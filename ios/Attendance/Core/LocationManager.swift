import Foundation
import CoreLocation
import Combine

/// GPS Location output structure matching Android's LocationResult.
public struct LocationResult: Equatable {
    public let latitude: Double
    public let longitude: Double
    public let accuracy: Float
    public let isMock: Bool

    public init(latitude: Double, longitude: Double, accuracy: Float, isMock: Bool = false) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.isMock = isMock
    }

    public static let empty = LocationResult(latitude: 0.0, longitude: 0.0, accuracy: 0.0, isMock: false)
}

/// CoreLocation wrapper managing permissions, high-accuracy GPS fixes, and anti-spoofing checks.
public final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationManager()

    private let clManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<LocationResult, Never>?

    @Published public private(set) var authorizationStatus: CLAuthorizationStatus
    @Published public private(set) var isLocationEnabled: Bool = true
    @Published public private(set) var lastKnownLocation: LocationResult?

    public override init() {
        self.authorizationStatus = clManager.authorizationStatus
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter = kCLDistanceFilterNone
        checkLocationEnabled()
    }

    public func requestAuthorization() {
        clManager.requestWhenInUseAuthorization()
    }

    public func checkLocationEnabled() {
        let enabled = CLLocationManager.locationServicesEnabled()
        DispatchQueue.main.async {
            self.isLocationEnabled = enabled
        }
    }

    public var hasLocationPermission: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    public func getCurrentLocation() async -> LocationResult {
        checkLocationEnabled()

        guard hasLocationPermission else {
            return .empty
        }

        // Return cached recent location if accurate within last 10 seconds
        if let current = clManager.location,
           abs(current.timestamp.timeIntervalSinceNow) < 10.0,
           current.horizontalAccuracy <= AppConfig.maxGpsAccuracyMeters {
            let res = mapLocation(current)
            self.lastKnownLocation = res
            return res
        }

        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            self.clManager.startUpdatingLocation()

            // Fallback timeout after 6 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
                if let cont = self?.locationContinuation {
                    self?.locationContinuation = nil
                    self?.clManager.stopUpdatingLocation()
                    if let loc = self?.clManager.location {
                        cont.resume(returning: self?.mapLocation(loc) ?? .empty)
                    } else {
                        cont.resume(returning: .empty)
                    }
                }
            }
        }
    }

    private func mapLocation(_ location: CLLocation) -> LocationResult {
        var isMock = false
        if #available(iOS 15.0, *) {
            isMock = location.sourceInformation?.isSimulatedBySoftware ?? false
        }
        return LocationResult(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: Float(location.horizontalAccuracy),
            isMock: isMock
        )
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // We require high horizontal accuracy
        if location.horizontalAccuracy > 0 && location.horizontalAccuracy <= AppConfig.maxGpsAccuracyMeters {
            if let cont = locationContinuation {
                locationContinuation = nil
                clManager.stopUpdatingLocation()
                let result = mapLocation(location)
                self.lastKnownLocation = result
                cont.resume(returning: result)
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let cont = locationContinuation {
            locationContinuation = nil
            clManager.stopUpdatingLocation()
            if let last = clManager.location {
                cont.resume(returning: mapLocation(last))
            } else {
                cont.resume(returning: .empty)
            }
        }
    }
}


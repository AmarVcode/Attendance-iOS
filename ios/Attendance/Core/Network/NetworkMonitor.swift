import Foundation
import Network
import Combine

/// Real-time network reachability observer using Apple's Network framework (matching NetworkConnectivityObserver).
public final class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.mnitsolutions.attendance.networkmonitor")

    @Published public private(set) var isOnline: Bool = true
    @Published public private(set) var isExpensive: Bool = false

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                self?.isExpensive = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}


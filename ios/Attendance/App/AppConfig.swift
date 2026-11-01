import Foundation

/// Central application configuration and environment constants.
public enum AppConfig {
    /// Base URL for the attendance backend API endpoints.
    public static let baseURL: URL = URL(string: "https://mnitsolutions.in/Attendance/public/api/")!

    /// Current application version string.
    public static let appVersion: String = "1.0"

    /// Maximum punch image resolution (width or height in pixels).
    public static let maxImageDimension: CGFloat = 1080.0

    /// Compression quality for captured punch selfies (0.0 - 1.0).
    public static let jpegCompressionQuality: CGFloat = 0.80

    /// Maximum allowable GPS horizontal accuracy in meters (matching server threshold).
    public static let maxGpsAccuracyMeters: Double = 50.0

    /// Network timeout interval in seconds.
    public static let requestTimeout: TimeInterval = 30.0

    /// Default annual paid leaves quota.
    public static let defaultAnnualPaidLeaves: Double = 12.0
}


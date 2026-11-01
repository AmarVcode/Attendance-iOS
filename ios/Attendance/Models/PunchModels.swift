import Foundation

/// Response from `POST punch`.
public struct PunchResponse: Codable {
    public let success: Bool?
    public let message: String?
    public let status: String?
    public let riskScore: Int?
    public let flags: [PunchFlag]?
    public let data: PunchResponseData?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case status
        case riskScore = "risk_score"
        case flags
        case data
    }
}

public struct PunchFlag: Codable {
    public let code: String?
    public let description: String?
    public let risk: Int?
}

public struct PunchResponseData: Codable {
    public let punch: PunchData?
    public let attendance: AttendanceSummaryData?
}

public struct PunchData: Codable {
    public let id: Int64?
    public let type: String?
    public let status: String?
    public let deviceTime: String?
    public let serverTime: String?
    public let latitude: Double?
    public let longitude: Double?
    public let rejectionReason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case status
        case deviceTime = "device_time"
        case serverTime = "server_time"
        case latitude
        case longitude
        case rejectionReason = "rejection_reason"
    }
}

public struct AttendanceSummaryData: Codable {
    public let id: Int64?
    public let date: String?
    public let status: String?
    public let checkIn: String?
    public let checkOut: String?
    public let workMinutes: Int?
    public let lateMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case status
        case checkIn = "check_in"
        case checkOut = "check_out"
        case workMinutes = "work_minutes"
        case lateMinutes = "late_minutes"
    }
}

/// Declared official company holiday item.
public struct HolidayItem: Codable, Identifiable, Equatable {
    public let id: Int64?
    public let name: String?
    public let date: String?
    public let dayName: String?
    public let description: String?
    public let isHoliday: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case date
        case dayName = "day_name"
        case description
        case isHoliday = "is_holiday"
    }

    public init(
        id: Int64? = nil,
        name: String?,
        date: String?,
        dayName: String? = nil,
        description: String? = nil,
        isHoliday: Bool? = true
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.dayName = dayName
        self.description = description
        self.isHoliday = isHoliday
    }
}

public struct HolidayListResponse: Codable {
    public let success: Bool?
    public let count: Int?
    public let data: [HolidayItem]?
}

public struct AttendanceListResponse: Codable {
    public let success: Bool?
    public let holidays: [HolidayItem]?
    public let data: [AttendanceDayItem]?
}

public struct AttendanceDayItem: Codable, Identifiable {
    public let id: Int64?
    public let userId: Int?
    public let date: String?
    public let checkIn: String?
    public let checkOut: String?
    public let workMinutes: Int?
    public let lateMinutes: Int?
    public let status: String?
    public let punches: [ServerPunchItem]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case checkIn = "check_in"
        case checkOut = "check_out"
        case workMinutes = "work_minutes"
        case lateMinutes = "late_minutes"
        case status
        case punches
    }
}

public struct ServerPunchItem: Codable, Identifiable {
    public let id: Int64?
    public let attendanceId: Int64?
    public let userId: Int?
    public let type: String?
    public let latitude: Double?
    public let longitude: Double?
    public let accuracyM: Float?
    public let deviceTime: String?
    public let serverTime: String?
    public let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case attendanceId = "attendance_id"
        case userId = "user_id"
        case type
        case latitude
        case longitude
        case accuracyM = "accuracy_m"
        case deviceTime = "device_time"
        case serverTime = "server_time"
        case status
    }
}

/// Offline synchronization summary result.
public struct SyncResult: Equatable {
    public let totalPending: Int
    public let syncedCount: Int
    public let failedCount: Int
    public let errors: [String]

    public init(totalPending: Int, syncedCount: Int, failedCount: Int, errors: [String] = []) {
        self.totalPending = totalPending
        self.syncedCount = syncedCount
        self.failedCount = failedCount
        self.errors = errors
    }
}


import Foundation

/// Leave category definition.
public struct LeaveType: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let code: String?
    public let daysPerYear: Int?
    public let isPaid: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case code
        case daysPerYear = "days_per_year"
        case isPaid = "is_paid"
    }

    public init(id: Int, name: String, code: String? = nil, daysPerYear: Int? = nil, isPaid: Bool? = true) {
        self.id = id
        self.name = name
        self.code = code
        self.daysPerYear = daysPerYear
        self.isPaid = isPaid
    }
}

/// Single submitted leave application record.
public struct LeaveRequestItem: Codable, Identifiable {
    public let id: Int64?
    public let userId: Int?
    public let leaveType: LeaveType?
    public let startDate: String?
    public let endDate: String?
    public let totalDays: Double?
    public let reason: String?
    public let status: String
    public let reviewedBy: String?
    public let reviewNotes: String?
    public let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case leaveType = "leave_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case totalDays = "total_days"
        case reason
        case status
        case reviewedBy = "reviewed_by"
        case reviewNotes = "review_notes"
        case createdAt = "created_at"
    }
}

/// Leave balance summary quotas.
public struct LeaveBalanceData: Codable, Equatable {
    public let totalAssigned: Double?
    public let remaining: Double?
    public let used: Double?

    enum CodingKeys: String, CodingKey {
        case totalAssigned = "total_assigned_paid_leaves"
        case remaining = "remaining_paid_leaves"
        case used = "used_paid_leaves"
    }

    public init(totalAssigned: Double? = 12.0, remaining: Double? = 12.0, used: Double? = 0.0) {
        self.totalAssigned = totalAssigned
        self.remaining = remaining
        self.used = used
    }
}

/// Response from `GET leaves`.
public struct LeaveListResponse: Codable {
    public let success: Bool?
    public let leaveBalance: LeaveBalanceData?
    public let leaveTypes: [LeaveType]?
    public let data: [LeaveRequestItem]?

    enum CodingKeys: String, CodingKey {
        case success
        case leaveBalance = "leave_balance"
        case leaveTypes = "leave_types"
        case data
    }
}

/// Request payload for `POST leaves`.
public struct ApplyLeaveRequest: Codable {
    public let leaveTypeId: Int
    public let startDate: String
    public let endDate: String
    public let reason: String

    enum CodingKeys: String, CodingKey {
        case leaveTypeId = "leave_type_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case reason
    }

    public init(leaveTypeId: Int, startDate: String, endDate: String, reason: String) {
        self.leaveTypeId = leaveTypeId
        self.startDate = startDate
        self.endDate = endDate
        self.reason = reason
    }
}

/// Response payload from `POST leaves`.
public struct ApplyLeaveResponse: Codable {
    public let success: Bool?
    public let message: String?
    public let leaveBalance: LeaveBalanceData?
    public let data: LeaveRequestItem?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case leaveBalance = "leave_balance"
        case data
    }
}


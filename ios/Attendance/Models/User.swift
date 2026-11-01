import Foundation

/// Authenticated employee profile model matching backend user schema.
public struct User: Codable, Identifiable, Equatable {
    public let id: Int?
    public let name: String
    public let email: String
    public let employeeId: String?
    public let phone: String?
    public let department: String?
    public let designation: String?
    public let joiningDate: String?
    public let status: String?
    public let role: String?
    public let paidLeaves: Double?
    public let remainingPaidLeaves: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case employeeId = "employee_id"
        case phone
        case department
        case designation
        case joiningDate = "joining_date"
        case status
        case role
        case paidLeaves = "paid_leaves"
        case remainingPaidLeaves = "remaining_paid_leaves"
    }

    public init(
        id: Int? = nil,
        name: String,
        email: String,
        employeeId: String? = nil,
        phone: String? = nil,
        department: String? = nil,
        designation: String? = nil,
        joiningDate: String? = nil,
        status: String? = "pending",
        role: String? = nil,
        paidLeaves: Double? = 12.0,
        remainingPaidLeaves: Double? = 12.0
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.employeeId = employeeId
        self.phone = phone
        self.department = department
        self.designation = designation
        self.joiningDate = joiningDate
        self.status = status
        self.role = role
        self.paidLeaves = paidLeaves
        self.remainingPaidLeaves = remainingPaidLeaves
    }

    public var isApprovedOrActive: Bool {
        guard let status = status?.lowercased() else { return false }
        return status == "approved" || status == "active"
    }
}


import Foundation

/// Request payload for employee authentication.
public struct LoginRequest: Codable {
    public let email: String
    public let password: String
    public let deviceUid: String?
    public let model: String?
    public let osVersion: String?
    public let appVersion: String?

    enum CodingKeys: String, CodingKey {
        case email
        case password
        case deviceUid = "device_uid"
        case model
        case osVersion = "os_version"
        case appVersion = "app_version"
    }

    public init(
        email: String,
        password: String,
        deviceUid: String? = nil,
        model: String? = nil,
        osVersion: String? = nil,
        appVersion: String? = nil
    ) {
        self.email = email
        self.password = password
        self.deviceUid = deviceUid
        self.model = model
        self.osVersion = osVersion
        self.appVersion = appVersion
    }
}

/// Response payload from `POST login`.
public struct LoginResponse: Codable {
    public let success: Bool?
    public let message: String?
    public let token: String?
    public let accessToken: String?
    public let user: User?
    public let status: String?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case token
        case accessToken = "access_token"
        case user
        case status
    }

    public func getEffectiveToken() -> String? {
        return token ?? accessToken
    }
}

/// Request payload for employee registration.
public struct RegisterRequest: Codable {
    public let name: String
    public let employeeId: String
    public let email: String
    public let phone: String
    public let department: String
    public let designation: String
    public let joiningDate: String
    public let password: String

    enum CodingKeys: String, CodingKey {
        case name
        case employeeId = "employee_id"
        case email
        case phone
        case department
        case designation
        case joiningDate = "joining_date"
        case password
    }

    public init(
        name: String,
        employeeId: String,
        email: String,
        phone: String,
        department: String,
        designation: String,
        joiningDate: String,
        password: String
    ) {
        self.name = name
        self.employeeId = employeeId
        self.email = email
        self.phone = phone
        self.department = department
        self.designation = designation
        self.joiningDate = joiningDate
        self.password = password
    }
}

/// Response payload from `POST register`.
public struct RegisterResponse: Codable {
    public let success: Bool?
    public let message: String?
    public let token: String?
    public let accessToken: String?
    public let status: String?
    public let user: User?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case token
        case accessToken = "access_token"
        case status
        case user
    }

    public func getEffectiveToken() -> String? {
        return token ?? accessToken
    }
}

/// Response payload from `GET me`.
public struct UserProfileResponse: Codable {
    public let success: Bool?
    public let message: String?
    public let user: User?
    public let status: String?
    public let data: UserProfileData?

    public func getEffectiveUser() -> User? {
        return user ?? data?.user
    }

    public func getEffectiveStatus() -> String? {
        return status ?? data?.status ?? user?.status ?? data?.user?.status
    }
}

public struct UserProfileData: Codable {
    public let user: User?
    public let status: String?
}


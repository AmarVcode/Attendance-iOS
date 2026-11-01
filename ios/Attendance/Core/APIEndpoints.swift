import Foundation

/// Type-safe definition of attendance REST API endpoints.
public enum APIEndpoint {
    case login(request: LoginRequest)
    case register(request: RegisterRequest)
    case getUserProfile
    case logout
    case submitPunch(multipart: MultipartFormData)
    case getAttendance(month: String?)
    case getHolidays(month: String?, year: Int?)
    case getLeaves
    case applyLeave(request: ApplyLeaveRequest)

    public var path: String {
        switch self {
        case .login:
            return "login"
        case .register:
            return "register"
        case .getUserProfile:
            return "me"
        case .logout:
            return "logout"
        case .submitPunch:
            return "punch"
        case .getAttendance:
            return "attendance"
        case .getHolidays:
            return "holidays"
        case .getLeaves:
            return "leaves"
        case .applyLeave:
            return "leaves"
        }
    }

    public var method: String {
        switch self {
        case .login, .register, .logout, .submitPunch, .applyLeave:
            return "POST"
        case .getUserProfile, .getAttendance, .getHolidays, .getLeaves:
            return "GET"
        }
    }

    public func makeURLRequest(baseURL: URL, token: String?, deviceUid: String) -> URLRequest {
        var url = baseURL.appendingPathComponent(path)

        // Query parameters
        switch self {
        case .getAttendance(let month):
            if let month = month {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.queryItems = [URLQueryItem(name: "month", value: month)]
                if let resolved = components?.url { url = resolved }
            }
        case .getHolidays(let month, let year):
            var items: [URLQueryItem] = []
            if let month = month { items.append(URLQueryItem(name: "month", value: month)) }
            if let year = year { items.append(URLQueryItem(name: "year", value: String(year))) }
            if !items.isEmpty {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.queryItems = items
                if let resolved = components?.url { url = resolved }
            }
        default:
            break
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = AppConfig.requestTimeout

        // Standard Headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(deviceUid, forHTTPHeaderField: "Device-UID")

        if let token = token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Body & Content-Type
        switch self {
        case .login(let req):
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(req)
        case .register(let req):
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(req)
        case .applyLeave(let req):
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(req)
        case .submitPunch(let multipart):
            request.setValue(multipart.contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = multipart.finalize()
        case .getUserProfile, .logout, .getAttendance, .getHolidays, .getLeaves:
            break
        }

        return request
    }
}


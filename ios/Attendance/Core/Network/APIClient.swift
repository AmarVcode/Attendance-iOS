import Foundation

/// Core API Client handling HTTP requests, auth interception, error parsing, and JSON decoding.
public final class APIClient {
    public static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL

    private init(baseURL: URL = AppConfig.baseURL) {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.requestTimeout
        config.timeoutIntervalForResource = AppConfig.requestTimeout
        self.session = URLSession(configuration: config)
    }

    public func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let token = KeychainManager.shared.getAuthToken()
        let deviceUid = KeychainManager.shared.getOrGenerateDeviceUID()
        let urlRequest = endpoint.makeURLRequest(baseURL: baseURL, token: token, deviceUid: deviceUid)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle 401 Unauthorized
        if httpResponse.statusCode == 401 {
            await MainActor.run {
                PreferencesManager.shared.clearSession()
            }
            throw APIError.unauthorized
        }

        // Handle HTTP Error Codes
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = extractErrorMessage(from: data, statusCode: httpResponse.statusCode)
            throw APIError.serverError(code: httpResponse.statusCode, message: errorMessage)
        }

        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            throw APIError.decodingError(error)
        }
    }

    public func requestRaw(_ endpoint: APIEndpoint) async throws -> (Data, HTTPURLResponse) {
        let token = KeychainManager.shared.getAuthToken()
        let deviceUid = KeychainManager.shared.getOrGenerateDeviceUID()
        let urlRequest = endpoint.makeURLRequest(baseURL: baseURL, token: token, deviceUid: deviceUid)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            await MainActor.run {
                PreferencesManager.shared.clearSession()
            }
            throw APIError.unauthorized
        }

        return (data, httpResponse)
    }

    private func extractErrorMessage(from data: Data, statusCode: Int) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Server responded with status \(statusCode)"
        }

        if let errors = json["errors"] as? [String: Any],
           let firstKey = errors.keys.first {
            if let messages = errors[firstKey] as? [String], let firstMsg = messages.first {
                return firstMsg
            }
            if let message = errors[firstKey] as? String {
                return message
            }
        }

        if let message = json["message"] as? String, !message.isEmpty {
            return message
        }

        return "Server error (\(statusCode))"
    }
}

/// Strongly typed API errors.
public enum APIError: LocalizedError {
    case unauthorized
    case invalidResponse
    case serverError(code: Int, message: String)
    case decodingError(Error)
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Session expired. Please log in again."
        case .invalidResponse:
            return "Invalid response received from server."
        case .serverError(_, let message):
            return message
        case .decodingError(let error):
            return "Data format error: \(error.localizedDescription)"
        case .networkError(let message):
            return message
        }
    }
}


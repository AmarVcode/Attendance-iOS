import Foundation

/// Generic state wrapper representing asynchronous operation states (matching Android Resource<T>).
public enum Resource<T> {
    case loading
    case success(data: T, message: String? = nil)
    case error(message: String, data: T? = nil)

    public var data: T? {
        switch self {
        case .loading:
            return nil
        case .success(let data, _):
            return data
        case .error(_, let data):
            return data
        }
    }

    public var message: String? {
        switch self {
        case .loading:
            return nil
        case .success(_, let message):
            return message
        case .error(let message, _):
            return message
        }
    }

    public var isLoading: BooleanLiteralType {
        if case .loading = self { return true }
        return false
    }
}


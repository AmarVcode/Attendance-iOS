import Foundation
import Security

/// Thread-safe Keychain manager for sensitive credentials and persistent hardware binding.
public final class KeychainManager {
    public static let shared = KeychainManager()

    private let service = "com.mnitsolutions.attendance"
    private let tokenKey = "auth_token"
    private let deviceUidKey = "device_uid"

    private init() {}

    // MARK: - Auth Token

    public func saveAuthToken(_ token: String) {
        save(key: tokenKey, value: token)
    }

    public func getAuthToken() -> String? {
        return get(key: tokenKey)
    }

    public func deleteAuthToken() {
        delete(key: tokenKey)
    }

    // MARK: - Device UID (Permanent hardware identifier)

    public func getOrGenerateDeviceUID() -> String {
        if let existing = get(key: deviceUidKey), !existing.isEmpty {
            return existing
        }
        let newUID = UUID().uuidString
        save(key: deviceUidKey, value: newUID)
        return newUID
    }

    // MARK: - Low-level Keychain primitives

    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Remove any existing item before adding
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}


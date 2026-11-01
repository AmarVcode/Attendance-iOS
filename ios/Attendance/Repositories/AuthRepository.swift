import Foundation
import Combine
import UIKit

/// Repository managing authentication, device registration, and profile fetching (matching AuthRepositoryImpl).
public final class AuthRepository {
    public static let shared = AuthRepository()

    private let apiClient: APIClient
    private let preferences: PreferencesManager
    private let keychain: KeychainManager

    public init(
        apiClient: APIClient = .shared,
        preferences: PreferencesManager = .shared,
        keychain: KeychainManager = .shared
    ) {
        self.apiClient = apiClient
        self.preferences = preferences
        self.keychain = keychain
    }

    public func login(email: String, password: String) async -> Resource<LoginResponse> {
        let deviceUid = keychain.getOrGenerateDeviceUID()
        let (model, osVersion) = await MainActor.run {
            ("\(UIDevice.current.model) (\(UIDevice.current.name))", "iOS \(UIDevice.current.systemVersion)")
        }

        let request = LoginRequest(
            email: email,
            password: password,
            deviceUid: deviceUid,
            model: model,
            osVersion: osVersion,
            appVersion: AppConfig.appVersion
        )

        do {
            let response: LoginResponse = try await apiClient.request(.login(request: request))

            if let token = response.getEffectiveToken(), !token.isEmpty {
                keychain.saveAuthToken(token)
            }

            if let user = response.user {
                preferences.saveUser(user)
                if let status = user.status {
                    preferences.saveUserStatus(status)
                }
            } else if let status = response.status {
                preferences.saveUserStatus(status)
            }

            return .success(data: response, message: response.message ?? "Login successful")
        } catch {
            return .error(message: error.localizedDescription)
        }
    }

    public func register(request: RegisterRequest) async -> Resource<RegisterResponse> {
        do {
            let response: RegisterResponse = try await apiClient.request(.register(request: request))

            if let token = response.getEffectiveToken(), !token.isEmpty {
                keychain.saveAuthToken(token)
            }

            let status = response.status ?? response.user?.status ?? "pending"
            preferences.saveUserStatus(status)

            if let user = response.user {
                preferences.saveUser(user)
            }

            return .success(data: response, message: response.message ?? "Registration submitted")
        } catch {
            return .error(message: error.localizedDescription)
        }
    }

    public func getUserProfile() async -> Resource<UserProfileResponse> {
        do {
            let response: UserProfileResponse = try await apiClient.request(.getUserProfile)

            let effectiveUser = response.getEffectiveUser()
            let effectiveStatus = response.getEffectiveStatus() ?? effectiveUser?.status ?? "active"

            if let user = effectiveUser {
                let userToSave = User(
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    employeeId: user.employeeId,
                    phone: user.phone,
                    department: user.department,
                    designation: user.designation,
                    joiningDate: user.joiningDate,
                    status: effectiveStatus,
                    role: user.role,
                    paidLeaves: user.paidLeaves,
                    remainingPaidLeaves: user.remainingPaidLeaves
                )
                preferences.saveUser(userToSave)
            }
            preferences.saveUserStatus(effectiveStatus)

            return .success(data: response, message: response.message)
        } catch {
            return .error(message: error.localizedDescription)
        }
    }

    public func logout() async {
        do {
            let _: [String: String]? = try? await apiClient.request(.logout)
        }
        await MainActor.run {
            preferences.clearSession()
        }
    }

    public func clearSession() {
        preferences.clearSession()
    }
}


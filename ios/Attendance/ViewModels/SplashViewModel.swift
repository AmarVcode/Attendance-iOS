import Foundation
import SwiftUI
import Combine

public enum SplashDestination {
    case loading
    case home
    case pendingApproval
    case login
}

@MainActor
public final class SplashViewModel: ObservableObject {
    @Published public private(set) var destination: SplashDestination = .loading

    private let authRepository: AuthRepository
    private let keychain: KeychainManager
    private let preferences: PreferencesManager

    public init(
        authRepository: AuthRepository = .shared,
        keychain: KeychainManager = .shared,
        preferences: PreferencesManager = .shared
    ) {
        self.authRepository = authRepository
        self.keychain = keychain
        self.preferences = preferences
        checkSession()
    }

    public func checkSession() {
        self.destination = .loading

        Task {
            // Small pause for branding display
            try? await Task.sleep(nanoseconds: 600_000_000)

            guard let token = keychain.getAuthToken(), !token.isEmpty else {
                self.destination = .login
                return
            }

            // Attempt to refresh profile
            let result = await authRepository.getUserProfile()
            switch result {
            case .success(let body, _):
                let status = body.getEffectiveStatus() ?? "active"
                if status.lowercased() == "approved" || status.lowercased() == "active" {
                    self.destination = .home
                } else {
                    self.destination = .pendingApproval
                }
            case .error, .loading:
                // Fallback to cached status if offline
                let cached = preferences.userStatus ?? "active"
                if cached.lowercased() == "approved" || cached.lowercased() == "active" {
                    self.destination = .home
                } else {
                    self.destination = .pendingApproval
                }
            }
        }
    }
}


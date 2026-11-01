import Foundation
import SwiftUI
import Combine

@MainActor
public final class PendingViewModel: ObservableObject {
    @Published public private(set) var user: User?
    @Published public private(set) var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var isApproved: Bool = false
    @Published public var isLoggedOut: Bool = false

    private let authRepository: AuthRepository
    private let preferences: PreferencesManager

    public init(
        authRepository: AuthRepository = .shared,
        preferences: PreferencesManager = .shared
    ) {
        self.authRepository = authRepository
        self.preferences = preferences
        self.user = preferences.currentUser
        refreshStatus()
    }

    public func refreshStatus() {
        isLoading = true
        errorMessage = nil

        Task {
            let result = await authRepository.getUserProfile()
            isLoading = false
            self.user = preferences.currentUser

            switch result {
            case .success(let body, _):
                let status = body.getEffectiveStatus() ?? "pending"
                if status.lowercased() == "approved" || status.lowercased() == "active" {
                    isApproved = true
                }
            case .error(let msg, _):
                errorMessage = msg
            case .loading:
                break
            }
        }
    }

    public func logout() {
        Task {
            await authRepository.logout()
            isLoggedOut = true
        }
    }

    public func clearState() {
        errorMessage = nil
    }
}


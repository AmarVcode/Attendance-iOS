import Foundation
import SwiftUI
import Combine

@MainActor
public final class LoginViewModel: ObservableObject {
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var isPasswordVisible: Bool = false
    @Published public private(set) var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var navigationDestination: SplashDestination?

    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository = .shared) {
        self.authRepository = authRepository
    }

    public func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }

    public func login() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty && !trimmedPassword.isEmpty else {
            errorMessage = "Please enter both email and password"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            let result = await authRepository.login(email: trimmedEmail, password: trimmedPassword)
            isLoading = false

            switch result {
            case .success(let response, _):
                let status = response.status ?? response.user?.status ?? "pending"
                if status.lowercased() == "approved" || status.lowercased() == "active" {
                    navigationDestination = .home
                } else {
                    navigationDestination = .pendingApproval
                }
            case .error(let message, _):
                errorMessage = message
            case .loading:
                break
            }
        }
    }

    public func clearState() {
        errorMessage = nil
        navigationDestination = nil
    }
}


import Foundation
import SwiftUI
import Combine

@MainActor
public final class SignupViewModel: ObservableObject {
    @Published public var name: String = ""
    @Published public var employeeId: String = ""
    @Published public var email: String = ""
    @Published public var phone: String = ""
    @Published public var department: String = ""
    @Published public var designation: String = ""
    @Published public var joiningDate: String = ""
    @Published public var password: String = ""
    @Published public var confirmPassword: String = ""
    @Published public var isPasswordVisible: Bool = false
    @Published public private(set) var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var didRegisterSuccessfully: Bool = false

    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository = .shared) {
        self.authRepository = authRepository
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.joiningDate = formatter.string(from: Date())
    }

    public func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }

    public func register() {
        let n = name.trimmingCharacters(in: .whitespaces)
        let emp = employeeId.trimmingCharacters(in: .whitespaces)
        let em = email.trimmingCharacters(in: .whitespaces)
        let ph = phone.trimmingCharacters(in: .whitespaces)
        let dept = department.trimmingCharacters(in: .whitespaces)
        let desig = designation.trimmingCharacters(in: .whitespaces)
        let date = joiningDate.trimmingCharacters(in: .whitespaces)

        guard !n.isEmpty, !emp.isEmpty, !em.isEmpty, !ph.isEmpty,
              !dept.isEmpty, !desig.isEmpty, !date.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all required fields"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        isLoading = true
        errorMessage = nil

        let request = RegisterRequest(
            name: n,
            employeeId: emp,
            email: em,
            phone: ph,
            department: dept,
            designation: desig,
            joiningDate: date,
            password: password
        )

        Task {
            let result = await authRepository.register(request: request)
            isLoading = false

            switch result {
            case .success:
                didRegisterSuccessfully = true
            case .error(let msg, _):
                errorMessage = msg
            case .loading:
                break
            }
        }
    }

    public func clearState() {
        errorMessage = nil
        didRegisterSuccessfully = false
    }
}


import SwiftUI

/// Login screen matching Android LoginScreen UI and validation rules.
public struct LoginScreen: View {
    @StateObject private var viewModel = LoginViewModel()
    public let onNavigateToHome: () -> Void
    public let onNavigateToPending: () -> Void

    public init(onNavigateToHome: @escaping () -> Void, onNavigateToPending: @escaping () -> Void) {
        self.onNavigateToHome = onNavigateToHome
        self.onNavigateToPending = onNavigateToPending
    }

    public var body: some View {
        ZStack {
            Color.lightBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 36)

                    // Minimal Branding Header
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle().stroke(Color.borderLight, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 42, height: 42)
                            .foregroundColor(.primaryBlue)
                    }

                    Spacer().frame(height: 16)

                    Text("MNIT Attendance")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.slateDark)

                    Spacer().frame(height: 4)

                    Text("Secure Employee Verification Portal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.slateMedium)

                    Spacer().frame(height: 32)

                    // Clean White Login Form Card
                    CustomCard(cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Sign In")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.slateDark)

                            Spacer().frame(height: 4)

                            Text("Enter your credentials to access your account")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.slateMedium)

                            Spacer().frame(height: 20)

                            // Email Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email Address")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.slateMedium)

                                HStack(spacing: 10) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.primaryBlue)
                                        .frame(width: 20)

                                    TextField("name@company.com", text: $viewModel.email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.borderLight, lineWidth: 1)
                                )
                            }

                            Spacer().frame(height: 14)

                            // Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.slateMedium)

                                HStack(spacing: 10) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.primaryBlue)
                                        .frame(width: 20)

                                    if viewModel.isPasswordVisible {
                                        TextField("Enter password", text: $viewModel.password)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                    } else {
                                        SecureField("Enter password", text: $viewModel.password)
                                    }

                                    Button(action: { viewModel.togglePasswordVisibility() }) {
                                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.slateMedium)
                                    }
                                }
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.borderLight, lineWidth: 1)
                                )
                            }

                            Spacer().frame(height: 24)

                            // Login Button
                            PrimaryButton(
                                title: "LOGIN TO ACCOUNT",
                                backgroundColor: .primaryBlue,
                                isLoading: viewModel.isLoading
                            ) {
                                viewModel.login()
                            }

                            Spacer().frame(height: 20)

                            // Administrator Provisioning Notice
                            HStack {
                                Text("Employee accounts are created directly by your company administrator. Please contact your company HR/Admin for your login credentials.")
                                    .font(.system(size: 11.5))
                                    .foregroundColor(.slateMedium)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(hex: 0xF8FAFC))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.borderLight, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 30)
                }
            }
        }
        .alert(isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Sign In Error"),
                message: Text(viewModel.errorMessage ?? "An error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: viewModel.navigationDestination) { destination in
            guard let destination = destination else { return }
            if destination == .home {
                onNavigateToHome()
            } else if destination == .pendingApproval {
                onNavigateToPending()
            }
            viewModel.clearState()
        }
    }
}


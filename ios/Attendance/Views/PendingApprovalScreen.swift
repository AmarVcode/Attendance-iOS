import SwiftUI

/// Status holding screen displayed while an employee account awaits admin verification.
public struct PendingApprovalScreen: View {
    @StateObject private var viewModel = PendingViewModel()
    public let onNavigateToHome: () -> Void
    public let onNavigateToLogin: () -> Void

    public init(onNavigateToHome: @escaping () -> Void, onNavigateToLogin: @escaping () -> Void) {
        self.onNavigateToHome = onNavigateToHome
        self.onNavigateToLogin = onNavigateToLogin
    }

    public var body: some View {
        ZStack {
            Color.lightBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 24)

                    // Soft Amber Pending Icon Banner
                    ZStack {
                        Circle()
                            .fill(Color.amberBg)
                            .frame(width: 90, height: 90)
                            .overlay(
                                Circle().stroke(Color(hex: 0xFDE68A), lineWidth: 1.5)
                            )

                        Image(systemName: "hourglass")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundColor(.amberPrimary)
                    }

                    Spacer().frame(height: 20)

                    Text("Account Pending Approval")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.slateDark)
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 8)

                    Text("Your account registration has been submitted and is currently under review by the system administrator. Once approved, you will be able to access all app features.")
                        .font(.system(size: 13))
                        .foregroundColor(.slateMedium)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 20)

                    Spacer().frame(height: 24)

                    // Clean White Profile Details Card
                    CustomCard(cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Submitted Employee Profile")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.slateDark)

                            Divider().background(Color.borderLight)
                                .padding(.vertical, 4)

                            ProfileRow(label: "Name", value: viewModel.user?.name ?? "N/A")
                            ProfileRow(label: "Employee ID", value: viewModel.user?.employeeId ?? "N/A")
                            ProfileRow(label: "Email", value: viewModel.user?.email ?? "N/A")
                            ProfileRow(label: "Phone", value: viewModel.user?.phone ?? "N/A")
                            ProfileRow(label: "Department", value: viewModel.user?.department ?? "N/A")
                            ProfileRow(label: "Designation", value: viewModel.user?.designation ?? "N/A")
                            ProfileRow(label: "Joining Date", value: viewModel.user?.joiningDate ?? "N/A")
                            ProfileRow(label: "Current Status", value: viewModel.user?.status?.uppercased() ?? "PENDING", isStatus: true)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 28)

                    // Action Buttons
                    VStack(spacing: 12) {
                        PrimaryButton(
                            title: "REFRESH STATUS",
                            icon: "arrow.clockwise",
                            backgroundColor: .primaryBlue,
                            isLoading: viewModel.isLoading
                        ) {
                            viewModel.refreshStatus()
                        }

                        Button(action: { viewModel.logout() }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 15, weight: .bold))
                                Text("LOGOUT")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .foregroundColor(.rosePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.borderLight, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 30)
                }
            }
        }
        .onChange(of: viewModel.isApproved) { approved in
            if approved {
                onNavigateToHome()
            }
        }
        .onChange(of: viewModel.isLoggedOut) { loggedOut in
            if loggedOut {
                onNavigateToLogin()
            }
        }
        .alert(isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Status"),
                message: Text(viewModel.errorMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

private struct ProfileRow: View {
    let label: String
    let value: String
    var isStatus: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.slateMedium)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isStatus ? .amberPrimary : .slateDark)
        }
        .padding(.vertical, 3)
    }
}


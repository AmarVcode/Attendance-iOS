import SwiftUI

/// Tab 4: Employee Profile & Device UID (matching EmployeeProfileTab in HomeScreen.kt).
public struct ProfileTab: View {
    public let user: User?
    public let deviceUid: String
    public let totalPunchesLogged: Int
    public let onLogoutClick: () -> Void

    public init(
        user: User?,
        deviceUid: String,
        totalPunchesLogged: Int,
        onLogoutClick: @escaping () -> Void
    ) {
        self.user = user
        self.deviceUid = deviceUid
        self.totalPunchesLogged = totalPunchesLogged
        self.onLogoutClick = onLogoutClick
    }

    public var body: some View {
        CustomCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 0) {
                // Profile Avatar & Header
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0xDBEAFE))
                            .frame(width: 56, height: 56)

                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.primaryBlue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user?.name ?? "Employee")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.slateDark)

                        Text("\(user?.designation ?? "Staff") • \(user?.department ?? "MNIT")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primaryBlue)
                    }
                }

                Spacer().frame(height: 18)
                Divider().background(Color.borderLight)
                Spacer().frame(height: 14)

                Text("Official Information")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.slateDark)

                Spacer().frame(height: 10)

                Group {
                    DetailRow(label: "Employee ID", value: user?.employeeId ?? "N/A")
                    DetailRow(label: "Email Address", value: user?.email ?? "N/A")
                    DetailRow(label: "Phone Number", value: user?.phone ?? "N/A")
                    DetailRow(label: "Department", value: user?.department ?? "N/A")
                    DetailRow(label: "Designation", value: user?.designation ?? "N/A")
                    DetailRow(label: "Annual Paid Leaves", value: "\(user?.paidLeaves ?? AppConfig.defaultAnnualPaidLeaves) days")
                    DetailRow(label: "Remaining Paid Leaves", value: "\(user?.remainingPaidLeaves ?? AppConfig.defaultAnnualPaidLeaves) days")
                    DetailRow(label: "Account Status", value: user?.status?.uppercased() ?? "APPROVED")
                    DetailRow(label: "Total Punches Logged", value: "\(totalPunchesLogged)")
                }

                Spacer().frame(height: 16)
                Divider().background(Color.borderLight)
                Spacer().frame(height: 14)

                Text("Device Registration")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.slateDark)

                Spacer().frame(height: 8)

                DetailRow(label: "Hardware Device UID", value: deviceUid)

                Spacer().frame(height: 10)

                Text("If sync reports 'device not approved', share your Device UID with your administrator to approve this phone in the admin portal.")
                    .font(.system(size: 11))
                    .foregroundColor(.slateMedium)
                    .lineSpacing(2)
                    .padding(10)
                    .background(Color(hex: 0xF1F5F9))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderLight, lineWidth: 1))

                Spacer().frame(height: 22)

                Button(action: onLogoutClick) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .bold))
                        Text("Log Out Account")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.rosePrimary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.slateMedium)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.slateDark)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}


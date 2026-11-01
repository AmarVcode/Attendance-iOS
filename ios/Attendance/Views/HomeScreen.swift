import SwiftUI

/// Main Home screen container with top bar, bottom navigation bar, and tabs (matching HomeScreen.kt).
public struct HomeScreen: View {
    @StateObject private var viewModel = HomeViewModel()
    public let onNavigateToLogin: () -> Void

    @State private var selectedTab: Int = 0
    @State private var activePunchTypeDialog: String? = nil
    @State private var showLocationSettingsAlert: Bool = false

    public init(onNavigateToLogin: @escaping () -> Void) {
        self.onNavigateToLogin = onNavigateToLogin
    }

    public var body: some View {
        ZStack {
            Color.lightBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top App Bar
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primaryBlue)
                            .frame(width: 32, height: 32)
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("MNIT Attendance")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.slateDark)

                        // Network status pill
                        HStack(spacing: 4) {
                            Circle()
                                .fill(viewModel.isOnline ? Color.emeraldPrimary : Color.amberPrimary)
                                .frame(width: 7, height: 7)

                            Text(viewModel.isOnline ? "Online" : "Offline Mode")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(viewModel.isOnline ? Color(hex: 0x15803D) : .amberPrimary)
                        }
                    }

                    Spacer()

                    // Sync button
                    Button(action: { viewModel.syncNow() }) {
                        if viewModel.isSyncing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .primaryBlue))
                                .frame(width: 36, height: 36)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.slateDark)
                                .frame(width: 36, height: 36)
                        }
                    }
                    .disabled(viewModel.isSyncing)

                    // Logout button
                    Button(action: { viewModel.logout() }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.slateDark)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)

                // Tab Content Body
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case 0:
                            let todayHoliday = viewModel.holidays.first { $0.date == viewModel.currentDateString }
                            HomeTabContent(
                                user: viewModel.user,
                                currentTimeString: viewModel.currentTimeString,
                                currentDateString: viewModel.currentDateString,
                                latestPunch: viewModel.latestPunch,
                                todayPunches: viewModel.todayPunches,
                                isRecordingPunch: viewModel.isRecordingPunch,
                                todayHoliday: todayHoliday,
                                onPunchClick: { type in activePunchTypeDialog = type }
                            )
                        case 1:
                            MonthlyCalendarTab(
                                allPunches: viewModel.allPunches,
                                holidays: viewModel.holidays,
                                onMonthChanged: { m in viewModel.fetchHolidays(month: m) }
                            )
                        case 2:
                            PunchesHistoryTab(allPunches: viewModel.allPunches)
                        case 3:
                            LeaveRequestTab(
                                leaveBalance: viewModel.leaveBalance,
                                leaveTypes: viewModel.leaveTypes,
                                leaveRequests: viewModel.leaveRequests,
                                isLoading: viewModel.isLoadingLeaves,
                                isSubmitting: viewModel.isSubmittingLeave,
                                onRefresh: { Task { await viewModel.fetchLeaves() } },
                                onSubmitLeave: { id, s, e, r, cb in
                                    viewModel.submitLeave(leaveTypeId: id, startDate: s, endDate: e, reason: r, onSuccess: cb)
                                }
                            )
                        case 4:
                            ProfileTab(
                                user: viewModel.user,
                                deviceUid: viewModel.deviceUid,
                                totalPunchesLogged: viewModel.allPunches.count,
                                onLogoutClick: { viewModel.logout() }
                            )
                        default:
                            EmptyView()
                        }

                        Spacer().frame(height: 20)
                    }
                    .padding(16)
                }

                // Bottom Navigation Bar
                HStack {
                    NavItem(icon: "house.fill", label: "Home", isSelected: selectedTab == 0) { selectedTab = 0 }
                    NavItem(icon: "calendar", label: "Calendar", isSelected: selectedTab == 1) { selectedTab = 1 }
                    NavItem(icon: "clock.arrow.circlepath", label: "Punches", isSelected: selectedTab == 2) { selectedTab = 2 }
                    NavItem(icon: "calendar.badge.clock", label: "Leaves", isSelected: selectedTab == 3) {
                        selectedTab = 3
                        Task { await viewModel.fetchLeaves() }
                    }
                    NavItem(icon: "person.fill", label: "Profile", isSelected: selectedTab == 4) { selectedTab = 4 }
                }
                .padding(.top, 8)
                .padding(.bottom, 14)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.borderLight),
                    alignment: .top
                )
            }
        }
        .fullScreenCover(item: Binding(
            get: { activePunchTypeDialog.map { PunchTypeWrapper(type: $0) } },
            set: { activePunchTypeDialog = $0?.type }
        )) { wrapper in
            SelfieCameraModal(
                punchType: wrapper.type,
                employeeName: viewModel.user?.name ?? "Employee",
                onDismiss: { activePunchTypeDialog = nil },
                onPhotoCaptured: { photo in
                    let type = wrapper.type
                    activePunchTypeDialog = nil
                    viewModel.recordPunch(type: type, selfieImage: photo)
                }
            )
        }
        .alert(isPresented: Binding(
            get: { viewModel.statusMessage != nil },
            set: { if !$0 { viewModel.clearStatusMessage() } }
        )) {
            Alert(
                title: Text("MNIT Attendance"),
                message: Text(viewModel.statusMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: viewModel.isLoggedOut) { loggedOut in
            if loggedOut {
                onNavigateToLogin()
            }
        }
    }
}

private struct PunchTypeWrapper: Identifiable {
    let id = UUID()
    let type: String
}

private struct NavItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .primaryBlue : .slateMedium)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(isSelected ? Color(hex: 0xDBEAFE) : Color.clear)
                    .clipShape(Capsule())

                Text(label)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .primaryBlue : .slateMedium)
            }
            .frame(maxWidth: .infinity)
        }
    }
}


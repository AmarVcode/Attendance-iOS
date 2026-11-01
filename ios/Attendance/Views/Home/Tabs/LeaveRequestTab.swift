import SwiftUI

/// Tab 3: Leave Management & Application (matching LeaveRequestTab in LeaveRequestTab.kt).
public struct LeaveRequestTab: View {
    public let leaveBalance: LeaveBalanceData
    public let leaveTypes: [LeaveType]
    public let leaveRequests: [LeaveRequestItem]
    public let isLoading: Bool
    public let isSubmitting: Bool
    public let onRefresh: () -> Void
    public let onSubmitLeave: (Int, String, String, String, @escaping () -> Void) -> Void

    @State private var isApplying: Bool = false
    @State private var selectedLeaveType: LeaveType?
    @State private var startDate: String
    @State private var endDate: String
    @State private var reason: String = ""

    @State private var showStartDatePicker: Bool = false
    @State private var showEndDatePicker: Bool = false
    @State private var startDateObj: Date = Date()
    @State private var endDateObj: Date = Date()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    public init(
        leaveBalance: LeaveBalanceData = LeaveBalanceData(),
        leaveTypes: [LeaveType] = [],
        leaveRequests: [LeaveRequestItem] = [],
        isLoading: Bool = false,
        isSubmitting: Bool = false,
        onRefresh: @escaping () -> Void = {},
        onSubmitLeave: @escaping (Int, String, String, String, @escaping () -> Void) -> Void = { _, _, _, _, _ in }
    ) {
        self.leaveBalance = leaveBalance
        self.leaveTypes = leaveTypes
        self.leaveRequests = leaveRequests
        self.isLoading = isLoading
        self.isSubmitting = isSubmitting
        self.onRefresh = onRefresh
        self.onSubmitLeave = onSubmitLeave

        let today = DateFormatter()
        today.dateFormat = "yyyy-MM-dd"
        let tStr = today.string(from: Date())
        _startDate = State(initialValue: tStr)
        _endDate = State(initialValue: tStr)
    }

    public var body: some View {
        let requestedDays = calculateDays(start: startDate, end: endDate)
        let remainingQuota = leaveBalance.remaining ?? AppConfig.defaultAnnualPaidLeaves

        VStack(spacing: 16) {
            // 1. Leave Balance Quota Card
            CustomCard(cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: 0xEFF6FF))
                                .frame(width: 38, height: 38)
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.primaryBlue)
                                .font(.system(size: 18))
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text("My Leave Balance")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.slateDark)
                            Text("Synced with Admin Assigned Quota")
                                .font(.system(size: 11))
                                .foregroundColor(.slateMedium)
                        }
                    }

                    HStack(spacing: 10) {
                        // Total Quota
                        VStack(spacing: 3) {
                            Text("Quota")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.slateMedium)
                            Text(String(format: "%.1f", leaveBalance.totalAssigned ?? AppConfig.defaultAnnualPaidLeaves))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.slateDark)
                            Text("Assigned Days")
                                .font(.system(size: 10))
                                .foregroundColor(.slateMedium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: 0xF8FAFC))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderLight, lineWidth: 1))

                        // Available Remaining
                        VStack(spacing: 3) {
                            Text("Remaining")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: 0x065F46))
                            Text(String(format: "%.1f", remainingQuota))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: 0x047857))
                            Text("Available Days")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: 0x065F46))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.emeraldBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0xA7F3D0), lineWidth: 1))

                        // Used
                        let used = leaveBalance.used ?? max(0.0, (leaveBalance.totalAssigned ?? AppConfig.defaultAnnualPaidLeaves) - remainingQuota)
                        VStack(spacing: 3) {
                            Text("Used")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: 0x92400E))
                            Text(String(format: "%.1f", used))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.amberPrimary)
                            Text("Taken Days")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: 0x92400E))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.amberBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0xFDE68A), lineWidth: 1))
                    }
                }
            }

            // 2. Leave Application Form Card
            CustomCard(cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Leave Management")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.slateDark)
                            Text("Apply for leave and track approval status")
                                .font(.system(size: 12))
                                .foregroundColor(.slateMedium)
                        }

                        Spacer()

                        Button(action: { isApplying.toggle() }) {
                            HStack(spacing: 6) {
                                Image(systemName: isApplying ? "xmark" : "plus")
                                    .font(.system(size: 13, weight: .bold))
                                Text(isApplying ? "Cancel" : "Apply")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isApplying ? Color.slateLight.opacity(0.3) : Color.primaryBlue)
                            .foregroundColor(isApplying ? .slateDark : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    if isApplying {
                        Spacer().frame(height: 16)
                        Divider().background(Color.borderLight)
                        Spacer().frame(height: 14)

                        Text("New Leave Application")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.slateDark)

                        Spacer().frame(height: 12)

                        // Leave Type Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Leave Type")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.slateMedium)

                            Menu {
                                ForEach(leaveTypes) { type in
                                    Button(type.name) {
                                        selectedLeaveType = type
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedLeaveType?.name ?? leaveTypes.first?.name ?? "Select Leave Type")
                                        .foregroundColor(.slateDark)
                                        .font(.system(size: 14))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.slateMedium)
                                }
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLight, lineWidth: 1))
                            }
                        }

                        Spacer().frame(height: 12)

                        // Dates Row
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Start Date")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.slateMedium)

                                Button(action: { showStartDatePicker = true }) {
                                    HStack {
                                        Text(startDate)
                                            .font(.system(size: 13))
                                            .foregroundColor(.slateDark)
                                        Spacer()
                                        Image(systemName: "calendar").foregroundColor(.primaryBlue)
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLight, lineWidth: 1))
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("End Date")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.slateMedium)

                                Button(action: { showEndDatePicker = true }) {
                                    HStack {
                                        Text(endDate)
                                            .font(.system(size: 13))
                                            .foregroundColor(.slateDark)
                                        Spacer()
                                        Image(systemName: "calendar").foregroundColor(.primaryBlue)
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLight, lineWidth: 1))
                                }
                            }
                        }

                        Spacer().frame(height: 12)

                        // Duration pill
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.primaryBlue)
                                .font(.system(size: 14))
                            Text("Requested Duration")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.slateDark)
                            Spacer()
                            Text("\(requestedDays) Day\(requestedDays > 1 ? "s" : "")")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primaryBlue)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(hex: 0xEFF6FF))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xBFDBFE), lineWidth: 1))

                        // Over-quota alert
                        if Double(requestedDays) > remainingQuota {
                            Spacer().frame(height: 8)
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.amberPrimary)
                                    .font(.system(size: 15))
                                Text("Requested duration (\(requestedDays) days) exceeds remaining paid quota (\(String(format: "%.1f", remainingQuota)) days). Unpaid leave or special admin approval may apply.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: 0x92400E))
                                    .lineSpacing(2)
                            }
                            .padding(12)
                            .background(Color.amberBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xFDE68A), lineWidth: 1))
                        }

                        Spacer().frame(height: 12)

                        // Reason text
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Reason for leave")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.slateMedium)

                            TextEditor(text: $reason)
                                .frame(height: 80)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLight, lineWidth: 1))
                        }

                        Spacer().frame(height: 16)

                        PrimaryButton(
                            title: "Submit Leave Request",
                            backgroundColor: .primaryBlue,
                            isLoading: isSubmitting,
                            isEnabled: !reason.trimmingCharacters(in: .whitespaces).isEmpty
                        ) {
                            let typeId = selectedLeaveType?.id ?? leaveTypes.first?.id ?? 1
                            onSubmitLeave(typeId, startDate, endDate, reason) {
                                isApplying = false
                                reason = ""
                            }
                        }
                    }
                }
            }

            // 3. Past Applications List
            CustomCard(cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("My Applications")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.slateDark)

                        Spacer()

                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }

                        Button(action: onRefresh) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primaryBlue)
                        }
                    }

                    Spacer().frame(height: 14)
                    Divider().background(Color.borderLight)
                    Spacer().frame(height: 14)

                    if leaveRequests.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundColor(.slateMedium)

                            Text("No leave requests submitted yet")
                                .font(.system(size: 13))
                                .foregroundColor(.slateMedium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(leaveRequests) { leave in
                                LeaveApplicationRow(leave: leave)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showStartDatePicker) {
            VStack {
                DatePicker("Start Date", selection: $startDateObj, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                Button("Done") {
                    startDate = dateFormatter.string(from: startDateObj)
                    if endDate < startDate { endDate = startDate }
                    showStartDatePicker = false
                }
                .padding()
            }
        }
        .sheet(isPresented: $showEndDatePicker) {
            VStack {
                DatePicker("End Date", selection: $endDateObj, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                Button("Done") {
                    endDate = dateFormatter.string(from: endDateObj)
                    showEndDatePicker = false
                }
                .padding()
            }
        }
    }

    private func calculateDays(start: String, end: String) -> Int {
        guard let d1 = dateFormatter.date(from: start),
              let d2 = dateFormatter.date(from: end) else { return 1 }
        let diff = Calendar.current.dateComponents([.day], from: d1, to: d2).day ?? 0
        return max(1, diff + 1)
    }
}

private struct LeaveApplicationRow: View {
    let leave: LeaveRequestItem

    var body: some View {
        let status = leave.status.lowercased()
        let statusBg = status == "approved" ? Color.emeraldBg : (status == "rejected" ? Color.roseBg : Color.amberBg)
        let statusColor = status == "approved" ? Color.emeraldPrimary : (status == "rejected" ? Color.rosePrimary : Color.amberPrimary)
        let statusIcon = status == "approved" ? "checkmark.circle.fill" : (status == "rejected" ? "xmark.circle.fill" : "hourglass")

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(leave.leaveType?.name ?? "Leave Request")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.slateDark)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: statusIcon).font(.system(size: 11, weight: .bold))
                    Text(leave.status.capitalized).font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusBg)
                .foregroundColor(statusColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            let start = String(leave.startDate?.prefix(10) ?? "N/A")
            let end = String(leave.endDate?.prefix(10) ?? "N/A")
            let days = leave.totalDays != nil ? String(format: "%.0f", leave.totalDays!) : "1"

            Text("\(start)  to  \(end)  (\(days) day(s))")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primaryBlue)

            if let reason = leave.reason, !reason.isEmpty {
                Text(reason)
                    .font(.system(size: 13))
                    .foregroundColor(.slateDark)
            }

            if let note = leave.reviewNotes, !note.isEmpty {
                Text("Reviewer Note: \(note)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.slateMedium)
            }

            if let createdAt = leave.createdAt {
                let cleanTime = createdAt.prefix(19).replacingOccurrences(of: "T", with: " ")
                Text("Applied on: \(cleanTime)")
                    .font(.system(size: 11))
                    .foregroundColor(.slateMedium)
            }
        }
        .padding(14)
        .background(Color(hex: 0xF8FAFC))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderLight, lineWidth: 1))
    }
}


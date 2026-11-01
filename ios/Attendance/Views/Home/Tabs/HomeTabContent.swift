import SwiftUI

/// Tab 0: Home / Punch Actions & Today Summary (matching HomeTabContent in HomeScreen.kt).
public struct HomeTabContent: View {
    public let user: User?
    public let currentTimeString: String
    public let currentDateString: String
    public let latestPunch: AttendancePunchRecord?
    public let todayPunches: [AttendancePunchRecord]
    public let isRecordingPunch: Bool
    public let todayHoliday: HolidayItem?
    public let onPunchClick: (String) -> Void

    public init(
        user: User?,
        currentTimeString: String,
        currentDateString: String,
        latestPunch: AttendancePunchRecord?,
        todayPunches: [AttendancePunchRecord],
        isRecordingPunch: Bool,
        todayHoliday: HolidayItem? = nil,
        onPunchClick: @escaping (String) -> Void
    ) {
        self.user = user
        self.currentTimeString = currentTimeString
        self.currentDateString = currentDateString
        self.latestPunch = latestPunch
        self.todayPunches = todayPunches
        self.isRecordingPunch = isRecordingPunch
        self.todayHoliday = todayHoliday
        self.onPunchClick = onPunchClick
    }

    public var body: some View {
        let todayCheckIn = todayPunches.first(where: { $0.isPunchIn })
        let todayCheckOut = todayPunches.first(where: { $0.isPunchOut })
        let hasCheckedInToday = todayCheckIn != nil
        let hasCheckedOutToday = todayCheckOut != nil

        VStack(spacing: 16) {
            // 0. Official Holiday Banner (if today is an official holiday)
            if let holiday = todayHoliday {
                HStack(spacing: 12) {
                    Text("🎉")
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Official Company Holiday Today")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.amberDark)

                        Text(holiday.name ?? "Company Holiday")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: 0x78350F))

                        if let desc = holiday.description, !desc.isEmpty {
                            Text(desc)
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: 0x92400E))
                        }
                    }

                    Spacer()
                }
                .padding(14)
                .background(Color.amberBg)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: 0xFCD34D), lineWidth: 1)
                )
            }

            // 1. Welcome & Live Clock Card
            CustomCard(cornerRadius: 22) {
                VStack(alignment: .leading, spacing: 0) {
                    // Live Clock & Date Banner
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.primaryBlue)

                            Text(currentTimeString)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.slateDark)
                        }

                        Spacer()

                        Text(currentDateString)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.slateMedium)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color(hex: 0xF8FAFC))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.borderSubtle, lineWidth: 1)
                    )

                    Spacer().frame(height: 16)

                    Text("Welcome back,")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.slateMedium)

                    Spacer().frame(height: 2)

                    Text(user?.name ?? "Employee")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.slateDark)

                    Spacer().frame(height: 6)

                    Text("\(user?.designation ?? "Staff") • \(user?.department ?? "MNIT")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.brandIndigo)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.brandIndigoLight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: 0xC7D2FE), lineWidth: 1)
                        )

                    Spacer().frame(height: 16)
                    Divider().background(Color.borderSubtle)
                    Spacer().frame(height: 14)

                    // Punch Status Indicator Pill
                    let statusBg: Color = (hasCheckedInToday && hasCheckedOutToday) ? Color(hex: 0xEFF6FF) : (hasCheckedInToday ? Color.emeraldBg : Color(hex: 0xF1F5F9))
                    let statusBorder: Color = (hasCheckedInToday && hasCheckedOutToday) ? Color(hex: 0xBFDBFE) : (hasCheckedInToday ? Color(hex: 0xA7F3D0) : Color.borderLight)
                    let statusIcon = hasCheckedInToday ? "checkmark.circle.fill" : "clock.arrow.circlepath"
                    let statusIconColor: Color = (hasCheckedInToday && hasCheckedOutToday) ? .primaryBlue : (hasCheckedInToday ? .emeraldPrimary : .slateMedium)
                    let statusTextColor: Color = (hasCheckedInToday && hasCheckedOutToday) ? Color(hex: 0x1E40AF) : (hasCheckedInToday ? Color(hex: 0x065F46) : .slateDark)

                    let statusText = (hasCheckedInToday && hasCheckedOutToday) ?
                        "Completed for today • Out at \(todayCheckOut?.deviceTime.suffix(8) ?? "")" :
                        (hasCheckedInToday ? "Checked IN at \(todayCheckIn?.deviceTime.suffix(8) ?? "")" : "Not punched yet today")

                    HStack(spacing: 8) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(statusIconColor)

                        Text(statusText)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(statusTextColor)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(statusBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(statusBorder, lineWidth: 1)
                    )
                }
            }

            // 2. Attendance Action Buttons (State Machine)
            CustomCard(cornerRadius: 22) {
                VStack(alignment: .leading, spacing: 0) {
                    if hasCheckedInToday && hasCheckedOutToday {
                        // CASE 1: BOTH CHECKED IN AND OUT -> DONE CARD
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: 0xECFDF5))
                                    .frame(width: 60, height: 60)

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundColor(Color(hex: 0x059669))
                            }

                            Text("Done for Today! 🎉")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(.slateDark)

                            Text("You have completed your Check-In and Check-Out for today.")
                                .font(.system(size: 13))
                                .foregroundColor(.slateMedium)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 10) {
                                VStack {
                                    Text("CHECK IN")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(hex: 0x15803D))
                                    Text(todayCheckIn?.deviceTime.suffix(8) ?? "--:--")
                                        .font(.system(size: 13, weight: .heavy))
                                        .foregroundColor(.slateDark)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: 0xF0FDF4))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: 0xBBF7D0), lineWidth: 1)
                                )

                                VStack {
                                    Text("CHECK OUT")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(hex: 0xBE123C))
                                    Text(todayCheckOut?.deviceTime.suffix(8) ?? "--:--")
                                        .font(.system(size: 13, weight: .heavy))
                                        .foregroundColor(.slateDark)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: 0xFFF1F2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: 0xFECDD3), lineWidth: 1)
                                )
                            }
                            .padding(.top, 4)

                            Text("Only 1 check-in and check-out allowed per day • See you tomorrow!")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: 0x94A3B8))
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity)
                    } else if hasCheckedInToday {
                        // CASE 2: CHECKED IN ONLY -> SHOW CHECK OUT BUTTON
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Attendance Check-Out")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.slateDark)

                            Text("Checked in at \(todayCheckIn?.deviceTime.suffix(8) ?? ""). Ready to conclude your workday?")
                                .font(.system(size: 12))
                                .foregroundColor(.slateMedium)

                            Spacer().frame(height: 14)

                            Button(action: { onPunchClick("OUT") }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.left.to.line")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("CHECK OUT")
                                        .font(.system(size: 15, weight: .heavy))
                                        .tracking(0.5)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .foregroundColor(.white)
                                .background(LinearGradient.punchOutGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .disabled(isRecordingPunch)
                        }
                    } else {
                        // CASE 3: NOT YET CHECKED IN -> SHOW CHECK IN BUTTON
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Attendance Check-In")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.slateDark)

                            Text("Start your workday with live GPS & selfie verification")
                                .font(.system(size: 12))
                                .foregroundColor(.slateMedium)

                            Spacer().frame(height: 14)

                            Button(action: { onPunchClick("IN") }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.right.to.line")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("CHECK IN")
                                        .font(.system(size: 15, weight: .heavy))
                                        .tracking(0.5)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .foregroundColor(.white)
                                .background(LinearGradient.punchInGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .disabled(isRecordingPunch)
                        }
                    }
                }
            }

            // 3. Today's Punches History
            CustomCard(cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Today's Punches")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.slateDark)

                            Text("\(todayPunches.count) record(s) logged today")
                                .font(.system(size: 12))
                                .foregroundColor(.slateMedium)
                        }

                        Spacer()

                        let dayFormatter = DateFormatter()
                        let _ = dayFormatter.dateFormat = "dd MMM"
                        Text(dayFormatter.string(from: Date()))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.slateDark)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: 0xF1F5F9))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.borderLight, lineWidth: 1)
                            )
                    }

                    Spacer().frame(height: 14)
                    Divider().background(Color.borderLight)
                    Spacer().frame(height: 14)

                    if todayPunches.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.system(size: 32))
                                .foregroundColor(.slateMedium)

                            Text("No punches recorded today yet")
                                .font(.system(size: 13))
                                .foregroundColor(.slateMedium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(todayPunches) { punch in
                                PunchRecordRow(punch: punch)
                            }
                        }
                    }
                }
            }
        }
    }
}


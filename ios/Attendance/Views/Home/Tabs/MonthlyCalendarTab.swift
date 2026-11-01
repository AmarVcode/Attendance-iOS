import SwiftUI

/// Tab 1: Monthly Attendance Calendar & Work Hours (matching MonthlyAttendanceCalendar in HomeScreen.kt).
public struct MonthlyCalendarTab: View {
    public let allPunches: [AttendancePunchRecord]
    public let holidays: [HolidayItem]
    public let onMonthChanged: (String) -> Void

    @State private var calendarMonth: Date = Date()
    @State private var selectedDateString: String

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private let monthNameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private let monthPrefixFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    public init(
        allPunches: [AttendancePunchRecord],
        holidays: [HolidayItem] = [],
        onMonthChanged: @escaping (String) -> Void = { _ in }
    ) {
        self.allPunches = allPunches
        self.holidays = holidays
        self.onMonthChanged = onMonthChanged
        let today = DateFormatter()
        today.dateFormat = "yyyy-MM-dd"
        _selectedDateString = State(initialValue: today.string(from: Date()))
    }

    public var body: some View {
        let monthPrefix = monthPrefixFormatter.string(from: calendarMonth)
        let holidaysByDate = holidays.reduce(into: [String: HolidayItem]()) { if let d = $1.date { $0[d] = $1 } }
        let monthHolidays = holidays.filter { $0.date?.hasPrefix(monthPrefix) == true }.sorted { ($0.date ?? "") < ($1.date ?? "") }
        let punchesByDate = Dictionary(grouping: allPunches, by: { $0.date })

        // Stats calculation
        let workedDaysCount = punchesByDate.keys.filter { $0.hasPrefix(monthPrefix) }.count
        let totalHoursFormatted = calculateWorkHours(punchesByDate: punchesByDate, monthPrefix: monthPrefix)

        VStack(spacing: 16) {
            // 1. Month Navigation Header Card
            CustomCard(cornerRadius: 20) {
                VStack(spacing: 14) {
                    HStack {
                        Button(action: { changeMonth(by: -1) }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.slateDark)
                                .frame(width: 36, height: 36)
                        }

                        Spacer()

                        VStack(spacing: 2) {
                            Text(monthNameFormatter.string(from: calendarMonth))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.slateDark)

                            Text("Work & Punch Calendar")
                                .font(.system(size: 12))
                                .foregroundColor(.slateMedium)
                        }

                        Spacer()

                        Button(action: { changeMonth(by: 1) }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.slateDark)
                                .frame(width: 36, height: 36)
                        }
                    }

                    Divider().background(Color.borderLight)

                    // Monthly stats summary pills
                    HStack(spacing: 8) {
                        VStack(spacing: 3) {
                            Text("Worked")
                                .font(.system(size: 11))
                                .foregroundColor(.slateMedium)
                            Text("\(workedDaysCount) days")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primaryBlue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: 0xF1F5F9))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLight, lineWidth: 1))

                        VStack(spacing: 3) {
                            Text("Est. Hours")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: 0x065F46))
                            Text(totalHoursFormatted)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.emeraldPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.emeraldBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xA7F3D0), lineWidth: 1))

                        VStack(spacing: 3) {
                            Text("Holidays")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: 0x92400E))
                            Text("\(monthHolidays.count) days")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: 0xD97706))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: 0xFEF3C7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xFCD34D), lineWidth: 1))
                    }
                }
            }

            // 1.5 Official Company Holidays Banner Card (if any in this month)
            if !monthHolidays.isEmpty {
                CustomCard(cornerRadius: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("🎉")
                                .font(.system(size: 18))

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Official Company Holidays")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color(hex: 0x92400E))

                                Text("\(monthNameFormatter.string(from: calendarMonth)) declared non-working days")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: 0xB45309))
                            }

                            Spacer()

                            Text("\(monthHolidays.count) Declared")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: 0x78350F))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: 0xFCD34D))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Divider().background(Color(hex: 0xFDE68A))

                        VStack(spacing: 8) {
                            ForEach(monthHolidays) { h in
                                Button(action: { if let d = h.date { selectedDateString = d } }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(h.name ?? "Holiday")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(Color(hex: 0x78350F))

                                            if let desc = h.description, !desc.isEmpty {
                                                Text(desc)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Color(hex: 0xB45309))
                                            }
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(h.date ?? "")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(Color(hex: 0xB45309))

                                            Text(h.dayName ?? "")
                                                .font(.system(size: 10))
                                                .foregroundColor(Color(hex: 0xD97706))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: 0xFCD34D), lineWidth: 0.5)
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // 2. Calendar Grid Card
            CustomCard(cornerRadius: 20) {
                VStack(spacing: 10) {
                    // Days of Week Header
                    let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                    HStack {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(day == "Sun" ? .rosePrimary : .slateMedium)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    Divider().background(Color.borderLight)

                    // Calendar Grid Days
                    let daysInGrid = generateCalendarGrid(for: calendarMonth)
                    let chunks = stride(from: 0, to: daysInGrid.count, by: 7).map {
                        Array(daysInGrid[$0..<min($0 + 7, daysInGrid.count)])
                    }

                    VStack(spacing: 6) {
                        ForEach(0..<chunks.count, id: \.self) { rowIndex in
                            HStack(spacing: 4) {
                                ForEach(0..<chunks[rowIndex].count, id: \.self) { colIndex in
                                    let dayNum = chunks[rowIndex][colIndex]
                                    if let day = dayNum {
                                        let year = calendar.component(.year, from: calendarMonth)
                                        let month = calendar.component(.month, from: calendarMonth)
                                        let dateKey = String(format: "%04d-%02d-%02d", year, month, day)

                                        let dayPunches = punchesByDate[dateKey] ?? []
                                        let hasIn = dayPunches.contains { $0.isPunchIn }
                                        let hasOut = dayPunches.contains { $0.isPunchOut }
                                        let isHoliday = holidaysByDate[dateKey] != nil
                                        let isSelected = selectedDateString == dateKey
                                        let isSunday = colIndex == 0

                                        Button(action: { selectedDateString = dateKey }) {
                                            VStack(spacing: 2) {
                                                Text("\(day)")
                                                    .font(.system(size: 13, weight: (hasIn || isSelected || isHoliday) ? .bold : .regular))
                                                    .foregroundColor(isSelected ? .white : (isSunday ? .rosePrimary : (hasIn ? (hasOut ? Color(hex: 0x15803D) : Color(hex: 0xB45309)) : (isHoliday ? Color(hex: 0xB45309) : .slateDark))))

                                                if !isSelected {
                                                    if hasIn {
                                                        Circle()
                                                            .fill(hasOut ? Color.emeraldPrimary : Color.amberPrimary)
                                                            .frame(width: 4, height: 4)
                                                    } else if isHoliday {
                                                        Circle()
                                                            .fill(Color(hex: 0xF59E0B))
                                                            .frame(width: 4, height: 4)
                                                    }
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(
                                                isSelected ? Color.primaryBlue :
                                                    (hasIn && hasOut ? Color(hex: 0xDCFCE7) :
                                                    (hasIn ? Color(hex: 0xFEF3C7) :
                                                    (isHoliday ? Color(hex: 0xFEF3C7) :
                                                    (isSunday ? Color(hex: 0xFFF1F2) : Color.clear))))
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(isSelected ? Color.clear : (isHoliday ? Color(hex: 0xFCD34D) : Color.borderLight), lineWidth: 0.5)
                                            )
                                        }
                                    } else {
                                        Spacer().frame(maxWidth: .infinity, maxHeight: 44)
                                    }
                                }
                            }
                        }
                    }

                    Divider().background(Color.borderLight)
                        .padding(.top, 4)

                    // Legend
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle().fill(Color(hex: 0x22C55E)).frame(width: 8, height: 8)
                            Text("Complete").font(.system(size: 11)).foregroundColor(.slateMedium)
                        }
                        HStack(spacing: 4) {
                            Circle().fill(Color.amberPrimary).frame(width: 8, height: 8)
                            Text("Partial").font(.system(size: 11)).foregroundColor(.slateMedium)
                        }
                        HStack(spacing: 4) {
                            Circle().fill(Color(hex: 0xF59E0B)).frame(width: 8, height: 8)
                            Text("Holiday").font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: 0xB45309))
                        }
                    }
                }
            }

            // 3. Selected Day Detailed Punches & Holiday Notice
            CustomCard(cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    let selectedPunches = punchesByDate[selectedDateString] ?? []
                    let selectedHoliday = holidaysByDate[selectedDateString]

                    Text("Day Details: \(selectedDateString)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.slateDark)

                    Text(selectedHoliday != nil ? "Official Company Holiday & Punches" : "\(selectedPunches.count) record(s) recorded on this date")
                        .font(.system(size: 12))
                        .foregroundColor(.slateMedium)

                    Divider().background(Color.borderLight)

                    if let holiday = selectedHoliday {
                        HStack(spacing: 10) {
                            Text("🎉").font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Official Company Holiday: \(holiday.name ?? "")")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color(hex: 0x92400E))
                                Text(holiday.description ?? "Official declared non-working holiday for company employees.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: 0xB45309))
                            }
                        }
                        .padding(12)
                        .background(Color(hex: 0xFEF3C7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xFCD34D), lineWidth: 1))
                    }

                    if selectedPunches.isEmpty {
                        Text(selectedHoliday != nil ? "Official company holiday. No punch records required for this day." : "No punch records recorded for this day")
                            .font(.system(size: 13))
                            .foregroundColor(.slateMedium)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(selectedPunches) { punch in
                                PunchRecordRow(punch: punch)
                            }
                        }
                    }
                }
            }
        }
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: calendarMonth) {
            calendarMonth = newDate
            onMonthChanged(monthPrefixFormatter.string(from: newDate))
        }
    }

    private func generateCalendarGrid(for date: Date) -> [Int?] {
        let range = calendar.range(of: .day, in: .month, for: date)!
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = 1
        let firstDayOfMonth = calendar.date(from: components)!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) // 1 = Sunday

        var days: [Int?] = []
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        for d in 1...range.count {
            days.append(d)
        }
        return days
    }

    private func calculateWorkHours(punchesByDate: [String: [AttendancePunchRecord]], monthPrefix: String) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")

        var totalMinutes: Int64 = 0

        for (dateKey, punches) in punchesByDate where dateKey.hasPrefix(monthPrefix) {
            let inPunch = punches.filter { $0.isPunchIn }.sorted { $0.createdAt < $1.createdAt }.first
            let outPunch = punches.filter { $0.isPunchOut }.sorted { $0.createdAt > $1.createdAt }.first

            if let inP = inPunch, let outP = outPunch,
               let inDate = timeFormatter.date(from: inP.deviceTime),
               let outDate = timeFormatter.date(from: outP.deviceTime),
               outDate > inDate {
                let diffMins = Int64(outDate.timeIntervalSince(inDate) / 60)
                totalMinutes += diffMins
            }
        }

        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        return "\(hours)h \(mins)m"
    }
}


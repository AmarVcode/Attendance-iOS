import SwiftUI

/// Tab 2: Complete Punch Log (matching AllPunchesHistoryTab in HomeScreen.kt).
public struct PunchesHistoryTab: View {
    public let allPunches: [AttendancePunchRecord]

    public init(allPunches: [AttendancePunchRecord]) {
        self.allPunches = allPunches
    }

    public var body: some View {
        CustomCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Complete Punch Log")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.slateDark)

                        Text("\(allPunches.count) total punches on device")
                            .font(.system(size: 12))
                            .foregroundColor(.slateMedium)
                    }

                    Spacer()

                    Text("History")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primaryBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: 0xDBEAFE))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Spacer().frame(height: 14)
                Divider().background(Color.borderLight)
                Spacer().frame(height: 14)

                if allPunches.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 38))
                            .foregroundColor(.slateMedium)

                        Text("No punch records recorded yet")
                            .font(.system(size: 14))
                            .foregroundColor(.slateMedium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    VStack(spacing: 10) {
                        ForEach(allPunches) { punch in
                            PunchRecordRow(punch: punch)
                        }
                    }
                }
            }
        }
    }
}


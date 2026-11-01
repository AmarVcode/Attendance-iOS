import SwiftUI

/// Component displaying a single punch record with selfie thumbnail and sync status.
public struct PunchRecordRow: View {
    public let punch: AttendancePunchRecord

    public init(punch: AttendancePunchRecord) {
        self.punch = punch
    }

    public var body: some View {
        let isPunchIn = punch.isPunchIn
        let bgColor = isPunchIn ? Color.emeraldBg : Color.roseBg
        let borderColor = isPunchIn ? Color(hex: 0xA7F3D0) : Color(hex: 0xFECDD3)
        let primaryTextColor = isPunchIn ? Color(hex: 0x065F46) : Color(hex: 0x991B1B)

        HStack(alignment: .top, spacing: 12) {
            // Selfie Thumbnail or Icon
            if !punch.selfiePath.isEmpty,
               let image = UIImage(contentsOfFile: punch.selfiePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 1)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isPunchIn ? Color.emeraldPrimary : Color.rosePrimary)
                        .frame(width: 48, height: 48)

                    Image(systemName: isPunchIn ? "arrow.right.to.line" : "arrow.left.to.line")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                }
            }

            // Punch Details
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(isPunchIn ? "CHECK IN" : "CHECK OUT")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(primaryTextColor)

                    // Sync Status Badge
                    if punch.syncStatus == AttendancePunchRecord.statusSynced {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.icloud.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Synced")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xDCFCE7))
                        .foregroundColor(Color(hex: 0x16A34A))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else if punch.syncStatus == AttendancePunchRecord.statusSyncing {
                        HStack(spacing: 3) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: 0x2563EB)))
                                .scaleEffect(0.6)
                            Text("Syncing...")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xDBEAFE))
                        .foregroundColor(Color(hex: 0x2563EB))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Text("Pending Sync")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: 0xFEF3C7))
                            .foregroundColor(Color(hex: 0xD97706))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                Text("Time: \(punch.deviceTime)")
                    .font(.system(size: 12))
                    .foregroundColor(.slateMedium)

                if punch.latitude != 0.0 || punch.longitude != 0.0 {
                    HStack(spacing: 3) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(String(format: "GPS: %.4f, %.4f (±%.0fm)", punch.latitude, punch.longitude, punch.accuracy))
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.slateMedium)
                }

                if let errorMsg = punch.syncErrorMessage, !errorMsg.isEmpty {
                    Text(errorMsg)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.rosePrimary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}


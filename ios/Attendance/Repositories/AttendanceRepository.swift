import Foundation
import UIKit
import Combine

/// Repository managing attendance punch recording, offline SQLite persistence, and cloud synchronization (matching AttendanceRepositoryImpl).
public final class AttendanceRepository {
    public static let shared = AttendanceRepository()

    private let apiClient: APIClient
    private let database: DatabaseManager
    private let preferences: PreferencesManager
    private let keychain: KeychainManager
    private let networkMonitor: NetworkMonitor

    private let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    public init(
        apiClient: APIClient = .shared,
        database: DatabaseManager = .shared,
        preferences: PreferencesManager = .shared,
        keychain: KeychainManager = .shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.apiClient = apiClient
        self.database = database
        self.preferences = preferences
        self.keychain = keychain
        self.networkMonitor = networkMonitor
    }

    // MARK: - Punch Recording

    public func recordPunch(
        type: String,
        selfieImage: UIImage,
        location: LocationResult
    ) async -> AttendancePunchRecord {
        let now = Date()
        let deviceTime = dateTimeFormatter.string(from: now)
        let todayDate = dateFormatter.string(from: now)
        let deviceUid = keychain.getOrGenerateDeviceUID()
        let user = preferences.currentUser

        // 1. Save selfie to disk
        let selfieURL = ImageUtils.saveImageToDocuments(selfieImage, prefix: "punch_")
        let selfiePath = selfieURL?.path ?? ""

        var punch = AttendancePunchRecord(
            id: Int64(now.timeIntervalSince1970 * 1000),
            userId: user?.id,
            type: type.lowercased(),
            latitude: location.latitude,
            longitude: location.longitude,
            accuracy: location.accuracy,
            deviceTime: deviceTime,
            date: todayDate,
            selfiePath: selfiePath,
            isMock: location.isMock,
            deviceUid: deviceUid,
            syncStatus: AttendancePunchRecord.statusPending,
            createdAt: Int64(now.timeIntervalSince1970 * 1000)
        )

        // 2. Attempt immediate online submission
        var onlineSynced = false
        var serverPunchId: Int64?
        var syncError: String?

        let jpegData = selfieImage.jpegData(compressionQuality: AppConfig.jpegCompressionQuality)
            ?? ImageUtils.createFallbackSelfie(employeeName: user?.name ?? "Employee").jpegData(compressionQuality: 0.8)!

        var multipart = MultipartFormData()
        multipart.addField(name: "type", value: punch.type)
        multipart.addField(name: "lat", value: String(format: "%.6f", punch.latitude))
        multipart.addField(name: "lng", value: String(format: "%.6f", punch.longitude))
        multipart.addField(name: "accuracy", value: String(format: "%.1f", punch.accuracy))
        multipart.addField(name: "device_time", value: punch.deviceTime)
        multipart.addField(name: "is_mock", value: punch.isMock ? "1" : "0")
        multipart.addField(name: "is_offline", value: "0")
        multipart.addField(name: "device_uid", value: punch.deviceUid)
        multipart.addFileData(name: "selfie", filename: "selfie.jpg", mimeType: "image/jpeg", data: jpegData)

        do {
            let response: PunchResponse = try await apiClient.request(.submitPunch(multipart: multipart))
            if response.success == true {
                onlineSynced = true
                serverPunchId = response.data?.punch?.id
            } else {
                syncError = response.message
            }
        } catch {
            let errString = error.localizedDescription
            if errString.localizedCaseInsensitiveContains("already checked in") ||
               errString.localizedCaseInsensitiveContains("already checked out") {
                onlineSynced = true
                syncError = "Synced (Previously recorded on server)"
            } else {
                syncError = errString
            }
        }

        // 3. Save locally to Database
        punch.syncStatus = onlineSynced ? AttendancePunchRecord.statusSynced : AttendancePunchRecord.statusPending
        punch.syncedAt = onlineSynced ? deviceTime : nil
        punch.serverPunchId = serverPunchId
        punch.syncErrorMessage = syncError

        database.insert(punch)
        return punch
    }

    // MARK: - Offline Punch Synchronization

    public func syncPendingPunches() async -> SyncResult {
        let pending = database.getPendingPunches()
        guard !pending.isEmpty else {
            return SyncResult(totalPending: 0, syncedCount: 0, failedCount: 0)
        }

        var synced = 0
        var failed = 0
        var errorList: [String] = []

        for var punch in pending {
            punch.syncStatus = AttendancePunchRecord.statusSyncing
            database.update(punch)

            let image: UIImage
            if !punch.selfiePath.isEmpty, let img = UIImage(contentsOfFile: punch.selfiePath) {
                image = img
            } else {
                let user = preferences.currentUser
                image = ImageUtils.createFallbackSelfie(employeeName: user?.name ?? "Employee")
            }

            let jpegData = image.jpegData(compressionQuality: AppConfig.jpegCompressionQuality)!

            var multipart = MultipartFormData()
            multipart.addField(name: "type", value: punch.type)
            multipart.addField(name: "lat", value: String(format: "%.6f", punch.latitude))
            multipart.addField(name: "lng", value: String(format: "%.6f", punch.longitude))
            multipart.addField(name: "accuracy", value: String(format: "%.1f", punch.accuracy))
            multipart.addField(name: "device_time", value: punch.deviceTime)
            multipart.addField(name: "is_mock", value: punch.isMock ? "1" : "0")
            multipart.addField(name: "is_offline", value: "1")
            multipart.addField(name: "device_uid", value: punch.deviceUid)
            multipart.addFileData(name: "selfie", filename: "selfie.jpg", mimeType: "image/jpeg", data: jpegData)

            do {
                let response: PunchResponse = try await apiClient.request(.submitPunch(multipart: multipart))
                punch.syncStatus = AttendancePunchRecord.statusSynced
                punch.syncedAt = dateTimeFormatter.string(from: Date())
                punch.serverPunchId = response.data?.punch?.id
                punch.syncErrorMessage = nil
                database.update(punch)
                synced += 1
            } catch {
                let errString = error.localizedDescription
                if errString.localizedCaseInsensitiveContains("already checked in") ||
                   errString.localizedCaseInsensitiveContains("already checked out") {
                    punch.syncStatus = AttendancePunchRecord.statusSynced
                    punch.syncedAt = dateTimeFormatter.string(from: Date())
                    punch.syncErrorMessage = "Synced (Previously recorded on server)"
                    database.update(punch)
                    synced += 1
                } else {
                    punch.syncStatus = AttendancePunchRecord.statusFailed
                    punch.syncErrorMessage = errString
                    database.update(punch)
                    failed += 1
                    errorList.append(errString)
                }
            }
        }

        return SyncResult(totalPending: pending.count, syncedCount: synced, failedCount: failed, errors: errorList)
    }

    // MARK: - Cloud History Restoration

    public func syncHistoryFromServer() async {
        guard networkMonitor.isOnline else { return }

        let user = preferences.currentUser
        let deviceUid = keychain.getOrGenerateDeviceUID()
        let existingServerIds = database.getAllServerPunchIds()

        // 1. Fetch official company holidays
        await fetchHolidays()

        // 2. Fetch attendance history for current month, previous month, and next month
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = monthFormatter.string(from: now)

        let prevDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let prevMonth = monthFormatter.string(from: prevDate)

        let nextDate = calendar.date(byAdding: .month, value: 1, to: now) ?? now
        let nextMonth = monthFormatter.string(from: nextDate)

        let monthsToFetch = [currentMonth, prevMonth, nextMonth]
        var newPunches: [AttendancePunchRecord] = []
        var allHolidaysMap = preferences.cachedHolidays.reduce(into: [String: HolidayItem]()) { $0[$1.date ?? ""] = $1 }

        for m in monthsToFetch {
            do {
                let response: AttendanceListResponse = try await apiClient.request(.getAttendance(month: m))

                // Accumulate embedded holidays
                response.holidays?.forEach { h in
                    if let d = h.date, !d.isEmpty { allHolidaysMap[d] = h }
                }

                // Accumulate punches
                let days = response.data ?? []
                for day in days {
                    let punches = day.punches ?? []
                    for p in punches {
                        guard let serverId = p.id, !existingServerIds.contains(serverId) else { continue }

                        let pDate = day.date ?? dateFormatter.string(from: Date())
                        let cleanDeviceTime = p.deviceTime?.prefix(19).replacingOccurrences(of: "T", with: " ")
                            ?? "\(pDate) \(p.type?.lowercased() == "out" ? (day.checkOut ?? "18:00:00") : (day.checkIn ?? "09:00:00"))"

                        let record = AttendancePunchRecord(
                            id: serverId,
                            userId: user?.id ?? p.userId ?? day.userId,
                            type: p.type?.lowercased() ?? "in",
                            latitude: p.latitude ?? 0.0,
                            longitude: p.longitude ?? 0.0,
                            accuracy: p.accuracyM ?? 10.0,
                            deviceTime: String(cleanDeviceTime),
                            date: pDate,
                            selfiePath: "",
                            isMock: false,
                            deviceUid: deviceUid,
                            syncStatus: AttendancePunchRecord.statusSynced,
                            syncedAt: p.serverTime ?? String(cleanDeviceTime),
                            serverPunchId: serverId,
                            createdAt: Int64(now.timeIntervalSince1970 * 1000)
                        )
                        newPunches.append(record)
                    }
                }
            } catch {
                // Ignore single month failure
            }
        }

        if !allHolidaysMap.isEmpty {
            let sortedHolidays = allHolidaysMap.values.sorted { ($0.date ?? "") < ($1.date ?? "") }
            preferences.saveHolidays(sortedHolidays)
        }

        if !newPunches.isEmpty {
            database.insertAll(newPunches)
        }
    }

    // MARK: - Holidays

    @discardableResult
    public func fetchHolidays(month: String? = nil) async -> [HolidayItem] {
        guard networkMonitor.isOnline else {
            return preferences.cachedHolidays
        }

        do {
            let response: HolidayListResponse = try await apiClient.request(.getHolidays(month: month, year: nil))
            let fetched = response.data ?? []
            var map = preferences.cachedHolidays.reduce(into: [String: HolidayItem]()) { $0[$1.date ?? ""] = $1 }
            fetched.forEach { if let d = $0.date, !d.isEmpty { map[d] = $0 } }
            let merged = map.values.sorted { ($0.date ?? "") < ($1.date ?? "") }
            preferences.saveHolidays(merged)
            return merged
        } catch {
            return preferences.cachedHolidays
        }
    }
}


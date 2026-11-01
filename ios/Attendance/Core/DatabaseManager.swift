import Foundation
import Combine

/// Local thread-safe persistent SQLite/JSON database manager replicating Room Database & AttendancePunchDao.
public final class DatabaseManager: ObservableObject {
    public static let shared = DatabaseManager()

    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.mnitsolutions.attendance.database", qos: .userInitiated)

    @Published public private(set) var allPunches: [AttendancePunchRecord] = []
    @Published public private(set) var pendingCount: Int = 0

    private init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dbDir = appSupport.appendingPathComponent("MNITAttendance", isDirectory: true)

        if !fileManager.fileExists(atPath: dbDir.path) {
            try? fileManager.createDirectory(at: dbDir, withIntermediateDirectories: true)
        }

        self.fileURL = dbDir.appendingPathComponent("attendance_punches.json")
        loadRecords()
    }

    // MARK: - Persistence I/O

    private func loadRecords() {
        queue.sync {
            guard FileManager.default.fileExists(atPath: fileURL.path),
                  let data = try? Data(contentsOf: fileURL),
                  let records = try? JSONDecoder().decode([AttendancePunchRecord].self, from: data) else {
                self.allPunches = []
                self.pendingCount = 0
                return
            }
            let sorted = records.sorted { $0.createdAt > $1.createdAt }
            DispatchQueue.main.async {
                self.allPunches = sorted
                self.pendingCount = sorted.filter { $0.isPending || $0.isFailed }.count
            }
        }
    }

    private func persistRecords(_ records: [AttendancePunchRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            try? data.write(to: fileURL, options: .atomic)
        }
        let sorted = records.sorted { $0.createdAt > $1.createdAt }
        let pending = sorted.filter { $0.isPending || $0.isFailed }.count
        DispatchQueue.main.async {
            self.allPunches = sorted
            self.pendingCount = pending
        }
    }

    // MARK: - DAO Operations

    @discardableResult
    public func insert(_ punch: AttendancePunchRecord) -> AttendancePunchRecord {
        return queue.sync {
            var current = allPunches
            if let index = current.firstIndex(where: { $0.id == punch.id }) {
                current[index] = punch
            } else {
                current.append(punch)
            }
            persistRecords(current)
            return punch
        }
    }

    public func insertAll(_ punches: [AttendancePunchRecord]) {
        queue.sync {
            var current = allPunches
            let existingIds = Set(current.map { $0.id })
            let existingServerIds = Set(current.compactMap { $0.serverPunchId })

            for punch in punches {
                if let serverId = punch.serverPunchId, existingServerIds.contains(serverId) {
                    continue
                }
                if existingIds.contains(punch.id) {
                    continue
                }
                current.append(punch)
            }
            persistRecords(current)
        }
    }

    public func update(_ punch: AttendancePunchRecord) {
        queue.sync {
            var current = allPunches
            if let index = current.firstIndex(where: { $0.id == punch.id }) {
                current[index] = punch
                persistRecords(current)
            }
        }
    }

    public func getById(_ id: Int64) -> AttendancePunchRecord? {
        return queue.sync {
            allPunches.first(where: { $0.id == id })
        }
    }

    public func getAllServerPunchIds() -> Set<Int64> {
        return queue.sync {
            Set(allPunches.compactMap { $0.serverPunchId })
        }
    }

    public func getPendingPunches() -> [AttendancePunchRecord] {
        return queue.sync {
            allPunches
                .filter { $0.syncStatus == AttendancePunchRecord.statusPending || $0.syncStatus == AttendancePunchRecord.statusFailed }
                .sorted { $0.createdAt < $1.createdAt }
        }
    }

    public func getTodayPunches(todayDate: String) -> [AttendancePunchRecord] {
        return queue.sync {
            allPunches
                .filter { $0.date == todayDate }
                .sorted { $0.createdAt > $1.createdAt }
        }
    }

    public func getLatestPunch() -> AttendancePunchRecord? {
        return queue.sync {
            allPunches.sorted { $0.createdAt > $1.createdAt }.first
        }
    }

    public func clearAll() {
        queue.sync {
            persistRecords([])
        }
    }
}


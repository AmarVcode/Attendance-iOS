import Foundation

/// Entity representing an attendance punch stored locally on the device (matching Android Room AttendancePunchEntity).
public struct AttendancePunchRecord: Codable, Identifiable, Equatable {
    public static let statusPending = "PENDING"
    public static let statusSyncing = "SYNCING"
    public static let statusSynced = "SYNCED"
    public static let statusFailed = "FAILED"

    public var id: Int64
    public var userId: Int?
    public var type: String // "in" or "out"
    public var latitude: Double
    public var longitude: Double
    public var accuracy: Float
    public var deviceTime: String // "YYYY-MM-DD HH:MM:SS"
    public var date: String // "YYYY-MM-DD"
    public var selfiePath: String
    public var isMock: Bool
    public var deviceUid: String
    public var syncStatus: String // PENDING, SYNCING, SYNCED, FAILED
    public var syncErrorMessage: String?
    public var syncedAt: String?
    public var serverPunchId: Int64?
    public var createdAt: Int64

    public init(
        id: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        userId: Int? = nil,
        type: String,
        latitude: Double,
        longitude: Double,
        accuracy: Float,
        deviceTime: String,
        date: String,
        selfiePath: String,
        isMock: Bool = false,
        deviceUid: String,
        syncStatus: String = AttendancePunchRecord.statusPending,
        syncErrorMessage: String? = nil,
        syncedAt: String? = nil,
        serverPunchId: Int64? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.userId = userId
        self.type = type.lowercased()
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.deviceTime = deviceTime
        self.date = date
        self.selfiePath = selfiePath
        self.isMock = isMock
        self.deviceUid = deviceUid
        self.syncStatus = syncStatus
        self.syncErrorMessage = syncErrorMessage
        self.syncedAt = syncedAt
        self.serverPunchId = serverPunchId
        self.createdAt = createdAt
    }

    public var isSynced: Bool {
        return syncStatus == AttendancePunchRecord.statusSynced
    }

    public var isPending: Bool {
        return syncStatus == AttendancePunchRecord.statusPending
    }

    public var isFailed: Bool {
        return syncStatus == AttendancePunchRecord.statusFailed
    }

    public var isPunchIn: Bool {
        return type.lowercased() == "in"
    }

    public var isPunchOut: Bool {
        return type.lowercased() == "out"
    }
}


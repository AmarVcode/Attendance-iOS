import Foundation
import SwiftUI
import Combine

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public private(set) var deviceUid: String
    @Published public private(set) var user: User?
    @Published public private(set) var isOnline: Bool = true
    @Published public private(set) var pendingCount: Int = 0
    @Published public private(set) var todayPunches: [AttendancePunchRecord] = []
    @Published public private(set) var allPunches: [AttendancePunchRecord] = []
    @Published public private(set) var latestPunch: AttendancePunchRecord?
    @Published public private(set) var holidays: [HolidayItem] = []

    @Published public private(set) var isSyncing: Bool = false
    @Published public var statusMessage: String?
    @Published public private(set) var isRecordingPunch: Bool = false

    @Published public private(set) var leaveTypes: [LeaveType] = []
    @Published public private(set) var leaveRequests: [LeaveRequestItem] = []
    @Published public private(set) var leaveBalance: LeaveBalanceData
    @Published public private(set) var isLoadingLeaves: Bool = false
    @Published public private(set) var isSubmittingLeave: Bool = false

    @Published public private(set) var isLocationEnabled: Bool = true
    @Published public var isLoggedOut: Bool = false

    @Published public var currentTimeString: String = ""
    @Published public var currentDateString: String = ""

    private let authRepository: AuthRepository
    private let attendanceRepository: AttendanceRepository
    private let apiClient: APIClient
    private let preferences: PreferencesManager
    private let keychain: KeychainManager
    private let database: DatabaseManager
    private let networkMonitor: NetworkMonitor
    private let locationManager: LocationManager

    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    public init(
        authRepository: AuthRepository = .shared,
        attendanceRepository: AttendanceRepository = .shared,
        apiClient: APIClient = .shared,
        preferences: PreferencesManager = .shared,
        keychain: KeychainManager = .shared,
        database: DatabaseManager = .shared,
        networkMonitor: NetworkMonitor = .shared,
        locationManager: LocationManager = .shared
    ) {
        self.authRepository = authRepository
        self.attendanceRepository = attendanceRepository
        self.apiClient = apiClient
        self.preferences = preferences
        self.keychain = keychain
        self.database = database
        self.networkMonitor = networkMonitor
        self.locationManager = locationManager

        self.deviceUid = keychain.getOrGenerateDeviceUID()
        self.user = preferences.currentUser
        self.leaveBalance = preferences.leaveBalance
        self.holidays = preferences.cachedHolidays

        setupBindings()
        startLiveClock()
        triggerAutoSync()
    }

    deinit {
        timer?.invalidate()
    }

    private func setupBindings() {
        // Observe database records
        database.$allPunches
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                self.allPunches = records
                let today = self.dateFormatter.string(from: Date())
                self.todayPunches = records.filter { $0.date == today }
                self.latestPunch = records.first
            }
            .store(in: &cancellables)

        database.$pendingCount
            .receive(on: DispatchQueue.main)
            .assign(to: \.pendingCount, on: self)
            .store(in: &cancellables)

        // Observe network state
        networkMonitor.$isOnline
            .receive(on: DispatchQueue.main)
            .sink { [weak self] online in
                guard let self = self else { return }
                self.isOnline = online
                if online {
                    self.triggerAutoSync()
                }
            }
            .store(in: &cancellables)

        // Observe user preferences
        preferences.$currentUser
            .receive(on: DispatchQueue.main)
            .assign(to: \.user, on: self)
            .store(in: &cancellables)

        preferences.$leaveBalance
            .receive(on: DispatchQueue.main)
            .assign(to: \.leaveBalance, on: self)
            .store(in: &cancellables)

        preferences.$cachedHolidays
            .receive(on: DispatchQueue.main)
            .assign(to: \.holidays, on: self)
            .store(in: &cancellables)

        locationManager.$isLocationEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLocationEnabled, on: self)
            .store(in: &cancellables)
    }

    private func startLiveClock() {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm:ss a"

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE, dd MMM yyyy"

        let updateClock = { [weak self] in
            let now = Date()
            self?.currentTimeString = timeFormatter.string(from: now)
            self?.currentDateString = dayFormatter.string(from: now)
        }

        updateClock()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                updateClock()
            }
        }
    }

    public func triggerAutoSync() {
        Task {
            guard networkMonitor.isOnline else { return }
            _ = await attendanceRepository.syncPendingPunches()
            await attendanceRepository.syncHistoryFromServer()
            await fetchLeaves()
        }
    }

    // MARK: - Attendance Punch Action

    public func recordPunch(type: String, selfieImage: UIImage) {
        guard !isRecordingPunch else { return }
        isRecordingPunch = true
        statusMessage = "Verifying GPS fix and recording punch..."

        Task {
            // 1. Check Location Authorization & GPS Hardware Toggle
            if !locationManager.hasLocationPermission {
                locationManager.requestAuthorization()
                statusMessage = "Location permission is required to punch attendance."
                isRecordingPunch = false
                return
            }

            locationManager.checkLocationEnabled()
            guard locationManager.isLocationEnabled else {
                statusMessage = "Please turn ON device GPS location to punch attendance."
                isRecordingPunch = false
                return
            }

            // 2. Fetch live GPS coordinates
            let location = await locationManager.getCurrentLocation()

            if location.isMock {
                statusMessage = "Mock GPS detected! Please disable fake location simulation."
                isRecordingPunch = false
                return
            }

            if location.latitude == 0.0 && location.longitude == 0.0 {
                statusMessage = "Unable to acquire accurate GPS location fix. Please move outdoors or near a window and retry."
                isRecordingPunch = false
                return
            }

            // 3. Record punch offline-first and attempt direct upload
            let record = await attendanceRepository.recordPunch(
                type: type,
                selfieImage: selfieImage,
                location: location
            )

            isRecordingPunch = false

            if record.isSynced {
                statusMessage = "Punch recorded and verified with server!"
            } else if let errorMsg = record.syncErrorMessage, !errorMsg.isEmpty {
                statusMessage = "Punch saved locally: \(errorMsg)"
            } else {
                statusMessage = "Punch saved offline. Will auto-sync when online."
            }
        }
    }

    // MARK: - Manual Sync

    public func syncNow() {
        guard !isSyncing else { return }
        isSyncing = true

        Task {
            guard networkMonitor.isOnline else {
                isSyncing = false
                statusMessage = "No internet connection. Records remain safely saved offline."
                return
            }

            let result = await attendanceRepository.syncPendingPunches()
            await attendanceRepository.syncHistoryFromServer()
            await fetchLeaves()
            isSyncing = false

            if result.failedCount > 0 && result.syncedCount == 0 {
                statusMessage = "Sync failed: \(result.errors.first ?? "Unable to upload punches")"
            } else if result.syncedCount > 0 {
                statusMessage = "Successfully synced \(result.syncedCount) offline record(s) to server."
            } else {
                statusMessage = "All records are already up to date."
            }
        }
    }

    // MARK: - Leaves Management

    public func fetchLeaves() async {
        isLoadingLeaves = true
        do {
            let response: LeaveListResponse = try await apiClient.request(.getLeaves)
            leaveTypes = response.leaveTypes ?? []
            leaveRequests = response.data ?? []

            if let balance = response.leaveBalance {
                preferences.saveLeaveBalance(
                    paidLeaves: balance.totalAssigned ?? AppConfig.defaultAnnualPaidLeaves,
                    remainingPaidLeaves: balance.remaining ?? AppConfig.defaultAnnualPaidLeaves
                )
            }
        } catch {
            // Silently fail if offline
        }
        isLoadingLeaves = false
    }

    public func submitLeave(
        leaveTypeId: Int,
        startDate: String,
        endDate: String,
        reason: String,
        onSuccess: @escaping () -> Void
    ) {
        isSubmittingLeave = true

        Task {
            let request = ApplyLeaveRequest(
                leaveTypeId: leaveTypeId,
                startDate: startDate,
                endDate: endDate,
                reason: reason
            )

            do {
                let response: ApplyLeaveResponse = try await apiClient.request(.applyLeave(request: request))
                isSubmittingLeave = false

                if response.success == true {
                    statusMessage = response.message ?? "Leave request submitted successfully!"
                    if let balance = response.leaveBalance {
                        preferences.saveLeaveBalance(
                            paidLeaves: balance.totalAssigned ?? AppConfig.defaultAnnualPaidLeaves,
                            remainingPaidLeaves: balance.remaining ?? AppConfig.defaultAnnualPaidLeaves
                        )
                    }
                    await fetchLeaves()
                    onSuccess()
                } else {
                    statusMessage = response.message ?? "Failed to submit leave request."
                }
            } catch {
                isSubmittingLeave = false
                statusMessage = "Error applying leave: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Holidays

    public func fetchHolidays(month: String? = nil) {
        Task {
            let items = await attendanceRepository.fetchHolidays(month: month)
            self.holidays = items
        }
    }

    // MARK: - Session

    public func logout() {
        Task {
            await authRepository.logout()
            isLoggedOut = true
        }
    }

    public func clearStatusMessage() {
        statusMessage = nil
    }
}


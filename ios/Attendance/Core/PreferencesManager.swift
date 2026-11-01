import Foundation
import Combine

/// Local key-value store managing cached user profiles, leave quotas, and holidays (matching Android PreferencesManager).
public final class PreferencesManager: ObservableObject {
    public static let shared = PreferencesManager()

    private let defaults = UserDefaults.standard
    private let keyUser = "mnit_cached_user"
    private let keyUserStatus = "mnit_cached_status"
    private let keyPaidLeaves = "mnit_paid_leaves"
    private let keyRemainingLeaves = "mnit_remaining_paid_leaves"
    private let keyHolidays = "mnit_cached_holidays_json"

    @Published public private(set) var currentUser: User?
    @Published public private(set) var userStatus: String?
    @Published public private(set) var leaveBalance: LeaveBalanceData
    @Published public private(set) var cachedHolidays: [HolidayItem] = []

    private init() {
        let paid = defaults.double(forKey: keyPaidLeaves)
        let rem = defaults.double(forKey: keyRemainingLeaves)
        let total = paid > 0 ? paid : AppConfig.defaultAnnualPaidLeaves
        let remaining = rem > 0 ? rem : AppConfig.defaultAnnualPaidLeaves
        let used = max(0.0, total - remaining)
        self.leaveBalance = LeaveBalanceData(totalAssigned: total, remaining: remaining, used: used)

        self.currentUser = loadUser()
        self.userStatus = defaults.string(forKey: keyUserStatus) ?? currentUser?.status ?? "pending"
        self.cachedHolidays = loadHolidays()
    }

    // MARK: - User Profile

    public func saveUser(_ user: User) {
        currentUser = user
        if let encoded = try? JSONEncoder().encode(user) {
            defaults.set(encoded, forKey: keyUser)
        }
        if let status = user.status {
            saveUserStatus(status)
        }
        if let paid = user.paidLeaves, let remaining = user.remainingPaidLeaves {
            saveLeaveBalance(paidLeaves: paid, remainingPaidLeaves: remaining)
        }
    }

    public func loadUser() -> User? {
        guard let data = defaults.data(forKey: keyUser),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user
    }

    public func saveUserStatus(_ status: String) {
        userStatus = status
        defaults.set(status, forKey: keyUserStatus)
    }

    // MARK: - Leave Balance

    public func saveLeaveBalance(paidLeaves: Double, remainingPaidLeaves: Double) {
        defaults.set(paidLeaves, forKey: keyPaidLeaves)
        defaults.set(remainingPaidLeaves, forKey: keyRemainingLeaves)
        let used = max(0.0, paidLeaves - remainingPaidLeaves)
        leaveBalance = LeaveBalanceData(totalAssigned: paidLeaves, remaining: remainingPaidLeaves, used: used)
    }

    // MARK: - Holidays Cache

    public func saveHolidays(_ holidays: [HolidayItem]) {
        cachedHolidays = holidays
        if let data = try? JSONEncoder().encode(holidays) {
            defaults.set(data, forKey: keyHolidays)
        }
    }

    public func loadHolidays() -> [HolidayItem] {
        guard let data = defaults.data(forKey: keyHolidays),
              let items = try? JSONDecoder().decode([HolidayItem].self, from: data) else {
            return []
        }
        return items
    }

    // MARK: - Session Cleanup

    public func clearSession() {
        KeychainManager.shared.deleteAuthToken()
        defaults.removeObject(forKey: keyUser)
        defaults.removeObject(forKey: keyUserStatus)
        currentUser = nil
        userStatus = nil
    }
}


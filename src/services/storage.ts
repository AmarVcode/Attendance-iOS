import {
  User,
  AttendancePunchRecord,
  HolidayItem,
  LeaveBalanceData,
  LeaveRequestItem,
  LeaveType,
} from '../types';

const STORAGE_KEYS = {
  DEVICE_UID: 'mnit_attendance_device_uid',
  AUTH_TOKEN: 'mnit_attendance_auth_token',
  USER_PROFILE: 'mnit_attendance_user_profile',
  PUNCHES: 'mnit_attendance_punches',
  HOLIDAYS: 'mnit_attendance_holidays',
  LEAVE_BALANCE: 'mnit_attendance_leave_balance',
  LEAVE_REQUESTS: 'mnit_attendance_leave_requests',
  OFFLINE_MODE_FORCED: 'mnit_attendance_offline_forced',
};

// Default seed employee
export const DEFAULT_USER: User = {
  id: 101,
  name: 'Er. Rajesh Kumar Sharma',
  email: 'test@mnitsolutions.in',
  employeeId: 'MNIT-2024-089',
  phone: '+91 98765 43210',
  department: 'Software Engineering & IT',
  designation: 'Senior Full Stack Engineer',
  joiningDate: '2023-01-15',
  status: 'active',
  role: 'employee',
  paidLeaves: 12.0,
  remainingPaidLeaves: 9.5,
};

// Default leave types matching backend
export const DEFAULT_LEAVE_TYPES: LeaveType[] = [
  { id: 1, name: 'Casual Leave (CL)', description: 'For personal or unplanned matters', daysAllowed: 8 },
  { id: 2, name: 'Medical Leave (ML)', description: 'For certified health or medical recuperation', daysAllowed: 10 },
  { id: 3, name: 'Earned Leave (EL)', description: 'Accumulated annual vacation leave', daysAllowed: 15 },
  { id: 4, name: 'Compensatory Off (Comp-Off)', description: 'For authorized weekend or holiday duty', daysAllowed: 5 },
  { id: 5, name: 'Restricted Holiday (RH)', description: 'Optional cultural or religious festival', daysAllowed: 2 },
];

// 2026 official holidays
export const DEFAULT_HOLIDAYS: HolidayItem[] = [
  { id: 1, name: 'New Year Day', date: '2026-01-01', dayName: 'Thursday', isHoliday: true, description: 'National New Year' },
  { id: 2, name: 'Republic Day', date: '2026-01-26', dayName: 'Monday', isHoliday: true, description: 'Celebration of Constitution of India' },
  { id: 3, name: 'Maha Shivratri', date: '2026-02-16', dayName: 'Monday', isHoliday: true, description: 'Festival of Shiva' },
  { id: 4, name: 'Holi Festival', date: '2026-03-04', dayName: 'Wednesday', isHoliday: true, description: 'Festival of Colors' },
  { id: 5, name: 'Eid-ul-Fitr', date: '2026-03-20', dayName: 'Friday', isHoliday: true, description: 'Islamic Festival' },
  { id: 6, name: 'Mahavir Jayanti', date: '2026-03-31', dayName: 'Tuesday', isHoliday: true, description: 'Jain Festival' },
  { id: 7, name: 'Good Friday', date: '2026-04-03', dayName: 'Friday', isHoliday: true, description: 'Christian Observance' },
  { id: 8, name: 'Independence Day', date: '2026-08-15', dayName: 'Saturday', isHoliday: true, description: 'National Day of Freedom' },
  { id: 9, name: 'Mahatma Gandhi Jayanti', date: '2026-10-02', dayName: 'Friday', isHoliday: true, description: 'Birth Anniversary of Gandhi' },
  { id: 10, name: 'Dussehra (Vijayadashami)', date: '2026-10-20', dayName: 'Tuesday', isHoliday: true, description: 'Triumph of Good over Evil' },
  { id: 11, name: 'Diwali (Deepavali)', date: '2026-11-08', dayName: 'Sunday', isHoliday: true, description: 'Festival of Lights' },
  { id: 12, name: 'Guru Nanak Jayanti', date: '2026-11-24', dayName: 'Tuesday', isHoliday: true, description: 'Sikh Festival' },
  { id: 13, name: 'Christmas Day', date: '2026-12-25', dayName: 'Friday', isHoliday: true, description: 'Christian Nativity' },
];

export class StorageService {
  // Keychain Device UID
  static getOrGenerateDeviceUID(): string {
    let uid = localStorage.getItem(STORAGE_KEYS.DEVICE_UID);
    if (!uid) {
      const randomHex = Array.from(crypto.getRandomValues(new Uint8Array(16)))
        .map((b) => b.toString(16).padStart(2, '0'))
        .join('');
      uid = `IOS-${randomHex.substring(0, 8)}-${randomHex.substring(8, 12)}-${randomHex.substring(12, 16)}`;
      localStorage.setItem(STORAGE_KEYS.DEVICE_UID, uid);
    }
    return uid;
  }

  // Auth Token
  static getAuthToken(): string | null {
    return localStorage.getItem(STORAGE_KEYS.AUTH_TOKEN);
  }

  static saveAuthToken(token: string): void {
    localStorage.setItem(STORAGE_KEYS.AUTH_TOKEN, token);
  }

  static clearAuthToken(): void {
    localStorage.removeItem(STORAGE_KEYS.AUTH_TOKEN);
  }

  // User Profile
  static getUser(): User | null {
    const raw = localStorage.getItem(STORAGE_KEYS.USER_PROFILE);
    if (!raw) return null;
    try {
      return JSON.parse(raw);
    } catch {
      return null;
    }
  }

  static saveUser(user: User): void {
    localStorage.setItem(STORAGE_KEYS.USER_PROFILE, JSON.stringify(user));
  }

  static clearUser(): void {
    localStorage.removeItem(STORAGE_KEYS.USER_PROFILE);
  }

  // Offline Mode forced toggle
  static isOfflineForced(): boolean {
    return localStorage.getItem(STORAGE_KEYS.OFFLINE_MODE_FORCED) === 'true';
  }

  static setOfflineForced(forced: boolean): void {
    localStorage.setItem(STORAGE_KEYS.OFFLINE_MODE_FORCED, forced ? 'true' : 'false');
  }

  // Punches (DatabaseManager.swift equivalent)
  static getAllPunches(): AttendancePunchRecord[] {
    const raw = localStorage.getItem(STORAGE_KEYS.PUNCHES);
    if (!raw) {
      // Seed with initial realistic records if first run
      const initial = this.generateSamplePunches();
      this.saveAllPunches(initial);
      return initial;
    }
    try {
      const records: AttendancePunchRecord[] = JSON.parse(raw);
      return records.sort((a, b) => b.createdAt - a.createdAt);
    } catch {
      return [];
    }
  }

  static saveAllPunches(punches: AttendancePunchRecord[]): void {
    localStorage.setItem(STORAGE_KEYS.PUNCHES, JSON.stringify(punches));
  }

  static addPunch(punch: AttendancePunchRecord): AttendancePunchRecord[] {
    const list = this.getAllPunches();
    const updated = [punch, ...list.filter((p) => p.id !== punch.id)];
    this.saveAllPunches(updated);
    return updated;
  }

  static updatePunch(updatedPunch: AttendancePunchRecord): AttendancePunchRecord[] {
    const list = this.getAllPunches();
    const updated = list.map((p) => (p.id === updatedPunch.id ? updatedPunch : p));
    this.saveAllPunches(updated);
    return updated;
  }

  // Holidays
  static getHolidays(): HolidayItem[] {
    const raw = localStorage.getItem(STORAGE_KEYS.HOLIDAYS);
    if (!raw) {
      this.saveHolidays(DEFAULT_HOLIDAYS);
      return DEFAULT_HOLIDAYS;
    }
    try {
      return JSON.parse(raw);
    } catch {
      return DEFAULT_HOLIDAYS;
    }
  }

  static saveHolidays(holidays: HolidayItem[]): void {
    localStorage.setItem(STORAGE_KEYS.HOLIDAYS, JSON.stringify(holidays));
  }

  // Leaves
  static getLeaveBalance(): LeaveBalanceData {
    const raw = localStorage.getItem(STORAGE_KEYS.LEAVE_BALANCE);
    if (!raw) {
      const initial: LeaveBalanceData = {
        totalAssigned: 12.0,
        used: 2.5,
        remaining: 9.5,
      };
      this.saveLeaveBalance(initial);
      return initial;
    }
    try {
      return JSON.parse(raw);
    } catch {
      return { totalAssigned: 12.0, used: 0, remaining: 12.0 };
    }
  }

  static saveLeaveBalance(balance: LeaveBalanceData): void {
    localStorage.setItem(STORAGE_KEYS.LEAVE_BALANCE, JSON.stringify(balance));
  }

  static getLeaveRequests(): LeaveRequestItem[] {
    const raw = localStorage.getItem(STORAGE_KEYS.LEAVE_REQUESTS);
    if (!raw) {
      const sample: LeaveRequestItem[] = [
        {
          id: 501,
          userId: 101,
          leaveType: DEFAULT_LEAVE_TYPES[0],
          startDate: '2026-10-12',
          endDate: '2026-10-13',
          totalDays: 2.0,
          reason: 'Family function & festival celebration in hometown',
          status: 'approved',
          reviewedBy: 'Admin (HOD)',
          reviewNotes: 'Approved. Ensure tasks handed over.',
          createdAt: '2026-10-08 11:20:00',
        },
        {
          id: 502,
          userId: 101,
          leaveType: DEFAULT_LEAVE_TYPES[1],
          startDate: '2026-10-28',
          endDate: '2026-10-28',
          totalDays: 0.5,
          reason: 'Dental checkup & doctor visit',
          status: 'approved',
          reviewedBy: 'Admin (HOD)',
          reviewNotes: 'Half-day medical leave granted.',
          createdAt: '2026-10-26 09:15:00',
        },
      ];
      this.saveLeaveRequests(sample);
      return sample;
    }
    try {
      return JSON.parse(raw);
    } catch {
      return [];
    }
  }

  static saveLeaveRequests(leaves: LeaveRequestItem[]): void {
    localStorage.setItem(STORAGE_KEYS.LEAVE_REQUESTS, JSON.stringify(leaves));
  }

  static addLeaveRequest(req: LeaveRequestItem): LeaveRequestItem[] {
    const list = this.getLeaveRequests();
    const updated = [req, ...list];
    this.saveLeaveRequests(updated);

    // Update remaining quota
    const balance = this.getLeaveBalance();
    const remaining = Math.max(0, (balance.remaining ?? 12) - (req.totalDays ?? 1));
    const used = (balance.used ?? 0) + (req.totalDays ?? 1);
    this.saveLeaveBalance({ ...balance, remaining, used });

    return updated;
  }

  static clearSession(): void {
    this.clearAuthToken();
    this.clearUser();
  }

  // Sample data generation for calendar & punches
  private static generateSamplePunches(): AttendancePunchRecord[] {
    const deviceUid = this.getOrGenerateDeviceUID();
    const records: AttendancePunchRecord[] = [];
    const now = new Date();

    // Generate recent historical punches for the past 14 days
    for (let i = 14; i >= 1; i--) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);

      // Skip Sundays
      if (d.getDay() === 0) continue;

      const yyyy = d.getFullYear();
      const mm = String(d.getMonth() + 1).padStart(2, '0');
      const dd = String(d.getDate()).padStart(2, '0');
      const dateStr = `${yyyy}-${mm}-${dd}`;

      const checkInHour = 9;
      const checkInMin = Math.floor(15 + Math.random() * 25);
      const checkInSec = Math.floor(Math.random() * 59);

      const checkOutHour = 18;
      const checkOutMin = Math.floor(10 + Math.random() * 35);
      const checkOutSec = Math.floor(Math.random() * 59);

      const inTimeStr = `${dateStr} ${String(checkInHour).padStart(2, '0')}:${String(checkInMin).padStart(2, '0')}:${String(checkInSec).padStart(2, '0')}`;
      const outTimeStr = `${dateStr} ${String(checkOutHour).padStart(2, '0')}:${String(checkOutMin).padStart(2, '0')}:${String(checkOutSec).padStart(2, '0')}`;

      // In record
      records.push({
        id: d.getTime() * 10 + 1,
        userId: 101,
        type: 'in',
        latitude: 26.8643 + (Math.random() - 0.5) * 0.001,
        longitude: 75.8115 + (Math.random() - 0.5) * 0.001,
        accuracy: 12.4,
        deviceTime: inTimeStr,
        date: dateStr,
        selfiePath: '/ic_logo.png',
        isMock: false,
        deviceUid,
        syncStatus: 'SYNCED',
        syncedAt: inTimeStr,
        serverPunchId: 1000 + i * 2,
        createdAt: d.getTime() + 9 * 3600000,
      });

      // Out record
      records.push({
        id: d.getTime() * 10 + 2,
        userId: 101,
        type: 'out',
        latitude: 26.8645 + (Math.random() - 0.5) * 0.001,
        longitude: 75.8118 + (Math.random() - 0.5) * 0.001,
        accuracy: 14.1,
        deviceTime: outTimeStr,
        date: dateStr,
        selfiePath: '/ic_logo.png',
        isMock: false,
        deviceUid,
        syncStatus: 'SYNCED',
        syncedAt: outTimeStr,
        serverPunchId: 1000 + i * 2 + 1,
        createdAt: d.getTime() + 18 * 3600000,
      });
    }

    return records.sort((a, b) => b.createdAt - a.createdAt);
  }
}

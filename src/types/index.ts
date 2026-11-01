export interface User {
  id?: number;
  name: string;
  email: string;
  employeeId?: string;
  phone?: string;
  department?: string;
  designation?: string;
  joiningDate?: string;
  status?: string; // 'pending' | 'active' | 'approved' | 'inactive'
  role?: string;
  paidLeaves?: number;
  remainingPaidLeaves?: number;
}

export interface LoginRequest {
  email: string;
  password: string;
  deviceUid?: string;
  model?: string;
  osVersion?: string;
  appVersion?: string;
}

export interface LoginResponse {
  success?: boolean;
  message?: string;
  token?: string;
  accessToken?: string;
  user?: User;
  status?: string;
}

export interface RegisterRequest {
  name: string;
  employeeId: string;
  email: string;
  phone: string;
  department: string;
  designation: string;
  joiningDate: string;
  password: string;
}

export interface RegisterResponse {
  success?: boolean;
  message?: string;
  token?: string;
  accessToken?: string;
  status?: string;
  user?: User;
}

export interface AttendancePunchRecord {
  id: number;
  userId?: number;
  type: 'in' | 'out';
  latitude: number;
  longitude: number;
  accuracy: number;
  deviceTime: string; // YYYY-MM-DD HH:mm:ss
  date: string; // YYYY-MM-DD
  selfiePath: string; // base64 or URL
  isMock: boolean;
  deviceUid: string;
  syncStatus: 'PENDING' | 'SYNCING' | 'SYNCED' | 'FAILED';
  syncErrorMessage?: string;
  syncedAt?: string;
  serverPunchId?: number;
  createdAt: number;
}

export interface PunchFlag {
  code?: string;
  description?: string;
  risk?: number;
}

export interface PunchData {
  id?: number;
  type?: string;
  status?: string;
  deviceTime?: string;
  serverTime?: string;
  latitude?: number;
  longitude?: number;
  rejectionReason?: string;
}

export interface AttendanceSummaryData {
  id?: number;
  date?: string;
  status?: string;
  checkIn?: string;
  checkOut?: string;
  workMinutes?: number;
  lateMinutes?: number;
}

export interface PunchResponse {
  success?: boolean;
  message?: string;
  status?: string;
  riskScore?: number;
  flags?: PunchFlag[];
  data?: {
    punch?: PunchData;
    attendance?: AttendanceSummaryData;
  };
}

export interface HolidayItem {
  id?: number;
  name?: string;
  date?: string; // YYYY-MM-DD
  dayName?: string;
  description?: string;
  isHoliday?: boolean;
}

export interface LeaveType {
  id: number;
  name: string;
  description?: string;
  daysAllowed?: number;
}

export interface LeaveRequestItem {
  id: number;
  userId?: number;
  leaveType?: LeaveType;
  startDate?: string;
  endDate?: string;
  totalDays?: number;
  reason?: string;
  status: 'pending' | 'approved' | 'rejected' | 'cancelled';
  reviewedBy?: string;
  reviewNotes?: string;
  createdAt?: string;
}

export interface LeaveBalanceData {
  totalAssigned?: number;
  remaining?: number;
  used?: number;
}

export interface LocationResult {
  latitude: number;
  longitude: number;
  accuracy: number;
  isMock?: boolean;
}

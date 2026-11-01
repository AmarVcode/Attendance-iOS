import React, { useState, useEffect } from 'react';
import {
  Home,
  Calendar,
  Clock,
  CalendarCheck,
  User,
  RefreshCw,
  LogOut,
  Wifi,
  WifiOff,
  CheckCircle2,
  X,
  AlertCircle,
} from 'lucide-react';
import {
  User as UserType,
  AttendancePunchRecord,
  HolidayItem,
  LeaveBalanceData,
  LeaveType,
  LeaveRequestItem,
  LocationResult,
} from '../../types';
import { StorageService } from '../../services/storage';
import { apiService } from '../../services/api';

import { HomeTabContent } from '../tabs/HomeTabContent';
import { MonthlyCalendarTab } from '../tabs/MonthlyCalendarTab';
import { PunchesHistoryTab } from '../tabs/PunchesHistoryTab';
import { LeaveRequestTab } from '../tabs/LeaveRequestTab';
import { ProfileTab } from '../tabs/ProfileTab';
import { SelfieCameraModal } from '../camera/SelfieCameraModal';

interface HomeScreenProps {
  onNavigateToLogin: () => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({ onNavigateToLogin }) => {
  const [selectedTab, setSelectedTab] = useState<number>(0);

  // Core App State
  const [currentUser, setCurrentUser] = useState<UserType | null>(StorageService.getUser());
  const [allPunches, setAllPunches] = useState<AttendancePunchRecord[]>(StorageService.getAllPunches());
  const [holidays, setHolidays] = useState<HolidayItem[]>(StorageService.getHolidays());
  const [leaveBalance, setLeaveBalance] = useState<LeaveBalanceData>(StorageService.getLeaveBalance());
  const [leaveTypes, setLeaveTypes] = useState<LeaveType[]>([]);
  const [leaveRequests, setLeaveRequests] = useState<LeaveRequestItem[]>(StorageService.getLeaveRequests());

  // Network & Sync State
  const [isOnline, setIsOnline] = useState<boolean>(!StorageService.isOfflineForced() && navigator.onLine);
  const [isSyncing, setIsSyncing] = useState<boolean>(false);
  const [isRecordingPunch, setIsRecordingPunch] = useState<boolean>(false);
  const [isLoadingLeaves, setIsLoadingLeaves] = useState<boolean>(false);
  const [isSubmittingLeave, setIsSubmittingLeave] = useState<boolean>(false);

  // Modals & Overlays
  const [activePunchTypeModal, setActivePunchTypeModal] = useState<'IN' | 'OUT' | null>(null);
  const [zoomPhotoUrl, setZoomPhotoUrl] = useState<string | null>(null);
  const [statusNotification, setStatusNotification] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);

  const deviceUid = StorageService.getOrGenerateDeviceUID();
  const todayStr = new Date().toISOString().slice(0, 10);
  const todayPunches = allPunches.filter((p) => p.date === todayStr);
  const todayHoliday = holidays.find((h) => h.date === todayStr);

  const pendingPunchesCount = allPunches.filter((p) => p.syncStatus === 'PENDING' || p.syncStatus === 'FAILED').length;

  // Listen to browser online/offline events
  useEffect(() => {
    const handleOnline = () => {
      if (!StorageService.isOfflineForced()) setIsOnline(true);
    };
    const handleOffline = () => {
      setIsOnline(false);
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    // Initial data fetch
    fetchInitialData();

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  const fetchInitialData = async () => {
    try {
      const h = await apiService.getHolidays();
      setHolidays(h);

      const leaves = await apiService.getLeaves();
      setLeaveBalance(leaves.balance);
      setLeaveTypes(leaves.types);
      setLeaveRequests(leaves.requests);
    } catch {
      // offline fallback is already active
    }
  };

  const showNotification = (message: string, type: 'success' | 'error' | 'info' = 'info') => {
    setStatusNotification({ message, type });
    setTimeout(() => {
      setStatusNotification(null);
    }, 4500);
  };

  // Perform punch sync
  const handleSyncNow = async () => {
    if (isSyncing) return;
    setIsSyncing(true);
    try {
      const result = await apiService.syncPendingPunches();
      setAllPunches(StorageService.getAllPunches());
      showNotification(result.details, result.failedCount > 0 ? 'error' : 'success');
    } catch (err: any) {
      showNotification('Sync failed: ' + (err.message || 'Network error'), 'error');
    } finally {
      setIsSyncing(false);
    }
  };

  // Record Punch handler
  const handlePhotoCaptured = async (selfieImage: string, location: LocationResult) => {
    const punchType = activePunchTypeModal;
    if (!punchType) return;

    setActivePunchTypeModal(null);
    setIsRecordingPunch(true);

    const now = new Date();
    const pad = (n: number) => String(n).padStart(2, '0');
    const deviceTime = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
    const date = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;

    // Create punch record
    const newRecord: AttendancePunchRecord = {
      id: Date.now(),
      userId: currentUser?.id || 101,
      type: punchType.toLowerCase() as 'in' | 'out',
      latitude: location.latitude,
      longitude: location.longitude,
      accuracy: location.accuracy,
      deviceTime,
      date,
      selfiePath: selfieImage,
      isMock: location.isMock || false,
      deviceUid,
      syncStatus: 'PENDING',
      createdAt: now.getTime(),
    };

    // Save locally first (offline-first architecture)
    const updatedList = StorageService.addPunch(newRecord);
    setAllPunches(updatedList);

    // Try immediate cloud sync
    if (isOnline) {
      try {
        const syncResult = await apiService.submitPunch(newRecord);
        if (syncResult.success) {
          const syncedRecord: AttendancePunchRecord = {
            ...newRecord,
            syncStatus: 'SYNCED',
            syncedAt: deviceTime,
            serverPunchId: syncResult.serverPunchId,
          };
          const syncdList = StorageService.updatePunch(syncedRecord);
          setAllPunches(syncdList);
          showNotification(`Attendance ${punchType} recorded & verified with server!`, 'success');
        } else {
          const failedRecord: AttendancePunchRecord = {
            ...newRecord,
            syncStatus: 'FAILED',
            syncErrorMessage: syncResult.message,
          };
          const fList = StorageService.updatePunch(failedRecord);
          setAllPunches(fList);
          showNotification(`Saved locally. ${syncResult.message}`, 'info');
        }
      } catch (err: any) {
        showNotification('Saved to device storage. Will auto-sync when online.', 'info');
      }
    } else {
      showNotification(`Punch ${punchType} saved offline in device storage.`, 'info');
    }

    setIsRecordingPunch(false);
  };

  // Submit Leave application
  const handleSubmitLeave = async (
    leaveTypeId: number,
    startDate: string,
    endDate: string,
    reason: string,
    onSuccess: () => void
  ) => {
    setIsSubmittingLeave(true);
    try {
      const created = await apiService.applyLeave(leaveTypeId, startDate, endDate, reason);
      setLeaveRequests(StorageService.getLeaveRequests());
      setLeaveBalance(StorageService.getLeaveBalance());
      onSuccess();
      showNotification('Leave application submitted for approval!', 'success');
    } catch (err: any) {
      showNotification(err.message || 'Failed to submit leave', 'error');
    } finally {
      setIsSubmittingLeave(false);
    }
  };

  const handleLogout = async () => {
    if (confirm('Are you sure you want to log out of this device session?')) {
      await apiService.logout();
      onNavigateToLogin();
    }
  };

  return (
    <div className="min-h-screen bg-slate-100 flex justify-center selection:bg-indigo-500 selection:text-white">
      {/* Mobile/Desktop Responsive Container */}
      <div className="w-full max-w-xl bg-slate-50 min-h-screen flex flex-col shadow-xl border-x border-slate-200/80">
        {/* Top App Bar */}
        <header className="sticky top-0 z-30 bg-white/95 backdrop-blur-md border-b border-slate-200/80 px-4 py-3 flex items-center justify-between shadow-2xs">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-white border border-slate-200 p-1 shadow-xs flex items-center justify-center shrink-0">
              <img src="/ic_logo.png" alt="Logo" className="w-full h-full object-contain" />
            </div>

            <div>
              <h1 className="text-base font-extrabold text-slate-900 tracking-tight leading-none">
                MNIT Attendance
              </h1>
              <div className="flex items-center gap-1.5 mt-1">
                <span
                  className={`w-2 h-2 rounded-full ${
                    isOnline ? 'bg-emerald-500 animate-pulse' : 'bg-amber-500'
                  }`}
                />
                <span className="text-[11px] font-semibold text-slate-600">
                  {isOnline ? 'Online Sync' : 'Offline Mode'}
                </span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-1.5">
            {/* Sync Button */}
            <button
              onClick={handleSyncNow}
              disabled={isSyncing}
              title="Synchronize pending punches"
              className="relative p-2 rounded-xl text-slate-600 hover:text-indigo-600 hover:bg-slate-100 transition disabled:opacity-50"
            >
              <RefreshCw size={18} className={isSyncing ? 'animate-spin text-indigo-600' : ''} />
              {pendingPunchesCount > 0 && (
                <span className="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-amber-500 text-white font-bold text-[10px] flex items-center justify-center shadow">
                  {pendingPunchesCount}
                </span>
              )}
            </button>

            {/* Logout Button */}
            <button
              onClick={handleLogout}
              title="Sign Out"
              className="p-2 rounded-xl text-slate-600 hover:text-rose-600 hover:bg-rose-50 transition"
            >
              <LogOut size={18} />
            </button>
          </div>
        </header>

        {/* Global Toast Notification */}
        {statusNotification && (
          <div className="sticky top-14 z-40 px-4 pt-2 animate-in slide-in-from-top-3 duration-200">
            <div
              className={`p-3 rounded-2xl shadow-lg border text-xs sm:text-sm font-semibold flex items-center justify-between gap-2.5 ${
                statusNotification.type === 'success'
                  ? 'bg-emerald-600 text-white border-emerald-500 shadow-emerald-900/20'
                  : statusNotification.type === 'error'
                  ? 'bg-rose-600 text-white border-rose-500 shadow-rose-900/20'
                  : 'bg-slate-900 text-white border-slate-800 shadow-slate-950/20'
              }`}
            >
              <div className="flex items-center gap-2">
                {statusNotification.type === 'success' ? (
                  <CheckCircle2 size={16} />
                ) : (
                  <AlertCircle size={16} />
                )}
                <span>{statusNotification.message}</span>
              </div>
              <button
                onClick={() => setStatusNotification(null)}
                className="opacity-70 hover:opacity-100 p-0.5"
              >
                <X size={14} />
              </button>
            </div>
          </div>
        )}

        {/* Tab Body */}
        <main className="flex-1 p-4 pb-28 overflow-y-auto">
          {selectedTab === 0 && (
            <HomeTabContent
              user={currentUser}
              todayPunches={todayPunches}
              isRecordingPunch={isRecordingPunch}
              todayHoliday={todayHoliday}
              onPunchClick={(type) => setActivePunchTypeModal(type)}
              onViewPhoto={(url) => setZoomPhotoUrl(url)}
            />
          )}

          {selectedTab === 1 && (
            <MonthlyCalendarTab
              allPunches={allPunches}
              holidays={holidays}
              onMonthChanged={(prefix) => apiService.getHolidays(prefix).then(setHolidays)}
              onViewPhoto={(url) => setZoomPhotoUrl(url)}
            />
          )}

          {selectedTab === 2 && (
            <PunchesHistoryTab
              allPunches={allPunches}
              isSyncing={isSyncing}
              onSyncNow={handleSyncNow}
              onViewPhoto={(url) => setZoomPhotoUrl(url)}
            />
          )}

          {selectedTab === 3 && (
            <LeaveRequestTab
              leaveBalance={leaveBalance}
              leaveTypes={leaveTypes}
              leaveRequests={leaveRequests}
              isLoading={isLoadingLeaves}
              isSubmitting={isSubmittingLeave}
              onRefresh={async () => {
                setIsLoadingLeaves(true);
                const l = await apiService.getLeaves();
                setLeaveBalance(l.balance);
                setLeaveRequests(l.requests);
                setIsLoadingLeaves(false);
              }}
              onSubmitLeave={handleSubmitLeave}
            />
          )}

          {selectedTab === 4 && (
            <ProfileTab
              user={currentUser}
              deviceUid={deviceUid}
              totalPunchesLogged={allPunches.length}
              onLogoutClick={handleLogout}
            />
          )}
        </main>

        {/* Bottom Navigation Bar (Matching iOS 5-Tab Bar) */}
        <nav className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-xl bg-white border-t border-slate-200/90 py-2 px-3 z-30 shadow-[0_-4px_20px_rgba(0,0,0,0.04)]">
          <div className="flex items-center justify-around">
            {[
              { id: 0, label: 'Home', icon: Home },
              { id: 1, label: 'Calendar', icon: Calendar },
              { id: 2, label: 'Punches', icon: Clock },
              { id: 3, label: 'Leaves', icon: CalendarCheck },
              { id: 4, label: 'Profile', icon: User },
            ].map((tab) => {
              const isSelected = selectedTab === tab.id;
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  type="button"
                  onClick={() => setSelectedTab(tab.id)}
                  className="flex-1 flex flex-col items-center justify-center py-1 group focus:outline-none"
                >
                  <div
                    className={`px-4 py-1 rounded-full transition-all duration-200 flex items-center justify-center ${
                      isSelected
                        ? 'bg-indigo-100 text-indigo-700 font-bold scale-105'
                        : 'text-slate-500 hover:text-slate-800'
                    }`}
                  >
                    <Icon size={20} className={isSelected ? 'stroke-[2.5]' : 'stroke-[1.8]'} />
                  </div>
                  <span
                    className={`text-[10px] tracking-tight mt-1 transition ${
                      isSelected ? 'font-bold text-indigo-700' : 'font-medium text-slate-500'
                    }`}
                  >
                    {tab.label}
                  </span>
                </button>
              );
            })}
          </div>
        </nav>

        {/* Fullscreen Front Camera Modal */}
        {activePunchTypeModal && (
          <SelfieCameraModal
            punchType={activePunchTypeModal}
            employeeName={currentUser?.name || 'Employee'}
            onDismiss={() => setActivePunchTypeModal(null)}
            onPhotoCaptured={handlePhotoCaptured}
          />
        )}

        {/* Photo Zoom Modal */}
        {zoomPhotoUrl && (
          <div
            className="fixed inset-0 z-50 bg-black/90 flex items-center justify-center p-4 backdrop-blur-xs"
            onClick={() => setZoomPhotoUrl(null)}
          >
            <div className="relative max-w-md w-full bg-slate-900 rounded-3xl p-3 border border-slate-800">
              <button
                onClick={() => setZoomPhotoUrl(null)}
                className="absolute top-4 right-4 z-10 w-9 h-9 rounded-full bg-slate-800 text-white flex items-center justify-center shadow hover:bg-slate-700"
              >
                <X size={18} />
              </button>
              <img
                src={zoomPhotoUrl}
                alt="Verification Selfie"
                className="w-full max-h-[75vh] object-contain rounded-2xl"
              />
              <p className="text-center text-slate-400 text-xs mt-3">
                Employee Verification Snapshot with Location Watermark
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

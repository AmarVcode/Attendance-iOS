import React, { useState } from 'react';
import { Hourglass, RefreshCw, CheckCircle2, LogOut, ShieldAlert, UserCheck } from 'lucide-react';
import { StorageService } from '../../services/storage';
import { apiService } from '../../services/api';
import { CustomCard } from '../common/CustomCard';

interface PendingApprovalScreenProps {
  onNavigateToHome: () => void;
  onNavigateToLogin: () => void;
}

export const PendingApprovalScreen: React.FC<PendingApprovalScreenProps> = ({
  onNavigateToHome,
  onNavigateToLogin,
}) => {
  const [user, setUser] = useState(StorageService.getUser());
  const [isChecking, setIsChecking] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);

  const checkStatus = async () => {
    setIsChecking(true);
    setNotice(null);
    try {
      const refreshed = await apiService.getUserProfile();
      if (refreshed) {
        setUser(refreshed);
        const st = refreshed.status?.toLowerCase();
        if (st === 'approved' || st === 'active') {
          onNavigateToHome();
          return;
        }
      }
      setNotice('Status is still pending review by the department administrator.');
    } catch {
      setNotice('Unable to reach server. Try again in a few moments.');
    } finally {
      setIsChecking(false);
    }
  };

  const simulateApproval = () => {
    if (user) {
      const approved = { ...user, status: 'active' };
      StorageService.saveUser(approved);
      setUser(approved);
      onNavigateToHome();
    }
  };

  const handleLogout = async () => {
    await apiService.logout();
    onNavigateToLogin();
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col justify-center items-center py-10 px-4 sm:px-6">
      <div className="w-full max-w-lg">
        {/* Soft Amber Pending Icon Banner */}
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-24 h-24 rounded-full bg-amber-50 border-2 border-amber-300 text-amber-600 shadow-lg shadow-amber-500/10 mb-4 animate-pulse">
            <Hourglass size={44} />
          </div>
          <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
            Account Pending Approval
          </h1>
          <p className="text-sm text-slate-600 mt-2 px-4 leading-relaxed">
            Your employee account registration has been submitted and is currently under review by the
            MNIT system administrator. Once approved, you will have access to the punch portal and live
            attendance logs.
          </p>
        </div>

        {notice && (
          <div className="mb-4 p-3 bg-amber-50 border border-amber-200 text-amber-800 rounded-xl text-xs sm:text-sm text-center">
            {notice}
          </div>
        )}

        {/* Profile Details Card */}
        <CustomCard className="mb-6">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100 mb-4">
            <h3 className="font-bold text-slate-900 text-sm">Submitted Registration Details</h3>
            <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-800 border border-amber-200 flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-ping" />
              PENDING REVIEW
            </span>
          </div>

          <div className="space-y-3 text-xs sm:text-sm">
            <div className="flex justify-between py-1.5 border-b border-slate-50">
              <span className="text-slate-500">Employee Name</span>
              <span className="font-bold text-slate-900">{user?.name || 'New Employee'}</span>
            </div>
            <div className="flex justify-between py-1.5 border-b border-slate-50">
              <span className="text-slate-500">Employee ID</span>
              <span className="font-semibold text-slate-900 font-mono">{user?.employeeId || 'N/A'}</span>
            </div>
            <div className="flex justify-between py-1.5 border-b border-slate-50">
              <span className="text-slate-500">Email Address</span>
              <span className="font-medium text-slate-900">{user?.email || 'N/A'}</span>
            </div>
            <div className="flex justify-between py-1.5 border-b border-slate-50">
              <span className="text-slate-500">Department</span>
              <span className="font-medium text-slate-900">{user?.department || 'N/A'}</span>
            </div>
            <div className="flex justify-between py-1.5 border-b border-slate-50">
              <span className="text-slate-500">Designation</span>
              <span className="font-medium text-slate-900">{user?.designation || 'N/A'}</span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-slate-500">Registered Date</span>
              <span className="font-medium text-slate-900">{user?.joiningDate || 'Today'}</span>
            </div>
          </div>
        </CustomCard>

        {/* Action Buttons */}
        <div className="space-y-3">
          <button
            onClick={checkStatus}
            disabled={isChecking}
            className="w-full py-3 px-4 bg-indigo-600 hover:bg-indigo-700 active:scale-[0.99] text-white font-bold text-sm rounded-xl shadow-md transition flex items-center justify-center gap-2"
          >
            <RefreshCw size={16} className={isChecking ? 'animate-spin' : ''} />
            Check Approval Status
          </button>

          {/* Quick Demo Simulator for easy testing */}
          <button
            onClick={simulateApproval}
            className="w-full py-3 px-4 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 border border-emerald-200 font-bold text-sm rounded-xl transition flex items-center justify-center gap-2"
          >
            <UserCheck size={16} />
            Simulate Admin Approval (Instant Access)
          </button>

          <button
            onClick={handleLogout}
            className="w-full py-2.5 px-4 bg-transparent hover:bg-slate-200/50 text-slate-600 font-medium text-xs rounded-xl transition flex items-center justify-center gap-2"
          >
            <LogOut size={14} /> Sign Out of Device
          </button>
        </div>
      </div>
    </div>
  );
};

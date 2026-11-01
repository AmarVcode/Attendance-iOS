import React, { useState } from 'react';
import { User as UserIcon, Mail, Phone, Calendar, ShieldCheck, Cpu, HardDrive, LogOut, Check, Copy, Wifi, WifiOff } from 'lucide-react';
import { User } from '../../types';
import { CustomCard } from '../common/CustomCard';
import { StorageService } from '../../services/storage';

interface ProfileTabProps {
  user: User | null;
  deviceUid: string;
  totalPunchesLogged: number;
  onLogoutClick: () => void;
}

export const ProfileTab: React.FC<ProfileTabProps> = ({
  user,
  deviceUid,
  totalPunchesLogged,
  onLogoutClick,
}) => {
  const [copied, setCopied] = useState(false);
  const [isOfflineForced, setIsOfflineForced] = useState(StorageService.isOfflineForced());

  const copyUid = () => {
    navigator.clipboard.writeText(deviceUid);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const toggleOffline = () => {
    const next = !isOfflineForced;
    setIsOfflineForced(next);
    StorageService.setOfflineForced(next);
  };

  return (
    <div className="space-y-4 sm:space-y-5">
      {/* 1. Header Profile Card */}
      <CustomCard>
        <div className="flex items-center gap-4 pb-4 border-b border-slate-100">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-tr from-indigo-600 to-indigo-500 text-white flex items-center justify-center font-black text-2xl shadow-md shadow-indigo-600/20 shrink-0">
            {user?.name
              ? user.name
                  .split(' ')
                  .map((p) => p[0])
                  .slice(0, 2)
                  .join('')
              : 'MN'}
          </div>

          <div className="min-w-0">
            <h2 className="text-xl font-black text-slate-900 truncate">{user?.name || 'Employee'}</h2>
            <div className="flex flex-wrap items-center gap-2 mt-1">
              <span className="text-xs font-semibold text-indigo-700 bg-indigo-50 border border-indigo-200 px-2.5 py-0.5 rounded-full">
                {user?.designation || 'Staff'}
              </span>
              <span className="text-xs text-slate-500 font-medium">
                {user?.department || 'MNIT'}
              </span>
            </div>
          </div>
        </div>

        {/* Official Information Details */}
        <div className="mt-4">
          <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3">
            Official Employment Details
          </h3>

          <div className="space-y-3 text-xs sm:text-sm">
            <div className="flex items-center justify-between py-2 border-b border-slate-50">
              <span className="text-slate-500 flex items-center gap-2">
                <ShieldCheck size={15} className="text-slate-400" /> Employee ID
              </span>
              <span className="font-bold text-slate-900 font-mono">{user?.employeeId || 'MNIT-2024-089'}</span>
            </div>

            <div className="flex items-center justify-between py-2 border-b border-slate-50">
              <span className="text-slate-500 flex items-center gap-2">
                <Mail size={15} className="text-slate-400" /> Official Email
              </span>
              <span className="font-medium text-slate-900">{user?.email || 'N/A'}</span>
            </div>

            <div className="flex items-center justify-between py-2 border-b border-slate-50">
              <span className="text-slate-500 flex items-center gap-2">
                <Phone size={15} className="text-slate-400" /> Phone Number
              </span>
              <span className="font-medium text-slate-900">{user?.phone || 'N/A'}</span>
            </div>

            <div className="flex items-center justify-between py-2 border-b border-slate-50">
              <span className="text-slate-500 flex items-center gap-2">
                <Calendar size={15} className="text-slate-400" /> Joining Date
              </span>
              <span className="font-medium text-slate-900">{user?.joiningDate || '2023-01-15'}</span>
            </div>

            <div className="flex items-center justify-between py-2">
              <span className="text-slate-500 flex items-center gap-2">
                <ShieldCheck size={15} className="text-emerald-500" /> Verification Status
              </span>
              <span className="px-2.5 py-0.5 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded-full font-bold text-xs">
                VERIFIED & ACTIVE
              </span>
            </div>
          </div>
        </div>
      </CustomCard>

      {/* 2. Device Security & Hardware Binding Card */}
      <CustomCard>
        <div className="flex items-center justify-between pb-3 border-b border-slate-100 mb-3">
          <div className="flex items-center gap-2">
            <Cpu size={16} className="text-indigo-600" />
            <h3 className="font-bold text-slate-900 text-sm">Device Binding & Diagnostics</h3>
          </div>
          <span className="text-[10px] font-mono text-slate-400 uppercase">iOS / Web Keychain</span>
        </div>

        <div className="space-y-3 text-xs">
          <div>
            <label className="text-slate-500 block mb-1 font-medium">Hardware Device UID</label>
            <div className="flex items-center justify-between bg-slate-50 border border-slate-200 rounded-xl p-2.5 font-mono text-slate-800 text-[11px]">
              <span className="truncate pr-2">{deviceUid}</span>
              <button
                type="button"
                onClick={copyUid}
                className="shrink-0 text-indigo-600 hover:text-indigo-800 transition flex items-center gap-1 font-sans text-xs font-semibold"
              >
                {copied ? <Check size={13} className="text-emerald-600" /> : <Copy size={13} />}
                {copied ? 'Copied' : 'Copy'}
              </button>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 pt-2">
            <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-200/80">
              <span className="text-slate-400 text-[11px] block">Stored Device Punches</span>
              <span className="text-base font-bold text-slate-900">{totalPunchesLogged} events</span>
            </div>

            <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-200/80">
              <span className="text-slate-400 text-[11px] block">App Environment</span>
              <span className="text-base font-bold text-slate-900">v1.0 (Web/iOS PWA)</span>
            </div>
          </div>

          <div className="pt-2 flex items-center justify-between">
            <span className="text-slate-500 font-medium">Network Sync Mode</span>
            <button
              onClick={toggleOffline}
              className={`px-3 py-1 rounded-xl text-xs font-semibold border flex items-center gap-1.5 transition ${
                isOfflineForced
                  ? 'bg-amber-50 text-amber-800 border-amber-300'
                  : 'bg-emerald-50 text-emerald-800 border-emerald-300'
              }`}
            >
              {isOfflineForced ? <WifiOff size={13} /> : <Wifi size={13} />}
              {isOfflineForced ? 'Offline-Only Mode' : 'Online Sync Active'}
            </button>
          </div>
        </div>
      </CustomCard>

      {/* Download Native iOS Package (.ipa) */}
      <CustomCard className="border-indigo-100 bg-gradient-to-r from-indigo-50/60 to-purple-50/40">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-indigo-600 text-white flex items-center justify-center font-bold shadow-md shadow-indigo-600/20">
              <span className="text-xs">IPA</span>
            </div>
            <div>
              <h3 className="font-bold text-slate-900 text-sm">Native iOS App Package (.ipa)</h3>
              <p className="text-[11px] text-slate-500">Official v1.0.0 Release • Ready to Sideload / Distribute</p>
            </div>
          </div>

          <a
            href="/Attendance.ipa"
            download="Attendance.ipa"
            className="px-3.5 py-2 bg-indigo-600 hover:bg-indigo-700 active:scale-95 text-white font-bold text-xs rounded-xl shadow-md transition flex items-center gap-1.5"
          >
            Download .ipa
          </a>
        </div>
      </CustomCard>

      {/* 3. Sign Out Button */}
      <CustomCard className="border-rose-100">
        <button
          onClick={onLogoutClick}
          className="w-full py-3 px-4 bg-rose-50 hover:bg-rose-100 active:scale-[0.99] text-rose-700 border border-rose-200 font-bold text-sm rounded-xl transition flex items-center justify-center gap-2"
        >
          <LogOut size={16} /> Sign Out of This Device
        </button>
      </CustomCard>
    </div>
  );
};

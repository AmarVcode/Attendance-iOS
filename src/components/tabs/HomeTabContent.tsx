import React, { useState, useEffect } from 'react';
import {
  Clock,
  Calendar,
  CheckCircle2,
  ArrowRightToLine,
  ArrowLeftToLine,
  MapPin,
  Sparkles,
  PartyPopper,
  ShieldCheck,
  AlertCircle,
  ExternalLink,
} from 'lucide-react';
import { User, AttendancePunchRecord, HolidayItem } from '../../types';
import { CustomCard } from '../common/CustomCard';
import { StatusPill } from '../common/StatusPill';

interface HomeTabContentProps {
  user: User | null;
  todayPunches: AttendancePunchRecord[];
  isRecordingPunch: boolean;
  todayHoliday?: HolidayItem;
  onPunchClick: (type: 'IN' | 'OUT') => void;
  onViewPhoto?: (photoUrl: string) => void;
}

export const HomeTabContent: React.FC<HomeTabContentProps> = ({
  user,
  todayPunches,
  isRecordingPunch,
  todayHoliday,
  onPunchClick,
  onViewPhoto,
}) => {
  // Live Clock
  const [currentTime, setCurrentTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const timeString = currentTime.toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: true,
  });

  const dateString = currentTime.toLocaleDateString('en-US', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });

  // Calculate today's in and out punch
  const todayCheckIn = todayPunches.find((p) => p.type.toLowerCase() === 'in');
  const todayCheckOut = todayPunches.find((p) => p.type.toLowerCase() === 'out');
  const hasCheckedInToday = Boolean(todayCheckIn);
  const hasCheckedOutToday = Boolean(todayCheckOut);

  // Elapsed duration if checked in
  const getElapsedShift = () => {
    if (!todayCheckIn) return null;
    try {
      const inTime = new Date(todayCheckIn.deviceTime).getTime();
      const endTime = todayCheckOut ? new Date(todayCheckOut.deviceTime).getTime() : currentTime.getTime();
      const diffMs = Math.max(0, endTime - inTime);
      const hours = Math.floor(diffMs / 3600000);
      const minutes = Math.floor((diffMs % 3600000) / 60000);
      const seconds = Math.floor((diffMs % 60000) / 1000);
      return `${String(hours).padStart(2, '0')}h ${String(minutes).padStart(2, '0')}m ${String(seconds).padStart(2, '0')}s`;
    } catch {
      return null;
    }
  };

  return (
    <div className="space-y-4 sm:space-y-5">
      {/* 0. Official Company Holiday Banner */}
      {todayHoliday && (
        <div className="p-4 bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200/80 rounded-2xl flex items-start gap-3.5 shadow-xs">
          <div className="w-10 h-10 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center shrink-0">
            <PartyPopper size={22} />
          </div>
          <div className="flex-1">
            <span className="text-[10px] font-extrabold uppercase tracking-wider text-amber-800 bg-amber-200/60 px-2 py-0.5 rounded">
              Official Company Holiday Today
            </span>
            <h4 className="font-bold text-slate-900 text-base mt-1">{todayHoliday.name}</h4>
            {todayHoliday.description && (
              <p className="text-xs text-slate-600 mt-0.5">{todayHoliday.description}</p>
            )}
          </div>
        </div>
      )}

      {/* 1. Welcome & Live Clock Card */}
      <CustomCard className="bg-gradient-to-b from-white to-slate-50/70 border-slate-200">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 mb-4 border-b border-slate-100">
          <div className="flex items-center gap-2 text-slate-700 bg-slate-100/80 border border-slate-200 px-3 py-1.5 rounded-xl w-fit">
            <Clock size={16} className="text-indigo-600 animate-spin-slow" />
            <span className="font-mono font-bold text-sm tracking-wide text-slate-900">{timeString}</span>
          </div>

          <div className="flex items-center gap-2 text-xs font-medium text-slate-500">
            <Calendar size={14} />
            <span>{dateString}</span>
          </div>
        </div>

        <div className="mb-4">
          <span className="text-xs font-medium text-slate-500">Welcome back,</span>
          <h2 className="text-2xl font-black text-slate-900 tracking-tight mt-0.5">
            {user?.name || 'Employee'}
          </h2>
          <div className="flex flex-wrap items-center gap-2 mt-2">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold bg-indigo-50 text-indigo-700 border border-indigo-200">
              {user?.designation || 'Staff Engineer'}
            </span>
            <span className="text-xs font-medium text-slate-500">
              {user?.department || 'MNIT Solutions'}
            </span>
          </div>
        </div>

        {/* Punch Status Indicator Pill */}
        <div
          className={`p-3.5 rounded-xl border flex items-center justify-between text-xs sm:text-sm font-semibold transition ${
            hasCheckedInToday && hasCheckedOutToday
              ? 'bg-blue-50/80 border-blue-200 text-blue-800'
              : hasCheckedInToday
              ? 'bg-emerald-50/80 border-emerald-200 text-emerald-800'
              : 'bg-slate-100/80 border-slate-200 text-slate-700'
          }`}
        >
          <div className="flex items-center gap-2.5">
            <span
              className={`w-3 h-3 rounded-full flex items-center justify-center ${
                hasCheckedInToday && hasCheckedOutToday
                  ? 'bg-blue-600'
                  : hasCheckedInToday
                  ? 'bg-emerald-500 animate-pulse'
                  : 'bg-slate-400'
              }`}
            >
              <span className="w-1.5 h-1.5 bg-white rounded-full" />
            </span>
            <span>
              {hasCheckedInToday && hasCheckedOutToday
                ? 'Workday Concluded (Both Punches Logged)'
                : hasCheckedInToday
                ? 'Checked In • Working (Shift Active)'
                : 'Not Checked In Today'}
            </span>
          </div>

          {hasCheckedInToday && (
            <span className="text-xs font-mono font-bold bg-white/80 px-2 py-0.5 rounded border shadow-2xs">
              {getElapsedShift()}
            </span>
          )}
        </div>
      </CustomCard>

      {/* 2. Punch Action Card (State Machine) */}
      <CustomCard className="border-indigo-100 shadow-md">
        {hasCheckedInToday && hasCheckedOutToday ? (
          // CASE 1: BOTH CHECKED IN AND OUT
          <div className="text-center py-4">
            <div className="w-14 h-14 bg-blue-50 text-blue-600 border border-blue-200 rounded-2xl flex items-center justify-center mx-auto mb-3">
              <CheckCircle2 size={32} />
            </div>
            <h3 className="text-lg font-bold text-slate-900">Workday Completed Today</h3>
            <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
              You have completed both IN and OUT attendance punches for today with verified GPS location and selfie.
            </p>
            <div className="mt-4 pt-3 border-t border-slate-100 inline-flex items-center gap-4 text-xs text-slate-600">
              <span>IN: <strong className="text-slate-900">{todayCheckIn?.deviceTime.slice(11, 19)}</strong></span>
              <span>•</span>
              <span>OUT: <strong className="text-slate-900">{todayCheckOut?.deviceTime.slice(11, 19)}</strong></span>
              <span>•</span>
              <span>Total: <strong className="text-indigo-600">{getElapsedShift()}</strong></span>
            </div>
          </div>
        ) : hasCheckedInToday ? (
          // CASE 2: CHECKED IN, SHOW CHECK OUT
          <div>
            <div className="flex items-center justify-between mb-2">
              <h3 className="font-bold text-slate-900 text-base">Attendance Check-Out</h3>
              <span className="text-xs text-slate-500 font-mono">
                In: {todayCheckIn?.deviceTime.slice(11, 19)}
              </span>
            </div>
            <p className="text-xs text-slate-500 mb-5">
              Ready to conclude your workday? Capture your departure selfie and GPS location to submit punch OUT.
            </p>

            <button
              onClick={() => onPunchClick('OUT')}
              disabled={isRecordingPunch}
              className="w-full py-4 px-6 bg-gradient-to-r from-rose-600 to-rose-500 hover:from-rose-500 hover:to-rose-400 active:scale-[0.99] text-white font-extrabold text-base tracking-wider rounded-2xl shadow-xl shadow-rose-600/30 transition flex items-center justify-center gap-3 disabled:opacity-60"
            >
              <ArrowLeftToLine size={22} className="stroke-[2.5]" />
              <span>CHECK OUT</span>
            </button>
          </div>
        ) : (
          // CASE 3: NOT YET CHECKED IN, SHOW CHECK IN
          <div>
            <div className="flex items-center justify-between mb-2">
              <h3 className="font-bold text-slate-900 text-base">Attendance Check-In</h3>
              <span className="text-xs font-semibold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                Shift Ready
              </span>
            </div>
            <p className="text-xs text-slate-500 mb-5">
              Start your workday with instant GPS verification and front camera face capture.
            </p>

            <button
              onClick={() => onPunchClick('IN')}
              disabled={isRecordingPunch}
              className="w-full py-4 px-6 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 active:scale-[0.99] text-white font-extrabold text-base tracking-wider rounded-2xl shadow-xl shadow-emerald-600/30 transition flex items-center justify-center gap-3 disabled:opacity-60"
            >
              <ArrowRightToLine size={22} className="stroke-[2.5]" />
              <span>CHECK IN</span>
            </button>
          </div>
        )}
      </CustomCard>

      {/* 3. Today's Punches History */}
      <CustomCard>
        <div className="flex items-center justify-between pb-3 mb-3 border-b border-slate-100">
          <div>
            <h3 className="font-bold text-slate-900 text-base">Today's Punch Log</h3>
            <p className="text-xs text-slate-500 mt-0.5">{todayPunches.length} punch event(s) recorded</p>
          </div>
          <span className="px-2.5 py-1 rounded-lg text-xs font-bold text-slate-700 bg-slate-100 border border-slate-200">
            {currentTime.toLocaleDateString('en-US', { day: 'numeric', month: 'short' })}
          </span>
        </div>

        {todayPunches.length === 0 ? (
          <div className="text-center py-8 text-slate-400">
            <Clock size={32} className="mx-auto mb-2 text-slate-300" />
            <p className="text-xs font-medium">No punches recorded today yet.</p>
            <p className="text-[11px] text-slate-400 mt-0.5">Click CHECK IN above when starting work.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {todayPunches.map((punch) => (
              <div
                key={punch.id}
                className="p-3 rounded-xl border border-slate-200/80 bg-slate-50/60 hover:bg-slate-50 flex items-center justify-between gap-3 transition"
              >
                {/* Selfie Thumbnail */}
                <div
                  onClick={() => onViewPhoto && onViewPhoto(punch.selfiePath)}
                  className="w-12 h-12 rounded-xl bg-slate-200 border border-slate-300 overflow-hidden shrink-0 cursor-pointer relative group"
                  title="Click to inspect verification photo"
                >
                  <img
                    src={punch.selfiePath}
                    alt="Punch verification"
                    className="w-full h-full object-cover group-hover:scale-110 transition"
                  />
                  <div className="absolute inset-0 bg-black/30 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white text-[10px] transition">
                    <ExternalLink size={12} />
                  </div>
                </div>

                {/* Details */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <StatusPill status={punch.type} />
                    <span className="text-xs font-bold text-slate-900 font-mono">
                      {punch.deviceTime.slice(11, 19)}
                    </span>
                  </div>

                  <div className="flex items-center gap-1 text-[11px] text-slate-500 mt-1 truncate">
                    <MapPin size={11} className="shrink-0 text-slate-400" />
                    <span>
                      {punch.latitude.toFixed(4)}°, {punch.longitude.toFixed(4)}° (±{punch.accuracy}m)
                    </span>
                  </div>
                </div>

                {/* Sync Pill */}
                <div className="shrink-0">
                  <StatusPill status={punch.syncStatus} />
                </div>
              </div>
            ))}
          </div>
        )}
      </CustomCard>
    </div>
  );
};

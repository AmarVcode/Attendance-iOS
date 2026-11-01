import React, { useState } from 'react';
import { Clock, Filter, MapPin, RefreshCw, CheckCircle2, AlertCircle, ArrowUpRight, Search } from 'lucide-react';
import { AttendancePunchRecord } from '../../types';
import { CustomCard } from '../common/CustomCard';
import { StatusPill } from '../common/StatusPill';

interface PunchesHistoryTabProps {
  allPunches: AttendancePunchRecord[];
  isSyncing: boolean;
  onSyncNow: () => void;
  onViewPhoto?: (photoUrl: string) => void;
}

export const PunchesHistoryTab: React.FC<PunchesHistoryTabProps> = ({
  allPunches,
  isSyncing,
  onSyncNow,
  onViewPhoto,
}) => {
  const [filter, setFilter] = useState<'ALL' | 'SYNCED' | 'PENDING' | 'FAILED'>('ALL');
  const [searchQuery, setSearchQuery] = useState('');

  const filtered = allPunches.filter((punch) => {
    if (filter === 'SYNCED' && punch.syncStatus !== 'SYNCED') return false;
    if (filter === 'PENDING' && punch.syncStatus !== 'PENDING' && punch.syncStatus !== 'SYNCING') return false;
    if (filter === 'FAILED' && punch.syncStatus !== 'FAILED') return false;

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        punch.date.includes(q) ||
        punch.deviceTime.includes(q) ||
        punch.type.toLowerCase().includes(q) ||
        punch.deviceUid.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const pendingCount = allPunches.filter((p) => p.syncStatus === 'PENDING' || p.syncStatus === 'FAILED').length;

  return (
    <div className="space-y-4 sm:space-y-5">
      {/* Top Header Card */}
      <CustomCard>
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-100">
          <div>
            <h2 className="text-lg sm:text-xl font-bold text-slate-900">Device Punch Log</h2>
            <p className="text-xs text-slate-500 mt-0.5">
              Complete offline-first attendance trail stored on this device ({allPunches.length} total events)
            </p>
          </div>

          <div className="flex items-center gap-2">
            {pendingCount > 0 && (
              <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800 border border-amber-200">
                {pendingCount} Pending Sync
              </span>
            )}
            <button
              onClick={onSyncNow}
              disabled={isSyncing}
              className="py-1.5 px-3 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 border border-indigo-200 rounded-xl text-xs font-semibold flex items-center gap-1.5 transition disabled:opacity-50"
            >
              <RefreshCw size={13} className={isSyncing ? 'animate-spin' : ''} />
              {isSyncing ? 'Syncing...' : 'Sync Cloud'}
            </button>
          </div>
        </div>

        {/* Filter Pills and Search */}
        <div className="mt-4 flex flex-col sm:flex-row gap-3 items-center justify-between">
          <div className="flex items-center gap-1.5 w-full sm:w-auto overflow-x-auto pb-1 sm:pb-0">
            {(['ALL', 'SYNCED', 'PENDING', 'FAILED'] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setFilter(tab)}
                className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition whitespace-nowrap ${
                  filter === tab
                    ? 'bg-indigo-600 text-white shadow-xs'
                    : 'bg-slate-100 hover:bg-slate-200/80 text-slate-600'
                }`}
              >
                {tab === 'ALL'
                  ? `All (${allPunches.length})`
                  : tab === 'SYNCED'
                  ? `Synced (${allPunches.filter((p) => p.syncStatus === 'SYNCED').length})`
                  : tab === 'PENDING'
                  ? `Pending (${allPunches.filter((p) => p.syncStatus === 'PENDING' || p.syncStatus === 'SYNCING').length})`
                  : `Failed (${allPunches.filter((p) => p.syncStatus === 'FAILED').length})`}
              </button>
            ))}
          </div>

          <div className="relative w-full sm:w-56">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search date or ID..."
              className="w-full pl-8 pr-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition"
            />
          </div>
        </div>
      </CustomCard>

      {/* Punches List */}
      <CustomCard>
        {filtered.length === 0 ? (
          <div className="text-center py-10 text-slate-400">
            <Clock size={36} className="mx-auto mb-2 text-slate-300" />
            <p className="text-sm font-medium">No attendance punches match this filter.</p>
            <p className="text-xs text-slate-400 mt-1">Punches recorded via Check In/Out will appear here.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {filtered.map((punch) => (
              <div
                key={punch.id}
                className="p-3.5 rounded-2xl border border-slate-200/80 bg-white hover:bg-slate-50/50 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-2xs transition"
              >
                <div className="flex items-start gap-3">
                  {/* Selfie Preview */}
                  <div
                    onClick={() => onViewPhoto && onViewPhoto(punch.selfiePath)}
                    className="w-14 h-14 rounded-xl bg-slate-100 border border-slate-200 overflow-hidden shrink-0 cursor-pointer relative group"
                    title="Click to view full photo"
                  >
                    <img
                      src={punch.selfiePath}
                      alt="Punch verification"
                      className="w-full h-full object-cover group-hover:scale-105 transition"
                    />
                    <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white text-[10px] font-medium transition">
                      View
                    </div>
                  </div>

                  {/* Punch Data */}
                  <div>
                    <div className="flex items-center gap-2">
                      <StatusPill status={punch.type} />
                      <span className="font-mono font-bold text-slate-900 text-sm">
                        {punch.deviceTime}
                      </span>
                    </div>

                    <div className="flex flex-wrap items-center gap-3 text-xs text-slate-500 mt-1.5">
                      <span className="flex items-center gap-1 font-mono">
                        <MapPin size={12} className="text-slate-400 shrink-0" />
                        {punch.latitude.toFixed(5)}°, {punch.longitude.toFixed(5)}° (±{punch.accuracy}m)
                      </span>
                      <span className="text-slate-300">•</span>
                      <span className="text-[11px] font-mono text-slate-400 truncate max-w-[150px]">
                        {punch.deviceUid}
                      </span>
                    </div>

                    {punch.syncErrorMessage && (
                      <p className="text-[11px] text-rose-600 font-medium mt-1">
                        Reason: {punch.syncErrorMessage}
                      </p>
                    )}
                  </div>
                </div>

                <div className="flex sm:flex-col items-center sm:items-end justify-between sm:justify-center gap-2 pt-2 sm:pt-0 border-t sm:border-t-0 border-slate-100">
                  <StatusPill status={punch.syncStatus} />
                  {punch.serverPunchId && (
                    <span className="text-[10px] font-mono text-slate-400">
                      Server #{punch.serverPunchId}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </CustomCard>
    </div>
  );
};

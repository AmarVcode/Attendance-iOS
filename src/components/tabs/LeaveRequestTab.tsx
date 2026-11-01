import React, { useState } from 'react';
import { Calendar, Clock, PlusCircle, CheckCircle2, AlertCircle, RefreshCw, Send, ChevronDown } from 'lucide-react';
import { LeaveBalanceData, LeaveRequestItem, LeaveType } from '../../types';
import { CustomCard } from '../common/CustomCard';
import { StatusPill } from '../common/StatusPill';

interface LeaveRequestTabProps {
  leaveBalance: LeaveBalanceData;
  leaveTypes: LeaveType[];
  leaveRequests: LeaveRequestItem[];
  isLoading: boolean;
  isSubmitting: boolean;
  onRefresh: () => void;
  onSubmitLeave: (
    leaveTypeId: number,
    startDate: string,
    endDate: string,
    reason: string,
    onSuccess: () => void
  ) => void;
}

export const LeaveRequestTab: React.FC<LeaveRequestTabProps> = ({
  leaveBalance,
  leaveTypes,
  leaveRequests,
  isLoading,
  isSubmitting,
  onRefresh,
  onSubmitLeave,
}) => {
  const [isApplying, setIsApplying] = useState(false);
  const [selectedTypeId, setSelectedTypeId] = useState<number>(leaveTypes[0]?.id || 1);

  const todayStr = new Date().toISOString().slice(0, 10);
  const [startDate, setStartDate] = useState(todayStr);
  const [endDate, setEndDate] = useState(todayStr);
  const [reason, setReason] = useState('');
  const [formError, setFormError] = useState<string | null>(null);

  // Calculate day count
  const calculateDays = (start: string, end: string) => {
    if (!start || !end) return 1;
    const d1 = new Date(start);
    const d2 = new Date(end);
    if (isNaN(d1.getTime()) || isNaN(d2.getTime())) return 1;
    const diffTime = d2.getTime() - d1.getTime();
    if (diffTime < 0) return 0;
    return Math.round(diffTime / (1000 * 3600 * 24)) + 1;
  };

  const requestedDays = calculateDays(startDate, endDate);
  const remainingQuota = leaveBalance.remaining ?? 12.0;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    if (requestedDays <= 0) {
      setFormError('End date must be greater than or equal to start date.');
      return;
    }

    if (!reason.trim()) {
      setFormError('Please describe the purpose or reason for the requested leave.');
      return;
    }

    if (requestedDays > remainingQuota) {
      setFormError(`Requested ${requestedDays} day(s) exceeds remaining paid quota of ${remainingQuota} day(s).`);
      return;
    }

    onSubmitLeave(selectedTypeId, startDate, endDate, reason.trim(), () => {
      setReason('');
      setIsApplying(false);
    });
  };

  return (
    <div className="space-y-4 sm:space-y-5">
      {/* 1. Leave Balance Quota Card */}
      <CustomCard>
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <Calendar size={18} />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-900">Annual Paid Leave Balance</h2>
              <p className="text-xs text-slate-500">Official MNIT leave allotment for current calendar year</p>
            </div>
          </div>
          <button
            onClick={onRefresh}
            title="Refresh balance"
            className="text-slate-400 hover:text-slate-700 transition"
          >
            <RefreshCw size={14} className={isLoading ? 'animate-spin' : ''} />
          </button>
        </div>

        <div className="grid grid-cols-3 gap-3 mt-4">
          <div className="bg-slate-50 border border-slate-200/80 rounded-xl p-3 text-center">
            <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider block">
              Total Quota
            </span>
            <span className="text-xl sm:text-2xl font-black text-slate-900 mt-1 block">
              {leaveBalance.totalAssigned ?? 12.0}
            </span>
            <span className="text-[10px] text-slate-400">Days / Year</span>
          </div>

          <div className="bg-rose-50/70 border border-rose-100 rounded-xl p-3 text-center">
            <span className="text-[11px] font-semibold text-rose-700 uppercase tracking-wider block">
              Leaves Taken
            </span>
            <span className="text-xl sm:text-2xl font-black text-rose-800 mt-1 block">
              {leaveBalance.used ?? 0.0}
            </span>
            <span className="text-[10px] text-rose-600/80">Approved</span>
          </div>

          <div className="bg-emerald-50/80 border border-emerald-200 rounded-xl p-3 text-center">
            <span className="text-[11px] font-semibold text-emerald-800 uppercase tracking-wider block">
              Remaining
            </span>
            <span className="text-xl sm:text-2xl font-black text-emerald-700 mt-1 block">
              {leaveBalance.remaining ?? 12.0}
            </span>
            <span className="text-[10px] text-emerald-600/80 font-medium">Available</span>
          </div>
        </div>

        {/* Toggle Apply Leave Form Button */}
        <div className="mt-4 pt-3 border-t border-slate-100">
          <button
            type="button"
            onClick={() => setIsApplying(!isApplying)}
            className={`w-full py-2.5 px-4 rounded-xl font-bold text-xs sm:text-sm transition flex items-center justify-center gap-2 ${
              isApplying
                ? 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                : 'bg-indigo-600 hover:bg-indigo-700 text-white shadow-md shadow-indigo-600/20'
            }`}
          >
            {isApplying ? (
              <>Cancel Leave Request</>
            ) : (
              <>
                <PlusCircle size={16} /> Apply for New Leave
              </>
            )}
          </button>
        </div>
      </CustomCard>

      {/* 2. Collapsible Apply Form */}
      {isApplying && (
        <CustomCard className="border-indigo-200 bg-gradient-to-b from-indigo-50/40 to-white animate-in slide-in-from-top-2 duration-200">
          <div className="flex items-center justify-between pb-3 mb-4 border-b border-indigo-100">
            <h3 className="font-bold text-slate-900 text-base">New Leave Application</h3>
            <span className="text-xs font-semibold text-indigo-700 bg-indigo-100 px-2.5 py-0.5 rounded-full">
              {requestedDays} Day(s) Requested
            </span>
          </div>

          {formError && (
            <div className="mb-4 p-3 bg-rose-50 border border-rose-200 text-rose-700 rounded-xl text-xs flex items-center gap-2">
              <AlertCircle size={16} className="shrink-0" />
              <span>{formError}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Leave Type */}
            <div>
              <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                Leave Category *
              </label>
              <select
                value={selectedTypeId}
                onChange={(e) => setSelectedTypeId(Number(e.target.value))}
                className="w-full px-3 py-2.5 bg-white border border-slate-200 rounded-xl text-xs sm:text-sm focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 transition"
              >
                {leaveTypes.map((type) => (
                  <option key={type.id} value={type.id}>
                    {type.name} {type.description ? `— ${type.description}` : ''}
                  </option>
                ))}
              </select>
            </div>

            {/* Date Range */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                  Start Date *
                </label>
                <input
                  type="date"
                  required
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs sm:text-sm focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 transition"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                  End Date *
                </label>
                <input
                  type="date"
                  required
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  className="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs sm:text-sm focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 transition"
                />
              </div>
            </div>

            {/* Reason */}
            <div>
              <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                Detailed Reason / Remarks *
              </label>
              <textarea
                required
                rows={3}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="State reason for absence and handover details..."
                className="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs sm:text-sm focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 transition"
              />
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full py-3 px-4 bg-indigo-600 hover:bg-indigo-700 active:scale-[0.99] text-white font-bold text-xs sm:text-sm rounded-xl shadow-md transition flex items-center justify-center gap-2 disabled:opacity-50"
            >
              {isSubmitting ? (
                <>
                  <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                  <span>Submitting to Department HOD...</span>
                </>
              ) : (
                <>
                  <Send size={15} />
                  <span>Submit Leave Application</span>
                </>
              )}
            </button>
          </form>
        </CustomCard>
      )}

      {/* 3. My Applications List */}
      <CustomCard>
        <div className="flex items-center justify-between pb-3 mb-3 border-b border-slate-100">
          <div>
            <h3 className="font-bold text-slate-900 text-base">My Leave Applications</h3>
            <p className="text-xs text-slate-500 mt-0.5">Track approvals & supervisor review notes</p>
          </div>
          <span className="px-2.5 py-0.5 rounded-full text-xs font-bold text-slate-600 bg-slate-100">
            {leaveRequests.length} Record(s)
          </span>
        </div>

        {leaveRequests.length === 0 ? (
          <div className="text-center py-8 text-slate-400">
            <Calendar size={32} className="mx-auto mb-2 text-slate-300" />
            <p className="text-xs font-medium">No leave applications recorded yet.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {leaveRequests.map((req) => (
              <div
                key={req.id}
                className="p-3.5 rounded-2xl border border-slate-200/80 bg-white hover:bg-slate-50/50 transition flex flex-col gap-2"
              >
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <h4 className="font-bold text-slate-900 text-xs sm:text-sm">
                      {req.leaveType?.name || 'Leave Application'}
                    </h4>
                    <span className="text-xs font-semibold text-indigo-700 bg-indigo-50 px-2 py-0.5 rounded border border-indigo-100 mt-1 inline-block">
                      {req.startDate} to {req.endDate} ({req.totalDays} day{req.totalDays !== 1 ? 's' : ''})
                    </span>
                  </div>
                  <StatusPill status={req.status} />
                </div>

                {req.reason && (
                  <p className="text-xs text-slate-600 bg-slate-50 p-2 rounded-lg border border-slate-100 mt-1">
                    "{req.reason}"
                  </p>
                )}

                {req.reviewNotes && (
                  <div className="text-[11px] text-slate-500 bg-indigo-50/50 p-2 rounded-lg border border-indigo-100/60 mt-1 flex items-start gap-1.5">
                    <CheckCircle2 size={13} className="text-indigo-600 shrink-0 mt-0.5" />
                    <div>
                      <strong className="text-slate-700">{req.reviewedBy || 'Admin'}:</strong> {req.reviewNotes}
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </CustomCard>
    </div>
  );
};

import React from 'react';

interface StatusPillProps {
  status: 'PENDING' | 'SYNCED' | 'FAILED' | 'SYNCING' | 'approved' | 'pending' | 'rejected' | 'active' | 'in' | 'out' | string;
  label?: string;
  size?: 'sm' | 'md';
}

export const StatusPill: React.FC<StatusPillProps> = ({ status, label, size = 'sm' }) => {
  const norm = status.toUpperCase();

  let bg = 'bg-slate-100 text-slate-700 border-slate-200';
  let dot = 'bg-slate-400';
  let displayLabel = label || status;

  if (norm === 'SYNCED' || norm === 'APPROVED' || norm === 'ACTIVE' || norm === 'IN') {
    bg = 'bg-emerald-50 text-emerald-700 border-emerald-200';
    dot = 'bg-emerald-500';
    if (norm === 'IN' && !label) displayLabel = 'PUNCH IN';
  } else if (norm === 'PENDING' || norm === 'SYNCING') {
    bg = 'bg-amber-50 text-amber-700 border-amber-200';
    dot = 'bg-amber-500 animate-pulse';
    if (norm === 'PENDING' && !label) displayLabel = 'PENDING SYNC';
  } else if (norm === 'FAILED' || norm === 'REJECTED' || norm === 'OUT') {
    if (norm === 'OUT') {
      bg = 'bg-rose-50 text-rose-700 border-rose-200';
      dot = 'bg-rose-500';
      if (!label) displayLabel = 'PUNCH OUT';
    } else {
      bg = 'bg-rose-50 text-rose-700 border-rose-200';
      dot = 'bg-rose-500';
    }
  }

  const sizeCls = size === 'sm' ? 'px-2.5 py-0.5 text-xs font-semibold' : 'px-3 py-1 text-sm font-semibold';

  return (
    <span className={`inline-flex items-center gap-1.5 rounded-full border ${bg} ${sizeCls} tracking-wide`}>
      <span className={`w-1.5 h-1.5 rounded-full ${dot}`} />
      <span>{displayLabel}</span>
    </span>
  );
};

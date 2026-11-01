import React, { useState, useMemo } from 'react';
import { ChevronLeft, ChevronRight, Calendar as CalendarIcon, Clock, Award, PartyPopper, MapPin } from 'lucide-react';
import { AttendancePunchRecord, HolidayItem } from '../../types';
import { CustomCard } from '../common/CustomCard';
import { StatusPill } from '../common/StatusPill';

interface MonthlyCalendarTabProps {
  allPunches: AttendancePunchRecord[];
  holidays: HolidayItem[];
  onMonthChanged?: (monthPrefix: string) => void;
  onViewPhoto?: (photoUrl: string) => void;
}

export const MonthlyCalendarTab: React.FC<MonthlyCalendarTabProps> = ({
  allPunches,
  holidays,
  onMonthChanged,
  onViewPhoto,
}) => {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedDateStr, setSelectedDateStr] = useState<string>(
    new Date().toISOString().slice(0, 10)
  );

  const year = currentDate.getFullYear();
  const month = currentDate.getMonth(); // 0-indexed

  const monthPrefix = `${year}-${String(month + 1).padStart(2, '0')}`;
  const monthName = currentDate.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });

  const prevMonth = () => {
    const next = new Date(year, month - 1, 1);
    setCurrentDate(next);
    const prefix = `${next.getFullYear()}-${String(next.getMonth() + 1).padStart(2, '0')}`;
    onMonthChanged?.(prefix);
  };

  const nextMonth = () => {
    const next = new Date(year, month + 1, 1);
    setCurrentDate(next);
    const prefix = `${next.getFullYear()}-${String(next.getMonth() + 1).padStart(2, '0')}`;
    onMonthChanged?.(prefix);
  };

  // Group punches by date (YYYY-MM-DD)
  const punchesByDate = useMemo(() => {
    const map = new Map<string, AttendancePunchRecord[]>();
    for (const p of allPunches) {
      const list = map.get(p.date) || [];
      list.push(p);
      map.set(p.date, list);
    }
    return map;
  }, [allPunches]);

  // Holidays by date
  const holidaysByDate = useMemo(() => {
    const map = new Map<string, HolidayItem>();
    for (const h of holidays) {
      if (h.date) map.set(h.date, h);
    }
    return map;
  }, [holidays]);

  // Monthly stats
  const { workedDaysCount, totalWorkHoursStr } = useMemo(() => {
    let days = 0;
    let totalMinutes = 0;

    for (const [dateStr, list] of punchesByDate.entries()) {
      if (dateStr.startsWith(monthPrefix)) {
        days++;
        const inPunch = list.find((p) => p.type.toLowerCase() === 'in');
        const outPunch = list.find((p) => p.type.toLowerCase() === 'out');
        if (inPunch && outPunch) {
          const tIn = new Date(inPunch.deviceTime).getTime();
          const tOut = new Date(outPunch.deviceTime).getTime();
          const diff = Math.max(0, Math.floor((tOut - tIn) / 60000));
          totalMinutes += diff;
        } else if (inPunch) {
          // Half day or default 4 hours if only in punch
          totalMinutes += 240;
        }
      }
    }

    const hrs = Math.floor(totalMinutes / 60);
    const mins = totalMinutes % 60;
    return {
      workedDaysCount: days,
      totalWorkHoursStr: `${hrs}h ${mins}m`,
    };
  }, [punchesByDate, monthPrefix]);

  // Month holidays
  const monthHolidays = useMemo(() => {
    return holidays
      .filter((h) => h.date?.startsWith(monthPrefix))
      .sort((a, b) => (a.date || '').localeCompare(b.date || ''));
  }, [holidays, monthPrefix]);

  // Calendar matrix calculation
  const calendarDays = useMemo(() => {
    const firstDayIndex = new Date(year, month, 1).getDay(); // 0 is Sunday
    const daysInCurrentMonth = new Date(year, month + 1, 0).getDate();
    const daysInPrevMonth = new Date(year, month, 0).getDate();

    const days: Array<{
      dayNum: number;
      dateStr: string;
      isCurrentMonth: boolean;
      isWeekend: boolean;
      hasPunches: boolean;
      holiday?: HolidayItem;
    }> = [];

    // Prev month padding
    for (let i = firstDayIndex - 1; i >= 0; i--) {
      const d = daysInPrevMonth - i;
      const prevDate = new Date(year, month - 1, d);
      const str = prevDate.toISOString().slice(0, 10);
      days.push({
        dayNum: d,
        dateStr: str,
        isCurrentMonth: false,
        isWeekend: prevDate.getDay() === 0 || prevDate.getDay() === 6,
        hasPunches: punchesByDate.has(str),
        holiday: holidaysByDate.get(str),
      });
    }

    // Current month days
    for (let d = 1; d <= daysInCurrentMonth; d++) {
      const cur = new Date(year, month, d);
      const str = `${year}-${String(month + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      days.push({
        dayNum: d,
        dateStr: str,
        isCurrentMonth: true,
        isWeekend: cur.getDay() === 0 || cur.getDay() === 6,
        hasPunches: punchesByDate.has(str),
        holiday: holidaysByDate.get(str),
      });
    }

    // Next month padding to fill up to 35 or 42 cells
    const remaining = (7 - (days.length % 7)) % 7;
    for (let d = 1; d <= remaining; d++) {
      const nextDate = new Date(year, month + 1, d);
      const str = nextDate.toISOString().slice(0, 10);
      days.push({
        dayNum: d,
        dateStr: str,
        isCurrentMonth: false,
        isWeekend: nextDate.getDay() === 0 || nextDate.getDay() === 6,
        hasPunches: punchesByDate.has(str),
        holiday: holidaysByDate.get(str),
      });
    }

    return days;
  }, [year, month, punchesByDate, holidaysByDate]);

  // Selected date details
  const selectedPunches = punchesByDate.get(selectedDateStr) || [];
  const selectedHoliday = holidaysByDate.get(selectedDateStr);

  return (
    <div className="space-y-4 sm:space-y-5">
      {/* 1. Month Navigation Header Card */}
      <CustomCard>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <button
              onClick={prevMonth}
              className="w-9 h-9 rounded-xl border border-slate-200 bg-slate-50 hover:bg-slate-100 flex items-center justify-center text-slate-700 transition"
              title="Previous Month"
            >
              <ChevronLeft size={18} />
            </button>
            <h2 className="text-lg sm:text-xl font-bold text-slate-900 min-w-[150px] text-center">
              {monthName}
            </h2>
            <button
              onClick={nextMonth}
              className="w-9 h-9 rounded-xl border border-slate-200 bg-slate-50 hover:bg-slate-100 flex items-center justify-center text-slate-700 transition"
              title="Next Month"
            >
              <ChevronRight size={18} />
            </button>
          </div>

          <button
            onClick={() => {
              const now = new Date();
              setCurrentDate(now);
              setSelectedDateStr(now.toISOString().slice(0, 10));
            }}
            className="text-xs font-semibold text-indigo-600 hover:text-indigo-800 bg-indigo-50 border border-indigo-200 px-3 py-1.5 rounded-xl transition"
          >
            Today
          </button>
        </div>

        {/* Month Summary Metrics */}
        <div className="grid grid-cols-3 gap-2.5 sm:gap-4 mt-5 pt-4 border-t border-slate-100">
          <div className="bg-slate-50 border border-slate-200/80 rounded-xl p-3 text-center">
            <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider block">
              Days Worked
            </span>
            <span className="text-xl font-black text-slate-900 mt-1 block">
              {workedDaysCount}
            </span>
          </div>

          <div className="bg-indigo-50/70 border border-indigo-100 rounded-xl p-3 text-center">
            <span className="text-[11px] font-semibold text-indigo-700 uppercase tracking-wider block">
              Total Hours
            </span>
            <span className="text-xl font-black text-indigo-900 mt-1 block">
              {totalWorkHoursStr}
            </span>
          </div>

          <div className="bg-amber-50/70 border border-amber-100 rounded-xl p-3 text-center">
            <span className="text-[11px] font-semibold text-amber-700 uppercase tracking-wider block">
              Holidays
            </span>
            <span className="text-xl font-black text-amber-900 mt-1 block">
              {monthHolidays.length}
            </span>
          </div>
        </div>
      </CustomCard>

      {/* 2. Interactive Calendar Grid */}
      <CustomCard>
        {/* Day Header Row */}
        <div className="grid grid-cols-7 gap-1 text-center font-bold text-xs text-slate-400 mb-2 py-1 border-b border-slate-100">
          <span>Sun</span>
          <span>Mon</span>
          <span>Tue</span>
          <span>Wed</span>
          <span>Thu</span>
          <span>Fri</span>
          <span>Sat</span>
        </div>

        {/* Days Matrix */}
        <div className="grid grid-cols-7 gap-1 sm:gap-1.5">
          {calendarDays.map((item, idx) => {
            const isSelected = item.dateStr === selectedDateStr;
            const isToday = item.dateStr === new Date().toISOString().slice(0, 10);

            return (
              <button
                key={idx}
                type="button"
                onClick={() => setSelectedDateStr(item.dateStr)}
                className={`min-h-[58px] sm:min-h-[64px] rounded-xl p-1.5 flex flex-col items-center justify-between transition relative border text-xs ${
                  isSelected
                    ? 'border-indigo-600 bg-indigo-50/80 shadow-xs ring-2 ring-indigo-500/30'
                    : item.isCurrentMonth
                    ? 'border-slate-100 bg-white hover:border-slate-300 hover:bg-slate-50/60'
                    : 'border-transparent bg-slate-50/30 text-slate-300'
                }`}
              >
                {/* Day number with Today marker */}
                <div className="w-full flex justify-between items-center px-0.5">
                  <span
                    className={`font-semibold text-xs ${
                      isSelected
                        ? 'text-indigo-900 font-bold'
                        : isToday
                        ? 'bg-indigo-600 text-white w-5 h-5 rounded-full flex items-center justify-center font-bold'
                        : item.isCurrentMonth
                        ? item.isWeekend
                          ? 'text-slate-400'
                          : 'text-slate-700'
                        : 'text-slate-300'
                    }`}
                  >
                    {item.dayNum}
                  </span>

                  {item.holiday && (
                    <span className="text-[10px]" title={item.holiday.name}>
                      🎉
                    </span>
                  )}
                </div>

                {/* Status Badges */}
                <div className="w-full flex flex-col items-center gap-0.5 mt-1">
                  {item.hasPunches ? (
                    <span className="w-full py-0.5 rounded text-[9px] font-bold text-emerald-800 bg-emerald-100 text-center truncate">
                      Present
                    </span>
                  ) : item.holiday ? (
                    <span className="w-full py-0.5 rounded text-[9px] font-bold text-amber-800 bg-amber-100 text-center truncate">
                      Holiday
                    </span>
                  ) : item.isWeekend ? (
                    <span className="text-[9px] text-slate-300 font-medium">Off</span>
                  ) : null}
                </div>
              </button>
            );
          })}
        </div>
      </CustomCard>

      {/* 3. Selected Day Drilldown */}
      <CustomCard className="border-indigo-100">
        <div className="flex items-center justify-between pb-3 mb-3 border-b border-slate-100">
          <div className="flex items-center gap-2">
            <CalendarIcon size={16} className="text-indigo-600" />
            <h3 className="font-bold text-slate-900 text-sm">
              Attendance for {new Date(selectedDateStr + 'T00:00:00').toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric', year: 'numeric' })}
            </h3>
          </div>
          {selectedHoliday && (
            <span className="px-2.5 py-0.5 bg-amber-100 text-amber-800 border border-amber-200 rounded-full text-xs font-semibold">
              🎉 {selectedHoliday.name}
            </span>
          )}
        </div>

        {selectedPunches.length === 0 ? (
          <div className="text-center py-6 text-slate-400 text-xs">
            {selectedHoliday ? (
              <p className="text-amber-700 font-medium">
                Official holiday declared: <strong>{selectedHoliday.name}</strong>
              </p>
            ) : (
              <p>No punches recorded on this selected day.</p>
            )}
          </div>
        ) : (
          <div className="space-y-3">
            {selectedPunches.map((punch) => (
              <div
                key={punch.id}
                className="p-3 rounded-xl border border-slate-200 bg-slate-50 flex items-center justify-between gap-3 text-xs"
              >
                <div
                  onClick={() => onViewPhoto && onViewPhoto(punch.selfiePath)}
                  className="w-10 h-10 rounded-lg bg-slate-200 overflow-hidden shrink-0 cursor-pointer border border-slate-300"
                >
                  <img src={punch.selfiePath} alt="Punch" className="w-full h-full object-cover" />
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <StatusPill status={punch.type} />
                    <span className="font-mono font-bold text-slate-900">{punch.deviceTime.slice(11, 19)}</span>
                  </div>
                  <div className="flex items-center gap-1 text-[11px] text-slate-500 mt-1">
                    <MapPin size={11} />
                    <span>{punch.latitude.toFixed(4)}°, {punch.longitude.toFixed(4)}° (±{punch.accuracy}m)</span>
                  </div>
                </div>
                <StatusPill status={punch.syncStatus} />
              </div>
            ))}
          </div>
        )}
      </CustomCard>

      {/* 4. Company Holidays in Month */}
      {monthHolidays.length > 0 && (
        <CustomCard>
          <div className="flex items-center gap-2 mb-3 pb-2 border-b border-slate-100">
            <PartyPopper size={16} className="text-amber-600" />
            <h3 className="font-bold text-slate-900 text-sm">
              Official Holidays in {monthName}
            </h3>
          </div>
          <div className="space-y-2">
            {monthHolidays.map((h) => (
              <div
                key={h.id}
                className="p-2.5 rounded-xl bg-amber-50/60 border border-amber-200/60 flex items-center justify-between text-xs"
              >
                <div>
                  <span className="font-bold text-slate-900">{h.name}</span>
                  {h.description && <p className="text-[11px] text-slate-500 mt-0.5">{h.description}</p>}
                </div>
                <span className="font-mono font-semibold text-amber-800 bg-amber-100 px-2 py-0.5 rounded">
                  {h.date} ({h.dayName})
                </span>
              </div>
            ))}
          </div>
        </CustomCard>
      )}
    </div>
  );
};

import React from 'react';
import { Clock, CheckCircle2 } from 'lucide-react';
import type { TodaySessionItem } from '../../types';

interface TodaySessionsCardProps {
  sessions: TodaySessionItem[];
  onSelectSessionChild?: (childId: string) => void;
}

export const TodaySessionsCard: React.FC<TodaySessionsCardProps> = ({
  sessions,
  onSelectSessionChild,
}) => {
  return (
    <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 shadow-xs">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-black text-[#432F62] flex items-center gap-2">
          <span>جلسات اليوم</span>
        </h3>
        <span className="text-xs font-bold text-[#8456D2] bg-[#F0E8FF] px-2.5 py-1 rounded-xl border border-[#E4D4FF]">
          {sessions.length} جلسات
        </span>
      </div>

      {/* List or Empty State */}
      {sessions.length === 0 ? (
        <div className="p-6 text-center text-xs font-bold text-[#74728A] bg-[#F7FAFC] rounded-2xl border border-[#E4D4FF]/70">
          لا توجد جلسات مكتملة مسجلة لهذا اليوم
        </div>
      ) : (
        <div className="space-y-3">
          {sessions.map((session) => (
            <div
              key={session.id}
              onClick={() => onSelectSessionChild?.(session.childId)}
              className="flex items-center justify-between p-3.5 rounded-2xl bg-[#F7FAFC] hover:bg-[#F0E8FF]/40 transition-colors border border-[#E4D4FF]/70 cursor-pointer"
            >
              {/* Right: Child name & domain */}
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-[#F0E8FF] text-[#8456D2] flex items-center justify-center shrink-0 border border-[#E4D4FF]">
                  <Clock className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="text-sm font-bold text-[#432F62]">{session.childName}</h4>
                  <div className="flex items-center gap-2 mt-0.5">
                    <span className="text-[11px] font-bold text-[#8456D2] bg-[#F0E8FF] px-2 py-0.5 rounded-md">
                      {session.domain}
                    </span>
                    <span className="text-[11px] text-[#74728A]">{session.timeLabel}</span>
                  </div>
                </div>
              </div>

              {/* Left: Status indicator */}
              <div className="flex items-center gap-1.5 text-xs font-bold text-[#6DAA60] bg-[#EEF3EE] px-2.5 py-1 rounded-xl border border-[#6DAA60]/30">
                <CheckCircle2 className="w-3.5 h-3.5" />
                <span>مكتملة</span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

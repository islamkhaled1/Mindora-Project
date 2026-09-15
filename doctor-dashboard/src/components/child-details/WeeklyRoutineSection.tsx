import React from 'react';
import { MessageSquare, Activity, Brain, Smile } from 'lucide-react';
import type { WeeklyRoutineTarget } from '../../types';
import { ProgressBar } from '../common/ProgressBar';

interface WeeklyRoutineSectionProps {
  targets: WeeklyRoutineTarget[];
}

export const WeeklyRoutineSection: React.FC<WeeklyRoutineSectionProps> = ({ targets }) => {
  const getIcon = (type: string) => {
    switch (type) {
      case 'speech':
        return <MessageSquare className="w-5 h-5 text-[#8456D2]" />;
      case 'motor':
        return <Activity className="w-5 h-5 text-[#FDB62C]" />;
      case 'cognitive':
        return <Brain className="w-5 h-5 text-[#6DAA60]" />;
      case 'social':
        return <Smile className="w-5 h-5 text-[#BD3737]" />;
      default:
        return <Activity className="w-5 h-5 text-[#8456D2]" />;
    }
  };

  return (
    <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 shadow-xs mb-6">
      {/* Section Header */}
      <div className="flex items-center justify-between mb-5">
        <div>
          <h3 className="text-lg font-black text-[#432F62]">الخطة الأسبوعية المقترحة</h3>
          <p className="text-xs text-[#74728A] font-semibold mt-0.5">
            خطة تدريب مقترحة أسبوعياً موزعة حسب المجالات النمائية (للقراءة فقط)
          </p>
        </div>
        <span className="text-xs font-bold text-[#8456D2] bg-[#F0E8FF] px-3 py-1 rounded-xl border border-[#E4D4FF]">
          عرض إرشادي
        </span>
      </div>

      {/* Routine Cards Grid (4 Columns on Desktop) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {targets.map((target) => (
          <div
            key={target.id}
            className="p-4 rounded-2xl border border-[#E4D4FF] bg-[#F7FAFC] flex flex-col justify-between"
          >
            {/* Top row: Icon + Sessions Count */}
            <div className="flex items-center justify-between mb-3">
              <div
                className="w-10 h-10 rounded-xl flex items-center justify-center border border-[#E4D4FF]"
                style={{ backgroundColor: target.bgColor }}
              >
                {getIcon(target.iconType)}
              </div>
              <span className="text-xs font-bold text-[#432F62] bg-[#F0E8FF] px-2.5 py-1 rounded-lg border border-[#E4D4FF]">
                {target.sessionsPerWeek} جلسات / أسبوع
              </span>
            </div>

            {/* Title & Description */}
            <div className="mb-4">
              <h4 className="text-sm font-bold text-[#432F62] mb-1">{target.title}</h4>
              <p className="text-xs text-[#74728A] font-medium leading-relaxed line-clamp-2">
                {target.description}
              </p>
            </div>

            {/* Mini Progress */}
            <div>
              <div className="flex justify-between items-center text-[11px] font-bold text-[#74728A] mb-1">
                <span>نسبة الإنجاز</span>
                <span className="text-[#432F62] font-black">{target.progressPercentage}%</span>
              </div>
              <ProgressBar percentage={target.progressPercentage} heightClass="h-1.5" />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

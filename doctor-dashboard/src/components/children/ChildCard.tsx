import React from 'react';
import { ChevronLeft } from 'lucide-react';
import type { AssignedChild } from '../../types';
import { ProgressBar } from '../common/ProgressBar';
import { StatusBadge } from '../common/StatusBadge';
import { formatGender, formatSupportLevel } from '../../utils/enumMappers';

interface ChildCardProps {
  child: AssignedChild;
  onSelect: (childId: string) => void;
}

export const ChildCard: React.FC<ChildCardProps> = ({ child, onSelect }) => {
  const genderLabel = formatGender(child.gender);
  const supportLevelLabel = formatSupportLevel(child.supportLevel);

  return (
    <div
      onClick={() => onSelect(child.id)}
      className="bg-white rounded-3xl border border-[#E4D4FF] p-5 shadow-xs hover:shadow-md transition-all duration-200 cursor-pointer flex flex-col justify-between group hover:border-[#8456D2]"
    >
      {/* Top Header: Avatar + Info + Status */}
      <div className="flex items-start justify-between gap-3 mb-4">
        {/* Child Avatar & Name */}
        <div className="flex items-center gap-3 min-w-0">
          {child.avatarUrl ? (
            <img
              src={child.avatarUrl}
              alt={child.fullName}
              className="w-11 h-11 rounded-full object-cover shrink-0 shadow-2xs group-hover:scale-105 transition-transform border border-[#E4D4FF]"
            />
          ) : (
            <div className="w-11 h-11 rounded-full bg-[#F0E8FF] text-[#8456D2] font-black text-base flex items-center justify-center shrink-0 shadow-2xs group-hover:scale-105 transition-transform border border-[#E4D4FF]">
              {child.avatarInitial}
            </div>
          )}
          <div className="min-w-0">
            <h4 className="text-base font-bold text-[#432F62] truncate group-hover:text-[#8456D2] transition-colors">
              {child.fullName}
            </h4>
            <p className="text-[11px] text-[#74728A] font-semibold truncate mt-0.5">
              {child.ageYears} سنوات • {genderLabel} • مستوى الدعم: {supportLevelLabel}
            </p>
          </div>
        </div>

        {/* Status Badge */}
        <div className="shrink-0">
          <StatusBadge status={child.recentTrend} variant="pill" />
        </div>
      </div>

      {/* Progress Section */}
      <div className="mb-4">
        <div className="flex items-center justify-between text-xs font-bold mb-1.5">
          <span className="text-[#74728A]">التقدم</span>
          <span className="text-[#432F62] font-black">{child.overallAverageScore}%</span>
        </div>
        <ProgressBar percentage={child.overallAverageScore} heightClass="h-2" />
      </div>

      {/* Card Footer: Last Session Date + Chevron Action */}
      <div className="flex items-center justify-between pt-3 border-t border-[#F0E8FF]">
        <span className="text-xs font-semibold text-[#74728A]">
          آخر جلسة: {child.lastSessionDate}
        </span>
        <button
          onClick={(e) => {
            e.stopPropagation();
            onSelect(child.id);
          }}
          className="w-8 h-8 rounded-xl bg-[#F0E8FF] group-hover:bg-[#E4D4FF] text-[#8456D2] flex items-center justify-center transition-colors cursor-pointer"
          title="عرض التفاصيل"
          aria-label={`عرض تفاصيل ${child.fullName}`}
        >
          <ChevronLeft className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};

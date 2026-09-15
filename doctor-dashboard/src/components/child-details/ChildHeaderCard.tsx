import React from 'react';
import { Calendar, Award } from 'lucide-react';
import type { AssignedChild } from '../../types';
import { StatusBadge } from '../common/StatusBadge';
import { CircularProgress } from '../common/CircularProgress';
import { formatGender, formatSupportLevel } from '../../utils/enumMappers';

interface ChildHeaderCardProps {
  child: AssignedChild;
}

export const ChildHeaderCard: React.FC<ChildHeaderCardProps> = ({ child }) => {
  const genderLabel = formatGender(child.gender);
  const supportLevelLabel = formatSupportLevel(child.supportLevel);

  return (
    <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 shadow-xs mb-6">
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
        {/* Right: Child Profile Information */}
        <div className="flex items-center gap-4">
          {child.avatarUrl ? (
            <img
              src={child.avatarUrl}
              alt={child.fullName}
              className="w-16 h-16 sm:w-20 sm:h-20 rounded-full object-cover shrink-0 shadow-xs border-2 border-[#E4D4FF]"
            />
          ) : (
            <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-full bg-[#F0E8FF] text-[#8456D2] font-black text-2xl sm:text-3xl flex items-center justify-center shrink-0 shadow-xs border-2 border-[#E4D4FF]">
              {child.avatarInitial}
            </div>
          )}
          <div>
            <div className="flex flex-wrap items-center gap-3">
              <h2 className="text-2xl font-black text-[#432F62]">{child.fullName}</h2>
              <StatusBadge status={child.recentTrend} variant="pill" />
            </div>
            {/* Approved UI Improvement: Gender + Support Level */}
            <p className="text-sm font-semibold text-[#74728A] mt-1">
              {child.ageYears} سنوات • {genderLabel} • مستوى الدعم: {supportLevelLabel}
            </p>
            {child.supportNotes && (
              <p className="text-xs text-[#74728A] mt-1">{child.supportNotes}</p>
            )}
          </div>
        </div>

        {/* Left: Last Session & Performance Circular Progress */}
        <div className="flex items-center gap-4 sm:gap-6 self-start lg:self-auto">
          {/* Last Session Mini-Card */}
          <div className="bg-[#F7FAFC] border border-[#E4D4FF] rounded-2xl px-4 py-3 text-right">
            <div className="flex items-center gap-1.5 text-xs text-[#74728A] font-bold mb-1">
              <Calendar className="w-3.5 h-3.5 text-[#8456D2]" />
              <span>آخر جلسة</span>
            </div>
            <p className="text-sm font-black text-[#432F62]">{child.lastSessionDate}</p>
            <p className="text-[11px] text-[#74728A] font-semibold mt-0.5">
              {child.totalCompletedSessions} جلسات مكتملة
            </p>
          </div>

          {/* Circular Score Widget */}
          <div className="flex items-center gap-3 bg-[#F7FAFC] border border-[#E4D4FF] rounded-2xl px-4 py-3">
            <div className="relative">
              <CircularProgress percentage={child.overallAverageScore} size={54} strokeWidth={5} />
              <span className="absolute inset-0 flex items-center justify-center text-xs font-black text-[#432F62]">
                {child.overallAverageScore}%
              </span>
            </div>
            <div>
              <div className="flex items-center gap-1 text-xs text-[#74728A] font-bold">
                <Award className="w-3.5 h-3.5 text-[#FDB62C]" />
                <span>متوسط الأداء</span>
              </div>
              <p className="text-xs font-black text-[#432F62] mt-0.5">
                {child.overallAverageScore >= 80
                  ? 'متميز'
                  : child.overallAverageScore >= 65
                  ? 'جيد'
                  : 'يحتاج دعم'}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

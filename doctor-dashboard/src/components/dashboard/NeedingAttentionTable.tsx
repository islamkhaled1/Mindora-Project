import React from 'react';
import { ChevronLeft, AlertCircle } from 'lucide-react';
import type { AssignedChild } from '../../types';
import { ProgressBar } from '../common/ProgressBar';
import { StatusBadge } from '../common/StatusBadge';

interface NeedingAttentionTableProps {
  childrenList: AssignedChild[];
  onSelectChild: (childId: string) => void;
  onViewAll?: () => void;
}

export const NeedingAttentionTable: React.FC<NeedingAttentionTableProps> = ({
  childrenList,
  onSelectChild,
  onViewAll,
}) => {
  return (
    <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 shadow-xs flex flex-col justify-between">
      {/* Table Header */}
      <div className="flex items-center justify-between mb-5">
        <div>
          <h3 className="text-lg font-black text-[#432F62] flex items-center gap-2">
            <span>أطفال بحاجة إلى انتباه</span>
          </h3>
          <p className="text-xs text-[#74728A] mt-0.5">
            أطفال بحاجة إلى مراجعة الخطة أو تحفيز الأداء
          </p>
        </div>

        {onViewAll && (
          <button
            onClick={onViewAll}
            className="text-xs font-bold text-[#8456D2] hover:text-[#432F62] flex items-center gap-1 hover:underline cursor-pointer transition-colors"
          >
            <span>عرض الكل</span>
            <ChevronLeft className="w-4 h-4" />
          </button>
        )}
      </div>

      {/* Table Content */}
      {childrenList.length === 0 ? (
        <div className="py-12 flex flex-col items-center justify-center text-center">
          <div className="w-12 h-12 rounded-full bg-[#EEF3EE] text-[#6DAA60] flex items-center justify-center mb-3">
            <AlertCircle className="w-6 h-6" />
          </div>
          <h4 className="text-sm font-bold text-[#432F62]">لا يوجد أطفال بحاجة إلى انتباه حالياً</h4>
          <p className="text-xs text-[#74728A] mt-1">جميع الأطفال يحققون تقدماً مستقراً وجيداً</p>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-right">
            <thead>
              <tr className="text-xs font-bold text-[#74728A] border-b border-[#F0E8FF] pb-2">
                <th className="py-2.5 px-2 font-bold">الطفل</th>
                <th className="py-2.5 px-3 font-bold min-w-[120px]">التقدم</th>
                <th className="py-2.5 px-3 font-bold">الحالة</th>
                <th className="py-2.5 px-2 font-bold text-left">التفاصيل</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#F0E8FF]/60">
              {childrenList.map((child) => (
                <tr
                  key={child.id}
                  onClick={() => onSelectChild(child.id)}
                  className="group hover:bg-[#F3EFFF]/50 transition-colors cursor-pointer"
                >
                  {/* Child Avatar & Name */}
                  <td className="py-3.5 px-2">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-full bg-[#F0E8FF] text-[#8456D2] font-black text-sm flex items-center justify-center shrink-0 shadow-2xs group-hover:scale-105 transition-transform border border-[#E4D4FF]">
                        {child.avatarInitial}
                      </div>
                      <div>
                        <h4 className="text-sm font-bold text-[#432F62] group-hover:text-[#8456D2] transition-colors">
                          {child.fullName}
                        </h4>
                        <span className="text-[11px] text-[#74728A]">
                          {child.ageYears} سنوات
                        </span>
                      </div>
                    </div>
                  </td>

                  {/* Progress Bar */}
                  <td className="py-3.5 px-3">
                    <div className="flex items-center gap-3">
                      <ProgressBar
                        percentage={child.overallAverageScore}
                        className="flex-1 min-w-[70px]"
                        heightClass="h-2"
                      />
                      <span className="text-xs font-black text-[#432F62] w-8 text-left">
                        {child.overallAverageScore}%
                      </span>
                    </div>
                  </td>

                  {/* Status Badge */}
                  <td className="py-3.5 px-3">
                    <StatusBadge status={child.recentTrend} variant="text" />
                  </td>

                  {/* Action Chevron */}
                  <td className="py-3.5 px-2 text-left">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        onSelectChild(child.id);
                      }}
                      className="w-8 h-8 rounded-xl bg-[#F0E8FF] group-hover:bg-[#E4D4FF] text-[#8456D2] flex items-center justify-center transition-colors cursor-pointer"
                      title="عرض تفاصيل الطفل"
                      aria-label={`عرض تفاصيل ${child.fullName}`}
                    >
                      <ChevronLeft className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

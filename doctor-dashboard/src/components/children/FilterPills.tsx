import React from 'react';
import type { PerformanceTrend } from '../../types';

export type FilterStatus = 'all' | PerformanceTrend;

interface FilterPillsProps {
  currentFilter: FilterStatus;
  onFilterChange: (filter: FilterStatus) => void;
  counts: {
    all: number;
    needsSupport: number;
    improving: number;
    steady: number;
  };
}

export const FilterPills: React.FC<FilterPillsProps> = ({
  currentFilter,
  onFilterChange,
  counts,
}) => {
  const filterOptions: { key: FilterStatus; label: string; count: number }[] = [
    { key: 'all', label: 'إجمالي الأطفال', count: counts.all },
    { key: 'NeedsSupport', label: 'يحتاج دعم', count: counts.needsSupport },
    { key: 'Improving', label: 'في تحسن', count: counts.improving },
    { key: 'Steady', label: 'مستقر', count: counts.steady },
  ];

  return (
    <div className="flex flex-wrap items-center gap-2.5 mb-6">
      {filterOptions.map((opt) => {
        const isActive = currentFilter === opt.key;
        return (
          <button
            key={opt.key}
            onClick={() => onFilterChange(opt.key)}
            className={`px-4 py-2 rounded-2xl text-xs font-bold transition-all duration-200 cursor-pointer flex items-center gap-2 ${
              isActive
                ? 'bg-[#F0E8FF] text-[#432F62] border border-[#E4D4FF] shadow-xs'
                : 'bg-white text-[#74728A] border border-[#E4D4FF]/80 hover:bg-[#F3EFFF] hover:text-[#432F62]'
            }`}
          >
            <span>{opt.label}</span>
            <span
              className={`px-2 py-0.5 rounded-full text-[11px] font-black ${
                isActive
                  ? 'bg-white text-[#8456D2] shadow-2xs'
                  : 'bg-[#F0E8FF] text-[#74728A]'
              }`}
            >
              {opt.count}
            </span>
          </button>
        );
      })}
    </div>
  );
};

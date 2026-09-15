import React from 'react';
import type { PerformanceTrend } from '../../types';

interface StatusBadgeProps {
  status: PerformanceTrend | string;
  variant?: 'pill' | 'text';
  className?: string;
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({
  status,
  variant = 'text',
  className = '',
}) => {
  let label = 'مستقر';
  let colorClasses = 'text-[#432F62] font-bold';
  let pillClasses = 'bg-[#F0E8FF] text-[#432F62] border border-[#E4D4FF] font-bold';

  if (
    status === 'NeedsSupport' ||
    status === 'يحتاج دعم' ||
    status === 'يحتاج مراجعة' ||
    status === 'يحتاج اهتمام'
  ) {
    label = 'يحتاج دعم';
    colorClasses = 'text-[#BD3737] font-bold';
    pillClasses = 'bg-[#FFD4CA] text-[#BD3737] border border-[#BD3737]/30 font-bold';
  } else if (status === 'Improving' || status === 'في تحسن') {
    label = 'في تحسن';
    colorClasses = 'text-[#6DAA60] font-bold';
    pillClasses = 'bg-[#EEF3EE] text-[#6DAA60] border border-[#6DAA60]/30 font-bold';
  } else if (status === 'Steady' || status === 'مستقر') {
    label = 'مستقر';
    colorClasses = 'text-[#432F62] font-bold';
    pillClasses = 'bg-[#F0E8FF] text-[#432F62] border border-[#E4D4FF] font-bold';
  }

  if (variant === 'pill') {
    return (
      <span
        className={`inline-flex items-center justify-center px-3.5 py-1 rounded-xl text-xs transition-colors ${pillClasses} ${className}`}
      >
        {label}
      </span>
    );
  }

  return <span className={`text-xs ${colorClasses} ${className}`}>{label}</span>;
};

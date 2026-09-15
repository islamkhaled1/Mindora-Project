import React from 'react';
import { ChevronLeft } from 'lucide-react';

interface StatCardProps {
  title: string;
  count: number | string;
  icon: React.ReactNode;
  onClick?: () => void;
  className?: string;
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  count,
  icon,
  onClick,
  className = '',
}) => {
  return (
    <div
      onClick={onClick}
      className={`bg-white rounded-3xl p-5 border border-[#E4D4FF] shadow-xs hover:shadow-md hover:border-[#8456D2] transition-all duration-200 flex flex-col justify-between cursor-pointer ${className}`}
    >
      {/* Top Header: Icon in rounded border container */}
      <div className="flex items-center justify-center w-full mb-3">
        <div className="w-11 h-11 rounded-2xl border border-[#E4D4FF] bg-[#F0E8FF] flex items-center justify-center text-[#8456D2] shadow-2xs">
          {icon}
        </div>
      </div>

      {/* Middle: Title */}
      <div className="text-center mb-2">
        <h4 className="text-sm font-bold text-[#74728A]">{title}</h4>
      </div>

      {/* Bottom: Big Number + Chevron Pill */}
      <div className="flex items-center justify-between mt-auto pt-2">
        <button
          className="w-7 h-7 rounded-xl bg-[#F0E8FF] hover:bg-[#E4D4FF] text-[#8456D2] flex items-center justify-center transition-colors cursor-pointer"
          title="عرض المزيد"
          aria-label="عرض المزيد"
        >
          <ChevronLeft className="w-4 h-4" />
        </button>
        <span className="text-2xl font-black text-[#432F62] tracking-tight">{count}</span>
      </div>
    </div>
  );
};

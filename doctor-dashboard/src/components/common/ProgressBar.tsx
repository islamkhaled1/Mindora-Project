import React from 'react';

interface ProgressBarProps {
  percentage: number;
  className?: string;
  heightClass?: string;
  trackColor?: string;
  fillColor?: string;
}

export const ProgressBar: React.FC<ProgressBarProps> = ({
  percentage,
  className = '',
  heightClass = 'h-2.5',
  trackColor = 'bg-[#E4D4FF]',
  fillColor = 'bg-[#432F62]', // Deep purple matching Sawa palette
}) => {
  const clamped = Math.min(100, Math.max(0, percentage));

  return (
    <div
      className={`w-full ${trackColor} rounded-full overflow-hidden ${heightClass} ${className}`}
      role="progressbar"
      aria-valuenow={clamped}
      aria-valuemin={0}
      aria-valuemax={100}
    >
      <div
        className={`${fillColor} ${heightClass} rounded-full transition-all duration-500 ease-out`}
        style={{ width: `${clamped}%` }}
      />
    </div>
  );
};

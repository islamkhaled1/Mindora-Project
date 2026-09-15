import React from 'react';

export interface LoadingStateProps {
  message?: string;
  variant?: 'card' | 'table' | 'full' | 'grid' | 'statCards';
  count?: number;
  className?: string;
}

export const LoadingState: React.FC<LoadingStateProps> = ({
  message = 'جاري تحميل البيانات...',
  variant = 'card',
  count = 3,
  className = '',
}) => {
  if (variant === 'full') {
    return (
      <div className={`flex flex-col items-center justify-center p-12 bg-white rounded-3xl border border-[#ede9fe] shadow-xs ${className}`}>
        <div className="w-12 h-12 border-4 border-[#ede9fe] border-t-[#4f46e5] rounded-full animate-spin mb-4" />
        <p className="text-slate-500 font-medium text-sm">{message}</p>
      </div>
    );
  }

  if (variant === 'statCards') {
    return (
      <div className={`grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 ${className}`}>
        {Array.from({ length: count }).map((_, i) => (
          <div key={i} className="bg-white rounded-2xl p-5 border border-[#ede9fe] shadow-xs animate-pulse">
            <div className="w-10 h-10 rounded-xl bg-slate-100 mx-auto mb-3" />
            <div className="h-4 bg-slate-100 rounded w-1/2 mx-auto mb-3" />
            <div className="flex justify-between items-center pt-2">
              <div className="w-7 h-7 bg-slate-100 rounded-lg" />
              <div className="h-6 bg-slate-200 rounded w-12" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (variant === 'grid') {
    return (
      <div className={`grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 ${className}`}>
        {Array.from({ length: count }).map((_, i) => (
          <div key={i} className="bg-white rounded-3xl p-5 border border-[#ede9fe] shadow-xs animate-pulse space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-full bg-slate-200 shrink-0" />
              <div className="space-y-2 flex-1">
                <div className="h-4 bg-slate-200 rounded w-2/3" />
                <div className="h-3 bg-slate-100 rounded w-1/2" />
              </div>
            </div>
            <div className="space-y-2">
              <div className="h-3 bg-slate-100 rounded w-1/4" />
              <div className="h-2 bg-slate-100 rounded w-full" />
            </div>
            <div className="flex justify-between items-center pt-2">
              <div className="h-3 bg-slate-100 rounded w-1/3" />
              <div className="w-7 h-7 bg-slate-100 rounded-lg" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (variant === 'table') {
    return (
      <div className={`w-full bg-white rounded-3xl p-6 border border-[#ede9fe] space-y-4 animate-pulse ${className}`}>
        <div className="h-8 bg-slate-100 rounded-xl w-1/3" />
        <div className="h-12 bg-slate-50 rounded-xl w-full" />
        <div className="h-12 bg-slate-50 rounded-xl w-full" />
        <div className="h-12 bg-slate-50 rounded-xl w-full" />
      </div>
    );
  }

  return (
    <div className={`bg-white rounded-3xl p-6 border border-[#ede9fe] shadow-xs animate-pulse ${className}`}>
      <div className="h-6 bg-slate-100 rounded-lg w-1/3 mb-4" />
      <div className="h-10 bg-slate-50 rounded-lg w-2/3 mb-3" />
      <div className="h-4 bg-slate-100 rounded-lg w-1/2" />
    </div>
  );
};

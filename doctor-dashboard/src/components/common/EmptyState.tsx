import React from 'react';
import { Inbox } from 'lucide-react';

interface EmptyStateProps {
  title?: string;
  description?: string;
  actionText?: string;
  onAction?: () => void;
  className?: string;
  icon?: React.ReactNode;
}

export const EmptyState: React.FC<EmptyStateProps> = ({
  title = 'لا توجد بيانات متاحة',
  description = 'لم يتم العثور على أي عناصر مسجلة في هذا القسم حالياً.',
  actionText,
  onAction,
  className = '',
  icon,
}) => {
  return (
    <div
      className={`flex flex-col items-center justify-center p-10 bg-white rounded-2xl border border-[#ede9fe] shadow-sm text-center ${className}`}
    >
      <div className="w-14 h-14 bg-[#f5f3ff] text-[#6366f1] rounded-2xl flex items-center justify-center mb-4">
        {icon || <Inbox className="w-7 h-7" />}
      </div>
      <h3 className="text-lg font-bold text-[#1e1b4b] mb-1">{title}</h3>
      <p className="text-sm text-slate-500 max-w-sm mb-4 leading-relaxed">{description}</p>
      {actionText && onAction && (
        <button
          onClick={onAction}
          className="inline-flex items-center justify-center px-5 py-2 bg-[#6366f1] hover:bg-[#4f46e5] text-white text-sm font-semibold rounded-xl shadow-sm transition-all"
        >
          {actionText}
        </button>
      )}
    </div>
  );
};

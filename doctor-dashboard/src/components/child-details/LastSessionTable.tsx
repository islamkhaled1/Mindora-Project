import React from 'react';
import type { LastSessionTaskItem } from '../../types';
import { ProgressBar } from '../common/ProgressBar';
import { StatusBadge } from '../common/StatusBadge';

interface LastSessionTableProps {
  tasks: LastSessionTaskItem[];
}

export const LastSessionTable: React.FC<LastSessionTableProps> = ({ tasks }) => {
  return (
    <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 shadow-xs mb-6">
      {/* Header */}
      <div className="mb-4">
        <h3 className="text-lg font-black text-[#432F62]">تفاصيل آخر جلسة</h3>
        <p className="text-xs text-[#74728A] font-semibold mt-0.5">
          نتائج الأنشطة المنجزة في الجلسة الأخيرة
        </p>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full text-right">
          <thead>
            <tr className="text-xs font-bold text-[#74728A] border-b border-[#F0E8FF]">
              <th className="py-2.5 px-3 font-bold">المجال</th>
              <th className="py-2.5 px-3 font-bold">النشاط</th>
              <th className="py-2.5 px-3 font-bold min-w-[140px]">الدرجة</th>
              <th className="py-2.5 px-3 font-bold">الحالة</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#F0E8FF]/70">
            {tasks.length === 0 ? (
              <tr>
                <td colSpan={4} className="py-6 text-center text-xs text-[#74728A] font-semibold">
                  لا توجد نتائج جلسات مسجلة بعد لهذا الطفل
                </td>
              </tr>
            ) : (
              tasks.map((task) => (
                <tr key={task.id} className="hover:bg-[#F3EFFF]/40 transition-colors">
                  <td className="py-3 px-3 text-sm font-bold text-[#432F62]">{task.domain}</td>
                  <td className="py-3 px-3 text-sm text-[#74728A] font-semibold">{task.activityTitle}</td>
                  <td className="py-3 px-3">
                    <div className="flex items-center gap-3">
                      <ProgressBar percentage={task.score} heightClass="h-2" className="flex-1" />
                      <span className="text-xs font-black text-[#432F62] w-8 text-left">
                        {task.score}%
                      </span>
                    </div>
                  </td>
                  <td className="py-3 px-3">
                    <StatusBadge status={task.status} variant="text" />
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

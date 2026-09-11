import React from 'react';
import { ActiveChild } from '../types';

interface ActiveChildrenTableProps {
  childrenList: ActiveChild[];
  onSelectChild?: (child: ActiveChild) => void;
}

export default function ActiveChildrenTable({
  childrenList,
  onSelectChild,
}: ActiveChildrenTableProps) {
  return (
    <div id="active-children-card" className="active-children-card">
      {/* عنوان الكارت */}
      <p className="active-children-title">أطفال نشطون</p>

      {/* حاوية الجدول */}
      <div className="active-table-container">
        <table className="active-table">
          <thead className="active-table-thead">
            <tr>
              <th className="active-table-th">الطفل</th>
              <th className="active-table-th">المجال</th>
              <th className="active-table-th">الهدف</th>
              <th className="active-table-th">النسبة</th>
              <th className="active-table-th">الحالة</th>
            </tr>
          </thead>
          <tbody className="active-table-tbody">
            {childrenList.map((child) => (
              <tr
                key={child.id}
                id={`active-child-row-${child.id}`}
                onClick={() => onSelectChild && onSelectChild(child)}
                className="active-table-row"
              >
                <td className="active-table-td font-bold">{child.name}</td>
                <td className="active-table-td text-muted">{child.field}</td>
                <td className="active-table-td">{child.goal}</td>
                <td className="active-table-td font-bold">{child.percentage}%</td>
                <td className="active-table-td">{child.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

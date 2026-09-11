import React from 'react';

interface StatusDistributionItem {
  label: string;
  count: number;
  color: string;
}

interface StatusDistributionChartProps {
  items?: StatusDistributionItem[];
  totalPercentage?: number;
}

export default function StatusDistributionChart({
  items = [
    { label: 'مستقر', count: 6, color: '#56B280' },
    { label: 'في تحسن', count: 4, color: '#4F92F7' },
    { label: 'يحتاج دعم', count: 5, color: '#D8CEF9' },
  ],
  totalPercentage = 72,
}: StatusDistributionChartProps) {
  // أبعاد الرسم الدائري
  const size = 190;
  const strokeWidth = 15;

  return (
    <div id="distribution-card" className="distribution-card " dir="rtl">

      {/* تفاصيل الحالات والأسماء (يمين الكارت) */}
      <div className="distribution-details">
        <div><p  className="font-extrabold text-[17px] pb-1 mt-4">توزيع حالات الأطفال</p></div>

        <div className="distribution-items-list">
          {items.map((item, index) => (
            <div key={index} className="distribution-item-row">
              {/* الرقم في أقصى اليمين */}
              <span className="distribution-count">{item.count}</span>

              {/* النقطة الدائرية الملونة في المنتصف */}
              <span
                className="color-dot"
                style={{ backgroundColor: item.color }}
                aria-hidden="true"
              />

              {/* اسم الحالة إلى يسار النقطة */}
              <span className="distribution-label">{item.label}</span>
            </div>
          ))}
        </div>
      </div>

      
      {/* الرسم الدائري Donut مع 72% في المنتصف (يسار الكارت) */}
      <div className="donut-chart-container">
   <svg
  width={size}
  height={size}
  viewBox="0 0 150 150"
  className="donut-chart-svg"
>
  {/* 1. القوس البنفسجي الفاتح (Lilac) في الجزء الأيسر */}
  <path
    d="M 31.66 108.86 A 55 55 0 0 1 34.13 38.20"
    fill="none"
    stroke="#D8CEF9"
    strokeWidth={10.5}
    strokeLinecap="round"
  />

  {/* 2. القوس الأخضر (Green) - تم تكبيره ليمتد على النصف العلوي والأيمن */}
  <path
    d="M 34.13 38.20 A 55 55 0 0 1 118.34 108.86"
    fill="none"
    stroke="#56B280"
    strokeWidth={10.5}
    strokeLinecap="round"
  />

  {/* 3. القوس الأزرق (Blue) - تم تقليصه ليكون أصغر حجماً في الأسفل */}
  <path
    d="M 118.34 108.86 A 55 55 0 0 1 31.66 108.86"
    fill="none"
    stroke="#4F92F7"
    strokeWidth={10.5}
    strokeLinecap="round"
  />

          {/* النسبة المركزية 72% في منتصف الدائرة تماماً */}
          <text
            x="75"
            y="70"
            textAnchor="middle"
            dominantBaseline="central"
            className="donut-center-percentage"
          >
            {totalPercentage}%
          </text>
        </svg>
      </div>


    </div>
  );
}

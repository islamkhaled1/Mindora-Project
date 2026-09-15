import React, { useState } from 'react';
import type { WeeklyTrendPoint } from '../../types';

interface ChartPoint extends WeeklyTrendPoint {
  x: number;
  y: number;
  clampedScore: number;
}

interface TrendChartProps {
  data: WeeklyTrendPoint[];
}

export const TrendChart: React.FC<TrendChartProps> = ({ data }) => {
  const [hoveredPoint, setHoveredPoint] = useState<ChartPoint | null>(null);

  if (!data || data.length === 0) {
    return (
      <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 shadow-xs relative flex flex-col justify-between">
        <div className="flex items-center justify-between mb-2">
          <h3 className="text-lg font-black text-[#432F62]">التقدم العام</h3>
          <span className="text-xs text-[#74728A] font-bold">آخر 6 أسابيع</span>
        </div>
        <div className="py-12 text-center text-[#74728A] text-xs font-semibold">
          لا توجد بيانات تقدم مسجلة حتى الآن
        </div>
      </div>
    );
  }

  // Chart coordinate space in SVG viewBox
  const width = 520;
  const height = 195;
  const paddingX = 48;
  const paddingTop = 32;
  const paddingBottom = 42;
  const plotHeight = height - paddingTop - paddingBottom; // 121

  // Strictly bounded 0% to 100% scale
  const minScore = 0;
  const maxScore = 100;

  // RTL Timeline: Oldest (index 0 / أسبوع 1) starts at RIGHT (width - paddingX)
  // Newest (index N-1 / أسبوع 6) ends at LEFT (paddingX)
  const points: ChartPoint[] = data.map((item, index) => {
    const x =
      data.length === 1
        ? width / 2
        : (width - paddingX) - (index * (width - paddingX * 2)) / (data.length - 1);

    const clampedScore = Math.max(minScore, Math.min(maxScore, item.averageScore || 0));
    const y = paddingTop + ((maxScore - clampedScore) / (maxScore - minScore)) * plotHeight;

    return {
      ...item,
      x,
      y,
      clampedScore,
    };
  });

  // Sort points by X ascending (left-to-right) for SVG cubic bezier drawing
  const sortedPoints = [...points].sort((a, b) => a.x - b.x);

  // Generate smooth SVG cubic Bézier path
  const generateSmoothPath = (pts: { x: number; y: number }[]): string => {
    if (pts.length < 2) return '';
    let d = `M ${pts[0].x} ${pts[0].y}`;

    for (let i = 0; i < pts.length - 1; i++) {
      const p0 = pts[i === 0 ? i : i - 1];
      const p1 = pts[i];
      const p2 = pts[i + 1];
      const p3 = pts[i + 2 < pts.length ? i + 2 : i + 1];

      const cp1x = p1.x + (p2.x - p0.x) / 6;
      const cp1y = p1.y + (p2.y - p0.y) / 6;

      const cp2x = p2.x - (p3.x - p1.x) / 6;
      const cp2y = p2.y - (p3.y - p1.y) / 6;

      d += ` C ${cp1x} ${cp1y}, ${cp2x} ${cp2y}, ${p2.x} ${p2.y}`;
    }

    return d;
  };

  const linePath = generateSmoothPath(sortedPoints);
  const baselineY = height - paddingBottom;

  // Area path closed cleanly down to baseline
  const areaPath =
    sortedPoints.length > 1 && linePath
      ? `${linePath} L ${sortedPoints[sortedPoints.length - 1].x} ${baselineY} L ${sortedPoints[0].x} ${baselineY} Z`
      : '';

  const y100 = paddingTop;
  const y50 = paddingTop + plotHeight / 2;
  const y0 = baselineY;

  return (
    <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 shadow-xs relative select-none">
      {/* Header */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <h3 className="text-lg font-black text-[#432F62]">التقدم العام</h3>
          <span className="text-[11px] font-bold text-[#8456D2] bg-[#F0E8FF] px-2.5 py-0.5 rounded-md border border-[#E4D4FF]">
            متوسط الأداء الأسبوعي
          </span>
        </div>
        <div className="flex items-center gap-1 text-xs text-[#74728A] font-bold">
          <span>آخر 6 أسابيع</span>
          <span className="text-[10px] text-[#8456D2] bg-[#F7FAFC] px-2 py-0.5 rounded-md border border-[#E4D4FF]">
            (من اليمين لليسار)
          </span>
        </div>
      </div>

      {/* SVG Chart Area */}
      <div className="w-full relative">
        <svg
          viewBox={`0 0 ${width} ${height}`}
          className="w-full h-auto overflow-visible"
          preserveAspectRatio="xMidYMid meet"
        >
          <defs>
            {/* Area Fill Gradient */}
            <linearGradient id="purpleTrendGradient" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#8456D2" stopOpacity="0.28" />
              <stop offset="100%" stopColor="#8456D2" stopOpacity="0.01" />
            </linearGradient>

            {/* Subtle Glow Filter */}
            <filter id="purpleLineGlow" x="-10%" y="-10%" width="120%" height="120%">
              <feDropShadow dx="0" dy="2" stdDeviation="2.5" floodColor="#8456D2" floodOpacity="0.3" />
            </filter>
          </defs>

          {/* Horizontal Grid Guidelines (100%, 50%, 0%) */}
          <g className="opacity-80">
            {/* 100% Line */}
            <line
              x1={paddingX - 10}
              y1={y100}
              x2={width - paddingX + 10}
              y2={y100}
              stroke="#E4D4FF"
              strokeDasharray="3 3"
              strokeWidth="1"
            />
            <text
              x={width - 4}
              y={y100 + 3}
              textAnchor="end"
              className="text-[9px] font-bold fill-[#74728A]"
            >
              100%
            </text>

            {/* 50% Line */}
            <line
              x1={paddingX - 10}
              y1={y50}
              x2={width - paddingX + 10}
              y2={y50}
              stroke="#F0E8FF"
              strokeDasharray="3 3"
              strokeWidth="1"
            />
            <text
              x={width - 4}
              y={y50 + 3}
              textAnchor="end"
              className="text-[9px] font-bold fill-[#74728A]"
            >
              50%
            </text>

            {/* 0% Baseline */}
            <line
              x1={paddingX - 10}
              y1={y0}
              x2={width - paddingX + 10}
              y2={y0}
              stroke="#E4D4FF"
              strokeWidth="1.2"
            />
            <text
              x={width - 4}
              y={y0 + 3}
              textAnchor="end"
              className="text-[9px] font-bold fill-[#74728A]"
            >
              0%
            </text>
          </g>

          {/* Area Fill */}
          {areaPath && <path d={areaPath} fill="url(#purpleTrendGradient)" />}

          {/* Line Curve */}
          {linePath && (
            <path
              d={linePath}
              fill="none"
              stroke="#8456D2"
              strokeWidth="3.5"
              strokeLinecap="round"
              filter="url(#purpleLineGlow)"
            />
          )}

          {/* Data Points and In-SVG Synchronized Labels */}
          {points.map((pt, idx) => {
            const isHovered = hoveredPoint?.weekNumber === pt.weekNumber;
            const hasData = pt.clampedScore > 0;
            const isCurrentWeek = idx === points.length - 1;

            return (
              <g key={pt.weekNumber ?? idx}>
                {/* Vertical helper highlight line on hover */}
                {isHovered && (
                  <line
                    x1={pt.x}
                    y1={paddingTop}
                    x2={pt.x}
                    y2={baselineY}
                    stroke="#8456D2"
                    strokeDasharray="2 2"
                    strokeWidth="1"
                    className="opacity-70"
                  />
                )}

                {/* Outer halo circle */}
                <circle
                  cx={pt.x}
                  cy={pt.y}
                  r={isHovered ? 8 : 6}
                  fill={hasData ? '#8456D2' : '#FFFFFF'}
                  fillOpacity={isHovered ? 0.3 : 0.15}
                  className="transition-all duration-200 pointer-events-none"
                />

                {/* Core interactive point */}
                <circle
                  cx={pt.x}
                  cy={pt.y}
                  r={isHovered ? 5.5 : 4}
                  fill={hasData ? '#8456D2' : '#FFFFFF'}
                  stroke={hasData ? '#FFFFFF' : '#74728A'}
                  strokeWidth="2.5"
                  className="transition-all duration-200 cursor-pointer"
                  onMouseEnter={() => setHoveredPoint(pt)}
                  onMouseLeave={() => setHoveredPoint(null)}
                />

                {/* X-Axis Label rendered at EXACT pt.x coordinate */}
                <text
                  x={pt.x}
                  y={height - 12}
                  textAnchor="middle"
                  className={`text-[11px] select-none transition-colors ${
                    isHovered
                      ? 'font-black fill-[#432F62]'
                      : isCurrentWeek
                      ? 'font-bold fill-[#8456D2]'
                      : 'font-semibold fill-[#74728A]'
                  }`}
                >
                  {pt.weekLabel}
                  {isCurrentWeek ? ' (الحالي)' : ''}
                </text>
              </g>
            );
          })}
        </svg>

        {/* Floating Tooltip positioned relative to hovered point */}
        {hoveredPoint && (
          <div
            className="absolute -top-3 transform -translate-x-1/2 bg-[#432F62] text-white text-[11px] font-bold px-3 py-1.5 rounded-xl shadow-lg pointer-events-none transition-all duration-150 z-20 flex items-center gap-1.5 border border-[#8456D2]/30"
            style={{
              left: `${(hoveredPoint.x / width) * 100}%`,
            }}
          >
            <span>{hoveredPoint.weekLabel}:</span>
            {hoveredPoint.clampedScore > 0 ? (
              <span className="text-[#FDB62C] font-black">{hoveredPoint.clampedScore}%</span>
            ) : (
              <span className="text-[#F0E8FF]/80 font-normal">لا توجد جلسات</span>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

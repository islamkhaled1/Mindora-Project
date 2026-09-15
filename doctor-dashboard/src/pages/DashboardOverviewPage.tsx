import React, { useEffect, useState, useCallback } from 'react';
import { Users, UserCheck, Calendar, Award } from 'lucide-react';
import type { DashboardKpis, TodaySessionItem, WeeklyTrendPoint, AssignedChild } from '../types';
import { dashboardService } from '../services/dashboardService';
import { StatCard } from '../components/common/StatCard';
import { NeedingAttentionTable } from '../components/dashboard/NeedingAttentionTable';
import { TodaySessionsCard } from '../components/dashboard/TodaySessionsCard';
import { TrendChart } from '../components/dashboard/TrendChart';
import { LoadingState } from '../components/common/LoadingState';
import { ErrorState } from '../components/common/ErrorState';

interface DashboardOverviewPageProps {
  onSelectChild: (childId: string) => void;
  onNavigateToChildren: () => void;
  onReferralCodeLoaded?: (code: string) => void;
}

export const DashboardOverviewPage: React.FC<DashboardOverviewPageProps> = ({
  onSelectChild,
  onNavigateToChildren,
  onReferralCodeLoaded,
}) => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [kpis, setKpis] = useState<DashboardKpis | null>(null);
  const [todaySessions, setTodaySessions] = useState<TodaySessionItem[]>([]);
  const [weeklyTrends, setWeeklyTrends] = useState<WeeklyTrendPoint[]>([]);
  const [needingAttentionChildren, setNeedingAttentionChildren] = useState<AssignedChild[]>([]);
  const [fetchIndex, setFetchIndex] = useState(0);

  const handleRetry = useCallback(() => {
    setLoading(true);
    setError(null);
    setFetchIndex((i) => i + 1);
  }, []);

  useEffect(() => {
    let isMounted = true;

    dashboardService
      .getDashboardOverview()
      .then((data) => {
        if (!isMounted) return;
        setKpis(data.kpis);
        setTodaySessions(data.todaySessions);
        setWeeklyTrends(data.weeklyTrends);
        setNeedingAttentionChildren(data.needingAttentionChildren);
        if (data.referralCode && onReferralCodeLoaded) {
          onReferralCodeLoaded(data.referralCode);
        }
        setError(null);
        setLoading(false);
      })
      .catch((err) => {
        if (!isMounted) return;
        const msg =
          err instanceof Error ? err.message : 'تعذر تحميل بيانات لوحة التحكم، يرجى المحاولة مرة أخرى.';
        setError(msg);
        console.error('Error loading dashboard overview:', err);
        setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [fetchIndex, onReferralCodeLoaded]);

  if (loading) {
    return (
      <div className="space-y-6">
        <LoadingState variant="statCards" count={4} />
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          <div className="lg:col-span-7">
            <LoadingState variant="table" />
          </div>
          <div className="lg:col-span-5 space-y-6">
            <LoadingState variant="card" />
            <LoadingState variant="card" />
          </div>
        </div>
      </div>
    );
  }

  if (error || !kpis) {
    return <ErrorState message={error || 'حدث خطأ غير متوقع'} onRetry={handleRetry} />;
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* 4 KPI Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="إجمالي الأطفال"
          count={kpis.totalAssignedChildren}
          icon={<Users className="w-5 h-5 text-[#4f46e5]" />}
          onClick={onNavigateToChildren}
        />
        <StatCard
          title="أطفال نشطون"
          count={kpis.activeChildrenCount}
          icon={<UserCheck className="w-5 h-5 text-[#4f46e5]" />}
          onClick={onNavigateToChildren}
        />
        <StatCard
          title="جلسات هذا الأسبوع"
          count={kpis.weeklyCompletedSessions}
          icon={<Calendar className="w-5 h-5 text-[#4f46e5]" />}
        />
        <StatCard
          title="متوسط الدرجة"
          count={`${kpis.averageMovementScore}%`}
          icon={<Award className="w-5 h-5 text-[#4f46e5]" />}
        />
      </div>

      {/* Main Two-Column Section Matching Screenshot */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Right Side in RTL: Table of Children Needing Attention (~60% width) */}
        <div className="lg:col-span-7 space-y-6">
          <NeedingAttentionTable
            childrenList={needingAttentionChildren}
            onSelectChild={onSelectChild}
            onViewAll={onNavigateToChildren}
          />
        </div>

        {/* Left Side in RTL: Today's Sessions + Weekly Trend Chart (~40% width) */}
        <div className="lg:col-span-5 space-y-6">
          <TodaySessionsCard
            sessions={todaySessions}
            onSelectSessionChild={onSelectChild}
          />
          <TrendChart data={weeklyTrends} />
        </div>
      </div>
    </div>
  );
};

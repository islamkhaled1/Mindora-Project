import { doctorApi } from '../api/doctorApi';
import type { DoctorDashboardDto, DoctorNeedsSupportAlertDto, DoctorRecentSessionDto } from '../api/types';
import type { DashboardKpis, TodaySessionItem, WeeklyTrendPoint, AssignedChild, PerformanceTrend } from '../types';
import { formatDomain } from '../utils/enumMappers';

export interface DashboardViewData {
  kpis: DashboardKpis;
  todaySessions: TodaySessionItem[];
  weeklyTrends: WeeklyTrendPoint[];
  needingAttentionChildren: AssignedChild[];
  referralCode: string;
}

const formatSessionTime = (dateString?: string): string => {
  if (!dateString) return 'اليوم';
  try {
    const date = new Date(dateString);
    return date.toLocaleTimeString('ar-EG', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: true,
    });
  } catch {
    return 'اليوم';
  }
};

const mapAlertToAssignedChild = (alert: DoctorNeedsSupportAlertDto): AssignedChild => {
  const lastSessionText = alert.lastSessionDateUtc
    ? new Date(alert.lastSessionDateUtc).toLocaleDateString('ar-EG', {
        month: 'short',
        day: 'numeric',
      })
    : alert.daysSinceLastSession < 365
    ? `منذ ${alert.daysSinceLastSession} يوم`
    : 'لم تبدأ بعد';

  return {
    id: alert.childId,
    fullName: alert.fullName,
    avatarInitial: alert.fullName.trim().charAt(0) || 'ط',
    dateOfBirth: '',
    ageYears: alert.ageYears,
    gender: 'NotSpecified',
    supportLevel: 'NotSpecified',
    currentMovementLevel: alert.currentMovementLevel || 'Beginner',
    totalCompletedSessions: 0,
    totalPracticeMinutes: 0,
    overallAverageScore: Math.round(alert.overallAverageScore),
    recentTrend: (alert.recentTrend as PerformanceTrend) || 'NeedsSupport',
    lastSessionDate: lastSessionText,
    lastSessionDateUtc: alert.lastSessionDateUtc || undefined,
  };
};

const mapRecentSessionToTodayItem = (session: DoctorRecentSessionDto): TodaySessionItem => {
  return {
    id: session.sessionId,
    childId: session.childId,
    childName: session.childFullName,
    domain: formatDomain(session.domain),
    timeLabel: formatSessionTime(session.completedAtUtc),
    status: 'Completed',
  };
};

export const dashboardService = {
  getDashboardOverview: async (): Promise<DashboardViewData> => {
    const dto: DoctorDashboardDto = await doctorApi.getDashboard();

    const kpis: DashboardKpis = {
      totalAssignedChildren: dto.totalAssignedChildren,
      activeChildrenCount: dto.activeChildrenCount,
      weeklyCompletedSessions: dto.weeklyCompletedSessions,
      averageMovementScore: Math.round(dto.averageMovementScore * 10) / 10,
      needsSupportCount: dto.needsSupportCount,
    };

    // Strictly real-data: today's completed sessions only from backend (empty state if 0 today)
    const todaySessions: TodaySessionItem[] = (dto.todayCompletedSessions || []).map(
      mapRecentSessionToTodayItem
    );

    const weeklyTrends: WeeklyTrendPoint[] = (dto.weeklyProgressTrend || []).map((w) => ({
      weekNumber: w.weekNumber ?? (w as unknown as { WeekNumber: number }).WeekNumber,
      weekLabel: w.weekLabel ?? (w as unknown as { WeekLabel: string }).WeekLabel,
      averageScore: Math.round(w.averageScore ?? (w as unknown as { AverageScore: number }).AverageScore),
    }));

    const needingAttentionChildren: AssignedChild[] = (dto.needsSupportAlerts || []).map(
      mapAlertToAssignedChild
    );

    return {
      kpis,
      todaySessions,
      weeklyTrends,
      needingAttentionChildren,
      referralCode: dto.referralCode || '',
    };
  },
};

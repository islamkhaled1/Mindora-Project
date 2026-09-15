export type PerformanceTrend = 'NeedsSupport' | 'Steady' | 'Improving';
export type SupportLevel = 'Mild' | 'Moderate' | 'High' | 'NotSpecified';
export type Gender = 'Boy' | 'Girl' | 'Other' | 'Male' | 'Female' | 'NotSpecified';
export type ActivityDomain = 'Movement' | 'Speech' | 'Attention' | 'Cognitive' | 'SocialEmotional';

export interface DoctorProfile {
  name: string;
  specialization: string;
  clinicName?: string;
  avatarUrl?: string;
  referralCode: string;
  gender?: string;
}

export interface AssignedChild {
  id: string;
  fullName: string;
  avatarInitial: string;
  avatarBgColor?: string;
  avatarUrl?: string;
  dateOfBirth: string;
  ageYears: number;
  gender: Gender;
  supportLevel: SupportLevel;
  supportNotes?: string;
  currentMovementLevel: string;
  totalCompletedSessions: number;
  totalPracticeMinutes: number;
  overallAverageScore: number;
  recentTrend: PerformanceTrend;
  lastSessionDate: string; // e.g. "اليوم", "أمس", "منذ يومين"
  lastSessionDateUtc?: string;
  doctorNotes?: string;
  doctorNotesUpdatedAt?: string;
}

export interface TodaySessionItem {
  id: string;
  childId: string;
  childName: string;
  domain: string; // e.g. "التواصل", "الحركة", "التركيز"
  timeLabel: string; // e.g. "10:00 صباحاً"
  status: 'Completed' | 'Upcoming';
}

export interface WeeklyTrendPoint {
  weekNumber: number;
  weekLabel: string; // "الاسبوع الاول", etc.
  averageScore: number;
}

export interface DashboardKpis {
  totalAssignedChildren: number;
  activeChildrenCount: number; // "أطفال نشطون"
  weeklyCompletedSessions: number;
  averageMovementScore: number;
  needsSupportCount: number;
}

export interface LastSessionTaskItem {
  id: string;
  domain: string; // "التواصل", "الفهم والإدراك", "الحركة"
  activityTitle: string; // "قولها معايا", "اسمع وابحث", "اتبع الحركة"
  score: number; // 80, 70, 60
  status: PerformanceTrend;
}

export interface WeeklyRoutineTarget {
  id: string;
  domain: string;
  title: string;
  sessionsPerWeek: number;
  description: string;
  iconType: 'speech' | 'motor' | 'cognitive' | 'social';
  color: string;
  bgColor: string;
  progressPercentage: number;
}

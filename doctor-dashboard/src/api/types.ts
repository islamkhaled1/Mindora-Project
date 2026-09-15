/**
 * ASP.NET Core Backend DTO types for Mindora Doctor Dashboard.
 * Strictly aligned with backend feature DTOs in Mindora.Application.
 */

export interface AuthUserDto {
  id: string;
  email: string;
  fullName: string;
  role: 'Doctor' | 'Parent';
  profileId: string;
}

export interface AuthResponseDto {
  token?: string | null;
  expiresAtUtc?: string | null;
  user?: AuthUserDto | null;
  requiresEmailVerification?: boolean;
}

export interface SendVerificationOtpRequest {
  email: string;
  platform: 'DoctorDashboard' | 'SawaApp';
}

export interface SendVerificationOtpResponse {
  succeeded: boolean;
  message: string;
  alreadyVerified?: boolean;
}

export interface VerifyEmailRequest {
  email: string;
  otp: string;
  platform: 'DoctorDashboard' | 'SawaApp';
}

export interface VerifyEmailResponse {
  succeeded: boolean;
  message: string;
  token?: string | null;
  expiresAtUtc?: string | null;
  user?: AuthUserDto | null;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterDoctorRequest {
  email: string;
  password: string;
  fullName: string;
  specialization: string;
  clinicName?: string;
  licenseNumber?: string;
  gender?: 'Male' | 'Female';
}

export interface DoctorLinkRequestSummaryDto {
  id: string;
  doctorId: string;
  parentId: string;
  childId: string;
  childName: string;
  parentName: string;
  childGender?: string | null;
  childAgeYears?: number | null;
  status: 'Pending' | 'Approved' | 'Rejected';
  createdAtUtc: string;
  respondedAtUtc?: string | null;
}

export interface CurrentUserDto {
  userId: string;
  email: string;
  fullName: string;
  role: 'Doctor' | 'Parent';
  profileId: string;
  gender?: 'Male' | 'Female' | 'Other' | string | null;
  specialization?: string | null;
  clinicName?: string | null;
  referralCode?: string | null;
}

export interface ProblemDetails {
  type?: string;
  title?: string;
  status?: number;
  detail?: string;
  instance?: string;
  errors?: Record<string, string[]>;
}

export interface DoctorNeedsSupportAlertDto {
  childId: string;
  fullName: string;
  ageYears: number;
  overallAverageScore: number;
  currentMovementLevel: string;
  recentTrend: string;
  daysSinceLastSession: number;
  lastSessionDateUtc: string | null;
}

export interface DoctorRecentSessionDto {
  sessionId: string;
  childId: string;
  childFullName: string;
  activityTitle: string;
  domain: string;
  overallScore: number;
  durationSeconds: number;
  completedAtUtc: string;
}

export interface DoctorWeeklyTrendDto {
  weekNumber: number;
  weekLabel: string;
  averageScore: number;
}

export interface DoctorDashboardDto {
  totalAssignedChildren: number;
  activeChildrenCount: number;
  weeklyCompletedSessions: number;
  averageMovementScore: number;
  needsSupportCount: number;
  needsSupportAlerts: DoctorNeedsSupportAlertDto[];
  recentCompletedSessions: DoctorRecentSessionDto[];
  referralCode: string;
  weeklyProgressTrend: DoctorWeeklyTrendDto[];
  todayCompletedSessions: DoctorRecentSessionDto[];
}

export interface DoctorChildCardDto {
  childId: string;
  fullName: string;
  dateOfBirth: string;
  ageYears: number;
  supportNotes: string | null;
  currentMovementLevel: string;
  totalCompletedSessions: number;
  totalPracticeMinutes: number;
  overallAverageScore: number;
  recentTrend: string;
  lastSessionDateUtc: string | null;
  assignedAtUtc: string;
  gender: string | null;
  avatarUrl: string | null;
  supportLevel: string | null;
}

export interface AssignedDoctorSummaryDto {
  doctorId: string;
  specialization: string;
  clinicName: string | null;
  assignedAtUtc: string;
  referralCode: string | null;
}

export interface ChildDetailsDto {
  id: string;
  parentId: string;
  fullName: string;
  dateOfBirth: string;
  supportNotes: string | null;
  currentMovementLevel: string;
  currentSpeechLevel: string;
  currentAttentionLevel: string;
  createdAtUtc: string;
  assignedDoctors: AssignedDoctorSummaryDto[];
  gender: string | null;
  diagnosis: string | null;
  avatarUrl: string | null;
  supportLevel: string | null;
  hearingStatus: string | null;
  visionStatus: string | null;
  focusDurationMinutes: number | null;
  preferredPracticeTime: string | null;
  preferredActivityType: string | null;
}

export interface DomainProgressDto {
  domain: string;
  completedSessions: number;
  averageScore: number;
  latestScore: number;
  trend: string;
}

export interface ChildProgressSummaryDto {
  childId: string;
  totalCompletedSessions: number;
  totalPracticeMinutes: number;
  overallAverageScore: number;
  currentStreakDays: number;
  recentPerformanceTrend: string;
  domainSummaries: DomainProgressDto[];
}

export interface SessionHistoryPointDto {
  sessionId: string;
  activityTitle: string;
  domain: string;
  score: number;
  durationSeconds: number;
  completedAtUtc: string;
}

export interface ActivityPerformanceDto {
  activityId: string;
  activityTitle: string;
  domain: string;
  baseDifficulty: string;
  timesPlayed: number;
  totalPracticeMinutes: number;
  averageScore: number;
  bestScore: number;
  latestScore: number;
  averageAccuracyPercentage: number | null;
  averageReactionTimeMs: number | null;
  averageRepetitions: number | null;
  lastPlayedUtc: string;
}

export interface DoctorNotesDto {
  childId: string;
  notes: string | null;
  updatedAtUtc: string | null;
}

export interface UpdateDoctorNotesRequest {
  notes: string | null;
}

export interface ForgotPasswordRequest {
  email: string;
  platform?: string;
}

export interface ForgotPasswordResponse {
  message: string;
  status: 'ContinueReset' | 'WrongPlatform' | string;
  targetPlatform?: string;
}

export interface VerifyOtpRequest {
  email: string;
  otp: string;
  platform?: string;
}

export interface VerifyOtpResponse {
  resetToken: string;
  message: string;
}

export interface ResetPasswordRequest {
  resetToken: string;
  newPassword: string;
  confirmPassword: string;
  platform?: string;
}

export interface ResetPasswordResponse {
  message: string;
}

export interface ChangePasswordRequest {
  currentPassword: string;
  newPassword: string;
  confirmPassword: string;
}

export interface ChangePasswordResponse {
  message: string;
}



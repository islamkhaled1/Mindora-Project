import { doctorApi } from '../api/doctorApi';
import { childrenApi } from '../api/childrenApi';
import type {
  DoctorChildCardDto,
  ChildDetailsDto,
  ChildProgressSummaryDto,
  SessionHistoryPointDto,
  ActivityPerformanceDto,
  DoctorNotesDto,
} from '../api/types';
import type {
  AssignedChild,
  PerformanceTrend,
  WeeklyRoutineTarget,
  LastSessionTaskItem,
} from '../types';
import {
  toGender,
  toSupportLevel,
  toPerformanceTrend,
  formatDomain,
} from '../utils/enumMappers';

export const formatLastSessionDate = (utcDate?: string | null): string => {
  if (!utcDate) return 'لم تبدأ بعد';
  try {
    const normalized =
      utcDate.endsWith('Z') || utcDate.includes('+') ? utcDate : `${utcDate}Z`;
    const date = new Date(normalized);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays <= 0) return 'اليوم';
    if (diffDays === 1) return 'أمس';
    if (diffDays === 2) return 'منذ يومين';
    if (diffDays > 2 && diffDays <= 10) return `منذ ${diffDays} أيام`;
    if (diffDays > 10 && diffDays < 30) return `منذ ${diffDays} يوماً`;
    return date.toLocaleDateString('ar-EG', {
      month: 'short',
      day: 'numeric',
      year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined,
    });
  } catch {
    return 'لم تبدأ بعد';
  }
};

export const formatDoctorNotesTimestamp = (utcDate?: string | null): string => {
  if (!utcDate) return '';
  try {
    const normalized =
      utcDate.endsWith('Z') || utcDate.includes('+') ? utcDate : `${utcDate}Z`;
    const date = new Date(normalized);
    const now = new Date();
    return `${date.toLocaleDateString('ar-EG', {
      day: 'numeric',
      month: 'long',
      year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined,
    })}، ${date.toLocaleTimeString('ar-EG', {
      hour: '2-digit',
      minute: '2-digit',
    })}`;
  } catch {
    return '';
  }
};

export const calculateAgeYears = (dobString: string): number => {
  try {
    const dob = new Date(dobString);
    const now = new Date();
    let age = now.getFullYear() - dob.getFullYear();
    const m = now.getMonth() - dob.getMonth();
    if (m < 0 || (m === 0 && now.getDate() < dob.getDate())) {
      age--;
    }
    return Math.max(0, age);
  } catch {
    return 0;
  }
};

export const mapDoctorChildCardDtoToAssignedChild = (dto: DoctorChildCardDto): AssignedChild => {
  const fullName = dto.fullName?.trim() || 'طفل غير معروف';
  return {
    id: dto.childId,
    fullName,
    avatarInitial: fullName.charAt(0) || 'ط',
    avatarUrl: dto.avatarUrl || undefined,
    dateOfBirth: dto.dateOfBirth,
    ageYears: dto.ageYears,
    gender: toGender(dto.gender),
    supportLevel: toSupportLevel(dto.supportLevel),
    supportNotes: dto.supportNotes || undefined,
    currentMovementLevel: dto.currentMovementLevel || 'Beginner',
    totalCompletedSessions: dto.totalCompletedSessions,
    totalPracticeMinutes: dto.totalPracticeMinutes,
    overallAverageScore: Math.round(dto.overallAverageScore),
    recentTrend: toPerformanceTrend(dto.recentTrend),
    lastSessionDate: formatLastSessionDate(dto.lastSessionDateUtc),
    lastSessionDateUtc: dto.lastSessionDateUtc || undefined,
  };
};

export const mapChildDetailsAndProgressToAssignedChild = (
  details: ChildDetailsDto,
  progress: ChildProgressSummaryDto,
  lastSessionDateUtc?: string | null
): AssignedChild => {
  const fullName = details.fullName?.trim() || 'طفل غير معروف';
  return {
    id: details.id,
    fullName,
    avatarInitial: fullName.charAt(0) || 'ط',
    avatarUrl: details.avatarUrl || undefined,
    dateOfBirth: details.dateOfBirth,
    ageYears: calculateAgeYears(details.dateOfBirth),
    gender: toGender(details.gender),
    supportLevel: toSupportLevel(details.supportLevel),
    supportNotes: details.supportNotes || undefined,
    currentMovementLevel: details.currentMovementLevel || 'Beginner',
    totalCompletedSessions: progress.totalCompletedSessions,
    totalPracticeMinutes: progress.totalPracticeMinutes,
    overallAverageScore: Math.round(progress.overallAverageScore),
    recentTrend: toPerformanceTrend(progress.recentPerformanceTrend),
    lastSessionDate: formatLastSessionDate(lastSessionDateUtc),
    lastSessionDateUtc: lastSessionDateUtc || undefined,
  };
};

export const deriveLastSessionTasks = (
  history: SessionHistoryPointDto[],
  _progress?: ChildProgressSummaryDto
): LastSessionTaskItem[] => {
  if (!history || history.length === 0) return [];

  // Sort descending by completion date so recent sessions appear first
  const sorted = [...history].sort(
    (a, b) => new Date(b.completedAtUtc).getTime() - new Date(a.completedAtUtc).getTime()
  );

  // Take the most recent sessions (up to 5)
  return sorted.slice(0, 5).map((session) => {
    const roundedScore = Math.round(session.score);
    let status: PerformanceTrend = 'Steady';
    if (roundedScore >= 80) status = 'Improving';
    else if (roundedScore < 65) status = 'NeedsSupport';

    return {
      id: session.sessionId,
      domain: formatDomain(session.domain),
      activityTitle: session.activityTitle,
      score: roundedScore,
      status,
    };
  });
};

export const deriveWeeklyRoutineTargets = (
  progress: ChildProgressSummaryDto
): WeeklyRoutineTarget[] => {
  const summaries = progress.domainSummaries || [];
  const movement = summaries.find((s) => s.domain.toLowerCase() === 'movement');
  const speech = summaries.find((s) => s.domain.toLowerCase() === 'speech');
  const attention = summaries.find((s) => s.domain.toLowerCase() === 'attention');
  const cognitiveOrSocial = summaries.find(
    (s) =>
      s.domain.toLowerCase() === 'cognitive' ||
      s.domain.toLowerCase() === 'socialemotional' ||
      s.domain.toLowerCase() === 'social'
  );

  return [
    {
      id: 'routine-speech',
      domain: 'نطق وتواصل',
      title: 'تمارين النطق والتواصل',
      sessionsPerWeek: speech ? Math.max(2, speech.completedSessions) : 3,
      description: 'تحفيز الكلمات البسيطة وتدريبات إخراج الأصوات',
      iconType: 'speech',
      color: '#8456D2',
      bgColor: '#F0E8FF',
      progressPercentage: speech ? Math.round(speech.averageScore) : 0,
    },
    {
      id: 'routine-motor',
      domain: 'حركي وتآزر',
      title: 'تطوير التآزر الحركي البصري',
      sessionsPerWeek: movement ? Math.max(3, movement.completedSessions) : 4,
      description: 'تمارين الإمساك بالأشياء والتحكم في حركة اليدين',
      iconType: 'motor',
      color: '#FDB62C',
      bgColor: '#FFF8EB',
      progressPercentage: movement ? Math.round(movement.averageScore) : 0,
    },
    {
      id: 'routine-attention',
      domain: 'معرفي وإدراك',
      title: 'تعزيز الانتباه والذاكرة',
      sessionsPerWeek: attention ? Math.max(2, attention.completedSessions) : 2,
      description: 'ألعاب تصنيف الألوان ومطابقة الأشكال الهندسية',
      iconType: 'cognitive',
      color: '#6DAA60',
      bgColor: '#EEF3EE',
      progressPercentage: attention ? Math.round(attention.averageScore) : 0,
    },
    {
      id: 'routine-social',
      domain: 'تفاعل وتواصل',
      title: 'مهارات التفاعل الاجتماعي',
      sessionsPerWeek: 2,
      description: 'الاستجابة للنداء والتواصل البصري مع المحيطين',
      iconType: 'social',
      color: '#BD3737',
      bgColor: '#FFD4CA',
      progressPercentage: cognitiveOrSocial
        ? Math.round(cognitiveOrSocial.averageScore)
        : Math.round(progress.overallAverageScore || 0),
    },
  ];
};

export interface ChildFilterCounts {
  all: number;
  needsSupport: number;
  improving: number;
  steady: number;
}

export const childrenService = {
  getDoctorChildren: async (): Promise<AssignedChild[]> => {
    const dtos = await doctorApi.getChildren();
    return dtos.map(mapDoctorChildCardDtoToAssignedChild);
  },

  calculateFilterCounts: (children: AssignedChild[]): ChildFilterCounts => {
    return {
      all: children.length,
      needsSupport: children.filter((c) => c.recentTrend === 'NeedsSupport').length,
      improving: children.filter((c) => c.recentTrend === 'Improving').length,
      steady: children.filter((c) => c.recentTrend === 'Steady').length,
    };
  },

  filterChildren: (
    children: AssignedChild[],
    searchQuery: string = '',
    statusFilter: string = 'all'
  ): AssignedChild[] => {
    let result = [...children];

    if (searchQuery.trim().length > 0) {
      const term = searchQuery.trim().toLowerCase();
      result = result.filter((child) => child.fullName.toLowerCase().includes(term));
    }

    if (statusFilter && statusFilter !== 'all') {
      result = result.filter((child) => child.recentTrend === statusFilter);
    }

    return result;
  },

  getChildDetails: (childId: string): Promise<ChildDetailsDto> => {
    return childrenApi.getChildDetails(childId);
  },

  getChildProgress: (childId: string): Promise<ChildProgressSummaryDto> => {
    return childrenApi.getChildProgress(childId);
  },

  getChildProgressHistory: (childId: string): Promise<SessionHistoryPointDto[]> => {
    return childrenApi.getChildProgressHistory(childId);
  },

  getChildActivityPerformance: (childId: string): Promise<ActivityPerformanceDto[]> => {
    return childrenApi.getChildActivityPerformance(childId);
  },

  getDoctorNotes: async (childId: string): Promise<DoctorNotesDto> => {
    return await doctorApi.getDoctorNotes(childId);
  },

  updateDoctorNotes: async (
    childId: string,
    notes: string | null
  ): Promise<DoctorNotesDto> => {
    return await doctorApi.updateDoctorNotes(childId, notes);
  },

  getChildProfileAndProgress: async (
    childId: string
  ): Promise<{
    child: AssignedChild;
    weeklyRoutine: WeeklyRoutineTarget[];
  }> => {
    // Phase 3 Scope: Strictly fetch only Child Details and Child Progress
    const [details, progress] = await Promise.all([
      childrenApi.getChildDetails(childId),
      childrenApi.getChildProgress(childId),
    ]);

    const child = mapChildDetailsAndProgressToAssignedChild(details, progress);
    const weeklyRoutine = deriveWeeklyRoutineTargets(progress);

    return {
      child,
      weeklyRoutine,
    };
  },

  getChildFullProfile: async (
    childId: string
  ): Promise<{
    child: AssignedChild;
    weeklyRoutine: WeeklyRoutineTarget[];
    lastSessionTasks: LastSessionTaskItem[];
    doctorNotes: DoctorNotesDto | null;
  }> => {
    // Concurrently fetch details, progress summary, progress history, and notes
    const [details, progress, history, notesDto] = await Promise.all([
      childrenApi.getChildDetails(childId),
      childrenApi.getChildProgress(childId),
      childrenApi.getChildProgressHistory(childId).catch((err) => {
        console.warn('Could not load session history for child', childId, err);
        return [] as SessionHistoryPointDto[];
      }),
      doctorApi.getDoctorNotes(childId).catch((err) => {
        console.warn('Could not load doctor notes for child', childId, err);
        return null;
      }),
    ]);

    const latestSession = [...(history || [])].sort(
      (a, b) => new Date(b.completedAtUtc).getTime() - new Date(a.completedAtUtc).getTime()
    )[0];

    const child = mapChildDetailsAndProgressToAssignedChild(
      details,
      progress,
      latestSession?.completedAtUtc
    );
    child.doctorNotes = notesDto?.notes || undefined;
    child.doctorNotesUpdatedAt = formatDoctorNotesTimestamp(notesDto?.updatedAtUtc);

    const weeklyRoutine = deriveWeeklyRoutineTargets(progress);
    const lastSessionTasks = deriveLastSessionTasks(history, progress);

    return {
      child,
      weeklyRoutine,
      lastSessionTasks,
      doctorNotes: notesDto,
    };
  },
};

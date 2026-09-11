/**
 * Mindora API Service
 * متوافق 100% مع مواصفات Mindora API Specification & Integration Contract
 * يربط لوحة تحكم الطبيب بسيرفر .NET 10 Web API
 */

// الرابط الأساسي للباك إند (المذكور في الوثيقة)
export const API_BASE_URL =
  (typeof import.meta !== 'undefined' &&
    (import.meta as Record<string, any>)?.env?.VITE_API_URL) ||
  'http://localhost:5222';

// دالة مساعدة لجلب Headers وتمرير JWT Bearer Token تلقائياً
function getHeaders(): HeadersInit {
  const token = localStorage.getItem('mindora_token');
  return {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
}

// -------------------------------------------------------------
// 1. Authentication (api/auth)
// -------------------------------------------------------------

export interface LoginResponse {
  token: string;
  expiresAtUtc: string;
  user: {
    id: string;
    email: string;
    fullName: string;
    role: 'Doctor' | 'Parent';
    profileId: string;
  };
}

/**
 * 2.3 تسجيل دخول الطبيب
 * POST /api/auth/login
 */
export async function loginDoctor(email: string, password: string): Promise<LoginResponse> {
  const response = await fetch(`${API_BASE_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.detail || 'فشل تسجيل الدخول، تأكد من صحة البريد وكلمة المرور');
  }

  const data: LoginResponse = await response.json();
  // حفظ التوكن وبيانات الطبيب
  localStorage.setItem('mindora_token', data.token);
  localStorage.setItem('mindora_user', JSON.stringify(data.user));
  return data;
}

/**
 * 2.4 جلب بيانات المستخدم الحالي
 * GET /api/auth/me
 */
export async function getCurrentUser() {
  const response = await fetch(`${API_BASE_URL}/api/auth/me`, {
    headers: getHeaders(),
  });
  if (!response.ok) return null;
  return response.json();
}

/**
 * تسجيل الخروج
 */
export function logout() {
  localStorage.removeItem('mindora_token');
  localStorage.removeItem('mindora_user');
}

// -------------------------------------------------------------
// 2. Doctor Dashboard Endpoints (api/doctor)
// -------------------------------------------------------------

export interface DoctorDashboardOverview {
  totalAssignedChildren: number;
  activeChildrenCount: number;
  weeklyCompletedSessions: number;
  averageMovementScore: number;
  needsSupportCount: number;
  needsSupportAlerts: Array<{
    childId: string;
    fullName: string;
    currentMovementLevel: string;
    recentTrend: 'Improving' | 'Stable' | 'NeedsSupport';
    daysSinceLastSession: number;
  }>;
  recentCompletedSessions: Array<{
    sessionId: string;
    childId: string;
    childFullName: string;
    activityTitle: string;
    domain: string;
    overallScore: number;
    durationSeconds: number;
    completedAtUtc: string;
  }>;
}

/**
 * 7.1 جلب إحصائيات لوحة تحكم الطبيب الرئيسية
 * GET /api/doctor/dashboard
 */
export async function getDoctorDashboard(): Promise<DoctorDashboardOverview | null> {
  const url = `${API_BASE_URL}/api/doctor/dashboard`;
  console.log(' [Mindora API] جاري إرسال Request إلى:', url);
  try {
    const response = await fetch(url, {
      headers: getHeaders(),
    });
    console.log(' [Mindora API] حالة الرد من السيرفر (Status):', response.status);
    if (!response.ok) return null;
    const data = await response.json();
    console.log(' [Mindora API] تم استلام بيانات الداشبورد بنجاح:', data);
    return data;
  } catch (err) {
    console.warn(' [Mindora API] تعذر الاتصال بسيرفر الباك إند المحلي، سيتم استخدام البيانات المحلية.', err);
    return null;
  }
}

export interface DoctorChildItem {
  childId: string;
  fullName: string;
  dateOfBirth: string;
  ageYears: number;
  supportNotes: string;
  currentMovementLevel: string;
  totalCompletedSessions: number;
  totalPracticeMinutes: number;
  overallAverageScore: number;
  recentTrend: 'Improving' | 'Stable' | 'NeedsSupport';
  lastSessionDateUtc: string;
  assignedAtUtc: string;
}

/**
 * 7.2 جلب قائمة أطفال الطبيب المعتمدين
 * GET /api/doctor/children
 */
export async function getDoctorChildren(): Promise<DoctorChildItem[] | null> {
  const url = `${API_BASE_URL}/api/doctor/children`;
  console.log(' [Mindora API] جاري إرسال Request لجلب الأطفال إلى:', url);
  try {
    const response = await fetch(url, {
      headers: getHeaders(),
    });
    console.log(' [Mindora API] حالة الرد لقائمة الأطفال (Status):', response.status);
    if (!response.ok) return null;
    const data = await response.json();
    console.log(' [Mindora API] تم استلام قائمة الأطفال بنجاح:', data);
    return data;
  } catch (err) {
    console.warn(' [Mindora API] تعذر الاتصال بسيرفر الباك إند لجلب الأطفال.', err);
    return null;
  }
}

/**
 * 7.3 ربط طفل جديد عبر كود الإحالة/الربط
 * POST /api/doctor/link-child
 */
export async function linkChildWithCode(linkingCode: string) {
  const response = await fetch(`${API_BASE_URL}/api/doctor/link-child`, {
    method: 'POST',
    headers: getHeaders(),
    body: JSON.stringify({ linkingCode }),
  });
  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.detail || 'كود الربط غير صحيح أو منتهي الصلاحية.');
  }
  return response.json();
}

// -------------------------------------------------------------
// 3. Children Progress & Details Endpoints (api/children)
// -------------------------------------------------------------

export interface ChildProgressSummary {
  childId: string;
  totalCompletedSessions: number;
  totalPracticeMinutes: number;
  overallAverageScore: number;
  currentStreakDays: number;
  recentPerformanceTrend: 'Improving' | 'Stable' | 'NeedsSupport';
  domainSummaries: Array<{
    domain: string;
    completedSessions: number;
    averageScore: number;
    latestScore: number;
    trend: string;
  }>;
}

/**
 * 6.1 جلب ملخص تقدم الطفل ومهاراته
 * GET /api/children/{childId}/progress
 */
export async function getChildProgress(childId: string): Promise<ChildProgressSummary | null> {
  try {
    const response = await fetch(`${API_BASE_URL}/api/children/${childId}/progress`, {
      headers: getHeaders(),
    });
    if (!response.ok) return null;
    return await response.json();
  } catch (err) {
    console.warn(`تعذر الاتصال بـ API لتقدم الطفل ${childId}`, err);
    return null;
  }
}

/**
 * 6.2 جلب سجل جلسات الطفل السابقة
 * GET /api/children/{childId}/progress/history
 */
export async function getChildHistory(childId: string, page = 1, pageSize = 10) {
  try {
    const response = await fetch(
      `${API_BASE_URL}/api/children/${childId}/progress/history?page=${page}&pageSize=${pageSize}`,
      { headers: getHeaders() }
    );
    if (!response.ok) return [];
    return await response.json();
  } catch (err) {
    return [];
  }
}

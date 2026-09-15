import type { Gender, SupportLevel, PerformanceTrend } from '../types';

/**
 * Normalizes backend gender string to strict Gender type ('Boy' | 'Girl' | 'Other').
 * Backend Gender enum: Boy = 1, Girl = 2, Other = 3.
 */
export const toGender = (gender?: string | null): Gender => {
  if (!gender) return 'NotSpecified';
  const g = gender.trim().toLowerCase();
  if (g === 'girl' || g === 'female' || g === 'بنت' || g === 'أنثى') return 'Girl';
  if (g === 'boy' || g === 'male' || g === 'ولد' || g === 'ذكر') return 'Boy';
  if (g === 'other' || g === 'أخرى') return 'Other';
  return 'NotSpecified';
};

/**
 * Normalizes backend support level string to strict SupportLevel type ('Mild' | 'Moderate' | 'High' | 'NotSpecified').
 * Backend SupportLevel enum: Mild = 1, Moderate = 2, High = 3.
 */
export const toSupportLevel = (level?: string | null): SupportLevel => {
  if (!level) return 'NotSpecified';
  const l = level.trim().toLowerCase();
  if (l === 'mild' || l === 'بسيط') return 'Mild';
  if (l === 'high' || l === 'substantial' || l === 'مكثف') return 'High';
  if (l === 'moderate' || l === 'متوسط') return 'Moderate';
  return 'NotSpecified';
};

/**
 * Normalizes backend recent trend string to strict PerformanceTrend type ('Improving' | 'Steady' | 'NeedsSupport').
 * Backend PerformanceTrend enum: Improving = 1, Steady = 2, NeedsSupport = 3.
 */
export const toPerformanceTrend = (trend?: string | null): PerformanceTrend => {
  if (!trend) return 'Steady';
  const t = trend.trim().toLowerCase();
  if (t === 'improving' || t === 'في تحسن') return 'Improving';
  if (t === 'needssupport' || t === 'يحتاج دعم' || t === 'يحتاج مراجعة') return 'NeedsSupport';
  return 'Steady';
};

export const formatGender = (gender?: string | null): string => {
  const g = toGender(gender);
  if (g === 'Girl') return 'أنثى';
  if (g === 'Boy') return 'ذكر';
  if (g === 'Other') return 'أخرى';
  return 'غير محدد';
};

export const formatSupportLevel = (level?: string | null): string => {
  const l = toSupportLevel(level);
  if (l === 'Mild') return 'بسيط';
  if (l === 'High') return 'مكثف';
  if (l === 'Moderate') return 'متوسط';
  return 'غير محدد';
};

export const formatPerformanceTrend = (trend?: string | null): string => {
  const t = toPerformanceTrend(trend);
  if (t === 'Improving') return 'في تحسن';
  if (t === 'NeedsSupport') return 'يحتاج دعم';
  return 'مستقر';
};

export const formatDomain = (domain?: string | null): string => {
  if (!domain) return 'عام';
  const d = domain.trim().toLowerCase();
  if (d === 'movement' || d === 'حركة' || d === 'الحركة') return 'الحركة';
  if (d === 'speech' || d === 'نطق' || d === 'التواصل' || d === 'النطق') return 'النطق والتواصل';
  if (d === 'attention' || d === 'تركيز' || d === 'الانتباه' || d === 'التركيز') return 'التركيز والانتباه';
  if (d === 'cognitive' || d === 'معرفة' || d === 'إدراك') return 'الإدراك والمعرفة';
  if (d === 'socialemotional' || d === 'تفاعل') return 'التفاعل الاجتماعي';
  return domain;
};

export const formatDifficultyAdjustment = (adjustment?: string | null): string => {
  if (!adjustment) return 'الحفاظ على المستوى';
  const a = adjustment.trim().toLowerCase();
  if (a === 'decrease' || a === '-1') return 'تقليل التحدي';
  if (a === 'maintain' || a === '0') return 'الحفاظ على المستوى';
  if (a === 'increase' || a === '1') return 'زيادة التحدي';
  return 'الحفاظ على المستوى';
};

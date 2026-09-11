import { ActiveChild, MetricCardItem, StatusDistributionItem, ChildCardItem } from '../types';

export const METRIC_CARDS: MetricCardItem[] = [
  {
    id: 'total',
    title: 'إجمالي الأطفال',
    value: 15,
    unit: 'طفل',
    iconName: 'user',
  },
  {
    id: 'active',
    title: 'أطفال نشطون',
    value: 12,
    unit: 'طفل',
    iconName: 'users',
  },
  {
    id: 'needs-support',
    title: 'يحتاج دعم',
    value: 5,
    unit: 'طفل',
    iconName: 'alert',
  },
  {
    id: 'stable',
    title: 'مستقر',
    value: 6,
    unit: 'طفل',
    iconName: 'check',
  },
  {
    id: 'improving',
    title: 'في تحسن',
    value: 4,
    unit: 'طفل',
    iconName: 'trending',
  },
];

export const ACTIVE_CHILDREN: ActiveChild[] = [
  {
    id: '1',
    name: 'عمر أحمد',
    field: 'تواصل',
    goal: 'التواصل البصري',
    percentage: 80,
    status: 'في تحسن',
  },
  {
    id: '2',
    name: 'سارة محمد',
    field: 'لغة',
    goal: 'تطوير الكلمات',
    percentage: 70,
    status: 'يحتاج دعم',
  },
  {
    id: '3',
    name: 'يوسف خالد',
    field: 'الحركه',
    goal: 'التوازن الحركي',
    percentage: 60,
    status: 'مستقر',
  },
  {
    id: '4',
    name: 'مريم علي',
    field: 'مهارات اجتماعيه',
    goal: 'التفاعل الاجتماعي',
    percentage: 60,
    status: 'يحتاج اهتمام',
  },
];

export const STATUS_DISTRIBUTION: StatusDistributionItem[] = [
  { label: 'مستقر', count: 6, color: '#56B280', percent: 40 },
  { label: 'في تحسن', count: 4, color: '#4F92F7', percent: 27 },
  { label: 'يحتاج دعم', count: 5, color: '#D8CEF9', percent: 33 },
];

export const ALL_CHILDREN: ChildCardItem[] = [
  { id: '1', name: 'عمر أحمد', age: '6 سنوات', initial: 'ع', percentage: 72, status: 'في تحسن' },
  { id: '2', name: 'ليلى محمد', age: '6 سنوات', initial: 'ل', percentage: 72, status: 'في تحسن' },
  { id: '3', name: 'ساره محمد', age: '6 سنوات', initial: 'س', percentage: 85, status: 'مستقر' },
  { id: '4', name: 'آدم حسن', age: '5 سنوات', initial: 'آ', percentage: 50, status: 'يحتاج دعم' },
  { id: '5', name: 'يوسف وليد', age: '7 سنوات', initial: 'ع', percentage: 55, status: 'يحتاج دعم' },
  { id: '6', name: 'سارة إبراهيم', age: '7 سنوات', initial: 'ع', percentage: 88, status: 'في تحسن' },
  { id: '7', name: 'هنا علي', age: '5 سنوات', initial: 'ع', percentage: 74, status: 'مستقر' },
  { id: '8', name: 'فريدة أحمد', age: '8 سنوات', initial: 'ع', percentage: 90, status: 'مستقر' },
  { id: '9', name: 'يس حسان', age: '6 سنوات', initial: 'ي', percentage: 58, status: 'يحتاج دعم' },
  { id: '10', name: 'ريان خالد', age: '7 سنوات', initial: 'ر', percentage: 82, status: 'مستقر' },
  { id: '11', name: 'مريم سعيد', age: '6 سنوات', initial: 'م', percentage: 78, status: 'مستقر' },
  { id: '12', name: 'حمزة وائل', age: '6 سنوات', initial: 'ح', percentage: 68, status: 'في تحسن' },
  { id: '13', name: 'نور الدين', age: '5 سنوات', initial: 'ن', percentage: 45, status: 'يحتاج دعم' },
  { id: '14', name: 'كنان مصطفى', age: '5 سنوات', initial: 'ك', percentage: 52, status: 'يحتاج دعم' },
  { id: '15', name: 'زياد طارق', age: '5 سنوات', initial: 'ز', percentage: 80, status: 'مستقر' },
];

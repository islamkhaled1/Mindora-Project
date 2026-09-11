export interface ActiveChild {
  id: string;
  name: string;
  field: string;
  goal: string;
  percentage: number;
  status: 'في تحسن' | 'يحتاج دعم' | 'مستقر' | 'يحتاج اهتمام';
}

export interface MetricCardItem {
  id: string;
  title: string;
  value: number;
  unit: string;
  iconName: 'user' | 'users' | 'alert' | 'check' | 'trending';
}

export interface StatusDistributionItem {
  label: string;
  count: number;
  color: string;
  percent: number;
}

export interface ChildCardItem {
  id: string;
  name: string;
  age: string;
  initial: string;
  percentage: number;
  status: 'في تحسن' | 'مستقر' | 'يحتاج دعم';
}

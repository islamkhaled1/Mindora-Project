import React, { useState, useMemo, useEffect } from 'react';
import Sidebar from './components/Sidebar';
import Header from './components/Header';
import MetricCards from './components/MetricCards';
import ActiveChildrenTable from './components/ActiveChildrenTable';
import StatusDistributionChart from './components/StatusDistributionChart';
import ChildrenListView from './components/ChildrenListView';
import ChildDetailView from './components/ChildDetailView';
import { ChildCardItem, MetricCardItem } from './types';
import {
  METRIC_CARDS,
  ACTIVE_CHILDREN,
  STATUS_DISTRIBUTION,
  ALL_CHILDREN,
} from './data/mockData';
import {
  getDoctorChildren,
  getDoctorDashboard,
  DoctorChildItem,
} from './services/mindoraApi';

export default function App() {
  const [activeTab, setActiveTab] = useState('children');
  const [selectedChild, setSelectedChild] = useState<ChildCardItem | null>(null);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // بيانات الأطفال والإحصائيات (تبدأ بالبيانات الافتراضية، وتتحدث تلقائياً من الـ API الحقيقي)
  const [childrenList, setChildrenList] = useState<ChildCardItem[]>(ALL_CHILDREN);
  const [metrics, setMetrics] = useState<MetricCardItem[]>(METRIC_CARDS);

  // 1. الاتصال التلقائي بالـ API عند فتح الصفحة
  useEffect(() => {
    async function loadApiData() {
      try {
        // جلب الأطفال من الباك إند: GET /api/doctor/children
        const apiChildren = await getDoctorChildren();
        if (apiChildren && apiChildren.length > 0) {
          const formattedChildren: ChildCardItem[] = apiChildren.map(
            (c: DoctorChildItem) => {
              let statusLabel: 'يحتاج دعم' | 'مستقر' | 'في تحسن' = 'مستقر';
              if (c.recentTrend === 'NeedsSupport') statusLabel = 'يحتاج دعم';
              else if (c.recentTrend === 'Improving') statusLabel = 'في تحسن';

              return {
                id: c.childId,
                name: c.fullName,
                age: `${c.ageYears} سنوات`,
                percentage: Math.round(c.overallAverageScore || 70),
                status: statusLabel,
                initial: c.fullName ? c.fullName.trim().charAt(0) : 'ط',
              };
            }
          );
          setChildrenList(formattedChildren);
        }

        // جلب إحصائيات الداشبورد: GET /api/doctor/dashboard
        const dashboardOverview = await getDoctorDashboard();
        if (dashboardOverview) {
          setMetrics([
            {
              id: 'total',
              value: dashboardOverview.totalAssignedChildren || 15,
              title: 'إجمالي الأطفال',
              unit: 'طفل',
              iconName: 'user',
            },
            {
              id: 'active',
              value: dashboardOverview.activeChildrenCount || 12,
              title: 'أطفال نشطون',
              unit: 'طفل',
              iconName: 'users',
            },
            {
              id: 'needs-support',
              value: dashboardOverview.needsSupportCount || 5,
              title: 'يحتاج دعم',
              unit: 'طفل',
              iconName: 'alert',
            },
            {
              id: 'stable',
              value: 6,
              title: 'مستقر',
              unit: 'طفل',
              iconName: 'check',
            },
            {
              id: 'improving',
              value: 4,
              title: 'في تحسن',
              unit: 'طفل',
              iconName: 'trending',
            },
          ]);
        }
      } catch {
        console.log('يعمل بالوضع الاحتياطي المحلي');
      }
    }

    loadApiData();
  }, []);

  // تصفية أطفال نشطون في الصفحة الرئيسية بناءً على حقل البحث
  const filteredActiveChildren = useMemo(() => {
    if (!searchQuery.trim()) return ACTIVE_CHILDREN;
    const query = searchQuery.trim().toLowerCase();
    return ACTIVE_CHILDREN.filter(
      (c) =>
        c.name.toLowerCase().includes(query) ||
        c.field.toLowerCase().includes(query) ||
        c.goal.toLowerCase().includes(query) ||
        c.status.toLowerCase().includes(query)
    );
  }, [searchQuery]);

  const handleTabChange = (tabId: string) => {
    setActiveTab(tabId);
    if (tabId !== 'children') {
      setSelectedChild(null);
    }
  };

  return (
    <div className="dashboard-layout" dir="rtl">
      {/* القائمة الجانبية (يمين) */}
      <Sidebar
        activeTab={activeTab}
        onTabChange={handleTabChange}
        isOpenMobile={mobileMenuOpen}
        onCloseMobile={() => setMobileMenuOpen(false)}
      />

      {/* منطقة المحتوى الرئيسية */}
      <main className="dashboard-main">
        <div className="dashboard-container">
          {activeTab === 'children' ? (
            selectedChild ? (
              /* صفحة تفاصيل الطفل (المطابقة لـ Dr dashboard (4).png) */
              <ChildDetailView
                child={selectedChild}
                onBack={() => setSelectedChild(null)}
                onOpenMobileMenu={() => setMobileMenuOpen(true)}
              />
            ) : (
              /* صفحة قائمة الأطفال (المطابقة لـ Dr dashboard (2).png) */
              <ChildrenListView
                childrenList={childrenList}
                onOpenMobileMenu={() => setMobileMenuOpen(true)}
                onSelectChild={(child) => setSelectedChild(child)}
              />
            )
          ) : (
            /* الصفحة الرئيسية للداشبورد */
            <>
              {/* الشريط العلوي مع كود الإحالة والبحث والإشعار */}
              <Header
                onOpenMobileMenu={() => setMobileMenuOpen(true)}
                searchQuery={searchQuery}
                onSearchChange={setSearchQuery}
              />

              {/* كروت الإحصائيات الخمسة */}
              <MetricCards metrics={metrics} />

              {/* القسم السفلي: جدول أطفال نشطون يميناً + توزيع الحالات يساراً */}
              <div className="lower-content-grid">
                {/* جدول أطفال نشطون (اليمين) */}
                <ActiveChildrenTable childrenList={filteredActiveChildren} />

                {/* توزيع حالات الأطفال Donut Chart (اليسار) */}
                <StatusDistributionChart
                  items={STATUS_DISTRIBUTION}
                  totalPercentage={72}
                />
              </div>
            </>
          )}
        </div>
      </main>
    </div>
  );
}

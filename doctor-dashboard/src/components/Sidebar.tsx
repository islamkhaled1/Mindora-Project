import React from 'react';

interface SidebarProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
  isOpenMobile?: boolean;
  onCloseMobile?: () => void;
}

export default function Sidebar({
  activeTab,
  onTabChange,
  isOpenMobile = false,
  onCloseMobile,
}: SidebarProps) {
  // القائمة مرتبة ومطابقة تماماً للأيقونات المطلوبة
  const navItems = [
    { id: 'home', label: 'الرئيسيه', iconClass: 'fa-solid fa-house' },
    { id: 'children', label: 'الأطفال', iconClass: 'fa-solid fa-user-group' },
    { id: 'treatment_plans', label: 'خطط العلاج', iconClass: 'fa-solid fa-clipboard-check' },
    { id: 'sessions', label: 'الجلسات', iconClass: 'fa-regular fa-calendar' },
    { id: 'comments', label: 'التعليقات', iconClass: 'fa-regular fa-comment-dots' },
    { id: 'progress', label: 'التقدم', iconClass: 'fa-solid fa-chart-simple' },
    { id: 'settings', label: 'الإعدادات', iconClass: 'fa-solid fa-gear' },
  ];

  return (
    <>
      {/* خلفية معتمة للموبايل */}
      {isOpenMobile && (
        <div
          id="mobile-sidebar-backdrop"
          onClick={onCloseMobile}
          className="fixed inset-0 z-40 bg-black/30 lg:hidden"
        />
      )}

      {/* القائمة الجانبية */}
      <aside
        id="app-sidebar"
        className={`sidebar ${
          isOpenMobile ? 'translate-x-0' : 'max-lg:translate-x-full'
        } max-lg:fixed max-lg:top-0 max-lg:right-0 max-lg:z-50 transition-transform`}
      >
        <div>
          {/* زر الإغلاق في شاشات الموبايل */}
          <div className="flex items-center justify-between pb-4 lg:hidden">
            <span className="text-base font-bold text-[#372868]">سوا للرعاية</span>
            <button
              id="sidebar-close-btn"
              onClick={onCloseMobile}
              className="rounded-lg p-1.5 text-[#372868] hover:bg-[#DFD7F5]"
              aria-label="إغلاق القائمة"
            >
              <i className="fa-solid fa-xmark text-lg"></i>
            </button>
          </div>

          {/* روابط القائمة الجانبية بالأيقونات الجديدة */}
          <nav id="sidebar-nav" className="sidebar-nav">
            {navItems.map((item) => {
              const isActive = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  id={`nav-item-${item.id}`}
                  onClick={() => {
                    onTabChange(item.id);
                    if (onCloseMobile) onCloseMobile();
                  }}
                  className={`sidebar-link ${isActive ? 'active' : ''}`}
                >
                  <i className={`${item.iconClass} sidebar-icon`} aria-hidden="true"></i>
                  <span>{item.label}</span>
                </button>
              );
            })}
          </nav>
        </div>

        {/* بروفايل الطبيبة وزر تسجيل الخروج */}
        <div id="sidebar-profile-section">
          {/* معلومات د. سارة */}
          <div className="sidebar-profile">
            <div className="doctor-avatar-circle">
                <img src="/src/assets/doctor-avatar.svg" alt="صورة د. سارة أحمد" className="doctor-avatar" />
            </div>

            <div className="doctor-text-info">
              <h4 className="doctor-name">د. سارة أحمد</h4>
              <p className="doctor-role">أخصائي رعاية أطفال متلازمة داون</p>
            </div>
          </div>

          {/* زر تسجيل الخروج مع أيقونة FontAwesome */}
          <button
            id="sidebar-logout-btn"
            onClick={() => alert('تم تسجيل الخروج بنجاح')}
            className="sidebar-logout-btn"
          >
            <i className="fa-solid fa-arrow-right-from-bracket sidebar-icon" aria-hidden="true"></i>
            <span>تسجيل الخروج</span>
          </button>
        </div>
      </aside>
    </>
  );
}

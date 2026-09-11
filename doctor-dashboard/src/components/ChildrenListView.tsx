import React, { useState, useMemo } from 'react';
import { ChildCardItem } from '../types';

interface ChildrenListViewProps {
  childrenList: ChildCardItem[];
  onOpenMobileMenu?: () => void;
  onSelectChild?: (child: ChildCardItem) => void;
}

export default function ChildrenListView({
  childrenList,
  onOpenMobileMenu,
  onSelectChild,
}: ChildrenListViewProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedFilter, setSelectedFilter] = useState<string>('all');
  const [showAll, setShowAll] = useState<boolean>(false);

  const INITIAL_LIMIT = 9;

  // حساب الأعداد الحية لكل تصنيف
  const totalCount = childrenList.length;
  const needsSupportCount = childrenList.filter((c) => c.status === 'يحتاج دعم').length;
  const stableCount = childrenList.filter((c) => c.status === 'مستقر').length;
  const improvingCount = childrenList.filter((c) => c.status === 'في تحسن').length;

  // التصفية حسب الفلتر والبحث
  const filteredList = useMemo(() => {
    return childrenList.filter((child) => {
      // فلتر التصنيف
      if (selectedFilter !== 'all' && child.status !== selectedFilter) {
        return false;
      }
      // فلتر البحث
      if (searchQuery.trim()) {
        const query = searchQuery.trim().toLowerCase();
        return (
          child.name.toLowerCase().includes(query) ||
          child.age.toLowerCase().includes(query) ||
          child.status.toLowerCase().includes(query)
        );
      }
      return true;
    });
  }, [childrenList, selectedFilter, searchQuery]);

  // قائمة الأطفال المعروضة (9 كروت كبداية لتفادي الاسكرول والتطابق مع الشاشة)
  const displayedList = useMemo(() => {
    if (showAll || filteredList.length <= INITIAL_LIMIT) {
      return filteredList;
    }
    return filteredList.slice(0, INITIAL_LIMIT);
  }, [filteredList, showAll]);

  return (
    <div id="children-page-view" className="children-page-view" dir="rtl">
      {/* 1. الشريط العلوي لصفحة الأطفال */}
      <div className="children-header-row">
        {/* يمين: العنوان الرئيسي والوصف */}
        <div className="flex items-center gap-3">
          {onOpenMobileMenu && (
            <button
              id="mobile-menu-trigger-children"
              onClick={onOpenMobileMenu}
              className="rounded-xl bg-[#DFD7F5] p-2 text-[#372868] lg:hidden"
              aria-label="القائمة"
              type="button"
            >
              <i className="fa-solid fa-bars text-lg" aria-hidden="true"></i>
            </button>
          )}
          <div>
            <h1 className="children-main-title">الأطفال</h1>
            <p className="children-subtitle">
              إدارة وعرض ملفات جميع الأطفال ومستوى تقدمهم
            </p>
          </div>
        </div>

        {/* يسار: شريط البحث البيضاوي */}
        <div className="header-search-wrapper ml-10">
          <input
            id="header-search-input"
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="البحث"
            className="header-search-input"
          />
          <i
            className="fa-solid fa-magnifying-glass header-search-icon"
            aria-hidden="true"
          ></i>
        </div>
      </div>

      {/* 2. بطاقات الإحصائيات/الفلاتر الأربعة العلوية */}
      <div className="children-stats-filters-row">
        {/* إجمالي الأطفال: 15 */}
        <button
          type="button"
          onClick={() => setSelectedFilter('all')}
          className={`children-filter-chip ${
            selectedFilter === 'all' ? 'active' : ''
          }`}
        >
          <span className="chip-label">إجمالي الأطفال</span>
          <span className="chip-value">{totalCount}</span>
        </button>

        {/* يحتاج دعم: 5 */}
        <button
          type="button"
          onClick={() =>
            setSelectedFilter(selectedFilter === 'يحتاج دعم' ? 'all' : 'يحتاج دعم')
          }
          className={`children-filter-chip ${
            selectedFilter === 'يحتاج دعم' ? 'active' : ''
          }`}
        >
          <span className="chip-label">يحتاج دعم</span>
          <span className="chip-value">{needsSupportCount}</span>
        </button>

        {/* مستقر: 6 */}
        <button
          type="button"
          onClick={() =>
            setSelectedFilter(selectedFilter === 'مستقر' ? 'all' : 'مستقر')
          }
          className={`children-filter-chip ${
            selectedFilter === 'مستقر' ? 'active' : ''
          }`}
        >
          <span className="chip-label">مستقر</span>
          <span className="chip-value">{stableCount}</span>
        </button>

        {/* في تحسن: 4 */}
        <button
          type="button"
          onClick={() =>
            setSelectedFilter(selectedFilter === 'في تحسن' ? 'all' : 'في تحسن')
          }
          className={`children-filter-chip ${
            selectedFilter === 'في تحسن' ? 'active' : ''
          }`}
        >
          <span className="chip-label">في تحسن</span>
          <span className="chip-value">{improvingCount}</span>
        </button>
      </div>

      {/* 3. شبكة كروت الأطفال أو بطاقة عدم وجود نتائج (مطابقة لـ Dr dashboard (3).png) */}
      {filteredList.length === 0 ? (
        <div className='no-results'>
        <div id="no-results-card" className="children-no-results-card">
          <div className="no-results-content">
            <i className="fa-solid fa-users no-results-icon" aria-hidden="true"></i>
            <h2 className="no-results-title">لا توجد نتائج</h2>
            <p className="no-results-subtitle">جرّب تغيير البحث أو الفلتر</p>
          </div>
        </div>
        </div>
      ) : (
        <div className="children-cards-grid">
          {displayedList.map((child) => (
            <div
              key={child.id}
              id={`child-card-${child.id}`}
              onClick={() => onSelectChild && onSelectChild(child)}
              className="child-item-card"
            >
              {/* سهم الدخول على أقصى اليسار */}
              <button
                type="button"
                className="child-card-arrow"
                aria-label={`عرض ملف ${child.name}`}
              >
                <i className="fa-solid fa-chevron-left" aria-hidden="true"></i>
              </button>

              {/* الجزء العلوي: صورة الحرف الأول + الاسم والسن */}
              <div className="child-card-top">
                <div className="child-avatar-circle">
                  <span className='text-[24px] font-bold '>{child.initial}</span>
                </div>
                <div className="child-info-text">
                  <h3 className="child-name">{child.name}</h3>
                  <p className="child-age">{child.age}</p>
                </div>
              </div>

              {/* الجزء الأوسط: النسبة وشريط التقدم */}
              <div className="child-progress-section">
                {/* شريط التقدم بالأرجواني الداكن */}
                <div className="child-progress-track">
                  <div
                    className="child-progress-fill"
                    style={{ width: `${child.percentage}%` }}
                  />
                </div>

                {/* نسبة الإنجاز */}
                <span className="child-progress-percent">{child.percentage}%</span>
              </div>

              {/* الجزء السفلي: حالة الطفل */}
              <div className="child-card-bottom">
                <span className="child-status-text">{child.status}</span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* زر عرض المزيد / عرض أقل لتفادي السكرول والحفاظ على تناسق الشاشة */}
      {filteredList.length > INITIAL_LIMIT && (
        <div className="children-load-more-wrapper">
          <button
            id="load-more-children-btn"
            type="button"
            onClick={() => setShowAll((prev) => !prev)}
            className="children-load-more-btn"
          >
            <span>{showAll ? 'عرض أقل' : 'عرض المزيد'}</span>
            <i
              className={`fa-solid ${showAll ? 'fa-chevron-up' : 'fa-chevron-down'}`}
              aria-hidden="true"
            ></i>
          </button>
        </div>
      )}
    </div>
  );
}

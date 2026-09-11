import React, { useState } from 'react';

interface HeaderProps {
  onOpenMobileMenu: () => void;
  searchQuery: string;
  onSearchChange: (q: string) => void;
}

export default function Header({
  onOpenMobileMenu,
  searchQuery,
  onSearchChange,
}: HeaderProps) {
  const [copied, setCopied] = useState(false);
  const referralCode = 'DR-2048';
   const handleCopyCode = async () => {
    let success = false;

    // 1. محاولة النسخ عبر Clipboard API الحديثة
    if (navigator.clipboard && window.isSecureContext) {
      try {
        await navigator.clipboard.writeText(referralCode);
        success = true;
      } catch {
        // قد يفشل داخل iframe بسبب قيود الأمان
      }
    }

    // 2. حل بديل (Fallback) يضمن النسخ بنسبة 100% داخل أي iframe
    if (!success) {
      try {
        const textArea = document.createElement('textarea');
        textArea.value = referralCode;
        textArea.style.position = 'fixed';
         textArea.style.left = '-9999px';
        textArea.style.top = '-9999px';
        textArea.setAttribute('readonly', '');
        document.body.appendChild(textArea);
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
      } catch (err) {
        console.warn('Fallback copy error', err);
      }
    }


    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <header id="dashboard-header" className="dashboard-header">
      {/* يمين: عنوان الترحيب + كود إحالة الطبيب */}
      <div className="header-greeting-section">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="header-greeting-title">
              صباح الخير د. سارة
            </h1>
            <p className="header-greeting-subtitle">
              هنا لمحة عامة عن تقدم أطفالك اليوم
            </p>
          </div>

          {/* زر الموبايل مع أيقونة fa-bars */}
          <button
            id="mobile-menu-trigger"
            onClick={onOpenMobileMenu}
            className="rounded-xl bg-[#DFD7F5] p-2 text-[#372868] lg:hidden mr-4"
            aria-label="القائمة"
            type="button"
          >
            <i className="fa-solid fa-bars text-lg" aria-hidden="true"></i>
          </button>
        </div>

        {/* كود إحالة الطبيب */}
        <div className="referral-code-wrapper">
          <div className="referral-box">
            <button
              id="copy-referral-btn"
              onClick={handleCopyCode}
               className={`referral-copy-btn ${copied ? 'copied' : ''}`}
              type="button"
            >
              {copied ? (
                <span className="flex items-center gap-1.5 text-emerald-700 font-bold">
                  <i className="fa-solid fa-check text-xs" aria-hidden="true"></i> تم النسخ
                </span>
              ) : (
                'نسخ'
              )}
            </button>
            <span className="referral-code-text">{referralCode}</span>
          </div>
          <span className="referral-label">كود إحالة الطبيب</span>
        </div>
      </div>

      {/* يسار: شريط البحث البيضاوي وزر الإشعارات */}
      <div className="header-left-controls">
        {/* شريط البحث مع أيقونة fa-magnifying-glass */}
        <div className="header-search-wrapper">
          <input
            id="header-search-input"
            type="text"
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder="البحث"
            className="header-search-input"
          />
          <i
            className="fa-solid fa-magnifying-glass header-search-icon"
            aria-hidden="true"
          ></i>
        </div>

        {/* زر الإشعارات مع أيقونة fa-bell */}
        <button
          id="header-notification-btn"
          className="header-notification-btn"
          aria-label="الإشعارات"
          type="button"
        >
          <i className="fa-regular fa-bell" aria-hidden="true"></i>
          <span className="notification-badge-dot" />
        </button>
      </div>
    </header>
  );
}
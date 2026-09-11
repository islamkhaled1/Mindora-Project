import React, { useState } from 'react';
import { ChildCardItem } from '../types';

interface ChildDetailViewProps {
  child: ChildCardItem;
  onBack: () => void;
  onOpenMobileMenu?: () => void;
}

interface TherapySkill {
  id: string;
  title: string;
  sessions: string;
  description: string;
  iconClass: string;
  iconBg: string;
  iconColor: string;
}

export default function ChildDetailView({
  child,
  onBack,
  onOpenMobileMenu,
}: ChildDetailViewProps) {
  const [noteText, setNoteText] = useState('');
  const [saveSuccess, setSaveSuccess] = useState(false);

  // كروت خطط العلاج والمهارات الأربعة (مطابقة لـ Dr dashboard (4).png من اليمين لليسار)
  const skills: TherapySkill[] = [
    {
      id: 'communication',
      title: 'التواصل واللغة',
      sessions: '3 جلسات في الأسبوع',
      description: 'تحسين مهارات التواصل والتعبير عن الاحتياجات وفهم اللغة.',
      iconClass: 'fa-solid fa-comment-dots',
      iconBg: '#EDE8F8',
      iconColor: '#362757',
    },
    {
      id: 'motor',
      title: 'المهارات الحركية',
      sessions: '2 جلسات في الأسبوع',
      description: 'تطوير التوازن، التنسيق، والمهارات الحركية الدقيقة والكبيرة.',
      iconClass: 'fa-solid fa-person-running',
      iconBg: '#FFF5E5',
      iconColor: '#F59E0B',
    },
    {
      id: 'cognitive',
      title: 'الإدراك والتعلم',
      sessions: '2 جلسات في الأسبوع',
      description: 'تنمية الانتباه، الذاكرة، وحل المشكلات والاستقلالية في التعلم.',
      iconClass: 'fa-solid fa-brain',
      iconBg: '#E7F7EE',
      iconColor: '#10B981',
    },
    {
      id: 'social',
      title: 'المهارات الاجتماعية والعاطفية',
      sessions: '1 جلسات في الأسبوع',
      description: 'تعزيز التفاعل الاجتماعي، بناء العلاقات، والتعبير عن المشاعر.',
      iconClass: 'fa-solid fa-hand-holding-heart',
      iconBg: '#FDECEF',
      iconColor: '#EF4444',
    },
  ];

  const handleSaveNote = () => {
    if (!noteText.trim()) return;
    setSaveSuccess(true);
    setTimeout(() => {
      setSaveSuccess(false);
      setNoteText('');
    }, 2200);
  };

  return (
    <div id="child-detail-page" className="child-detail-page" dir="rtl">
      {/* 1. زر العودة وتفاصيل بروفايل الطفل بالأعلى */}
      <div className="child-detail-top-bar">
        {/* زر العودة إلى قائمة الأطفال */}
        <div className="flex items-center justify-between w-full">
          <button
            id="back-to-children-btn"
            type="button"
            onClick={onBack}
            className="child-detail-back-btn"
          >
            <i className="fa-solid fa-arrow-right" aria-hidden="true"></i>
            <span>العودة إلى الأطفال</span>
          </button>

          {onOpenMobileMenu && (
            <button
              onClick={onOpenMobileMenu}
              className="rounded-xl bg-[#DFD7F5] p-2 text-[#372868] lg:hidden mr-auto"
              aria-label="القائمة"
              type="button"
            >
              <i className="fa-solid fa-bars text-lg" aria-hidden="true"></i>
            </button>
          )}
        </div>

        {/* كارت تعريف الطفل: الصورة، الاسم والسن، والحالة */}
        <div className="child-detail-profile-header">
          <div className="child-profile-main-info">
            {/* الدائرة الرمادية البنفسجية وبها حرف الطفل */}
            <div className="child-avatar-circle-lg">
              <span>{child.initial}</span>
            </div>

            {/* اسم الطفل وسنه */}
            <div className="child-profile-text">
              <h1 className="child-detail-name">{child.name}</h1>
              <p className="child-detail-meta">{child.age} • ذكر</p>
            </div>
          </div>

          {/* بادج الحالة */}
          <div className="child-detail-status-badge">
            <span>{child.status}</span>
          </div>
        </div>
      </div>

      {/* 2. كروت المهارات وجلسات الأسبوع الأربعة */}
      <div className="therapy-skills-grid">
        {skills.map((skill) => (
          <div key={skill.id} className="therapy-skill-card">
            {/* أيقونة المهارة داخل مربع ناعم بألوان مميزة */}
            <div
              className="skill-icon-wrapper"
              style={{ backgroundColor: skill.iconBg, color: skill.iconColor }}
            >
              <i className={skill.iconClass} aria-hidden="true"></i>
            </div>

            {/* عنوان المهارة */}
            <h3 className="skill-card-title">{skill.title}</h3>

            {/* عدد الجلسات في الأسبوع */}
            <p className="skill-card-sessions">{skill.sessions}</p>

            {/* الوصف والهدف */}
            <p className="skill-card-description">{skill.description}</p>
          </div>
        ))}
      </div>

      {/* 3. قسم الجلسات المكتملة */}
      <div className="completed-sessions-section">
        <h2 className="section-heading">الجلسات المكتملة</h2>
        <div className="completed-sessions-box">
          <i className="fa-regular fa-calendar completed-calendar-icon" aria-hidden="true"></i>
          <h3 className="completed-empty-title">لا توجد جلسات مكتملة بعد</h3>
          <p className="completed-empty-subtitle">
            ستظهر الجلسات المكتملة هنا بعد انتهاء أول جلسة.
          </p>
        </div>
      </div>

      {/* 4. قسم ملاحظات الطبيب */}
      <div className="doctor-notes-section">
        <h2 className="section-heading">ملاحظات الطبيب</h2>
        <div className="doctor-notes-form">
          {/* حقل إدخال الملاحظة */}
          <input
            id="doctor-note-input"
            type="text"
            value={noteText}
            onChange={(e) => setNoteText(e.target.value)}
            placeholder="أضف ملاحظات حول أداء الطفل..."
            className="doctor-notes-input"
          />

          {/* زر حفظ الملاحظة */}
          <button
            id="save-doctor-note-btn"
            type="button"
            onClick={handleSaveNote}
            className={`save-note-btn ${saveSuccess ? 'saved' : ''}`}
          >
            {saveSuccess ? (
              <span className="flex items-center gap-1.5 justify-center">
                <i className="fa-solid fa-check" aria-hidden="true"></i> تم الحفظ
              </span>
            ) : (
              'حفظ الملاحظة'
            )}
          </button>
        </div>
      </div>
    </div>
  );
}

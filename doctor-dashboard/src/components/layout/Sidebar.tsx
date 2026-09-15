import React from 'react';
import {
  Home,
  Users,
  UserPlus,
  ClipboardCheck,
  Calendar,
  MessageSquare,
  BarChart3,
  Settings,
  LogOut,
  KeyRound,
} from 'lucide-react';
import type { DoctorProfile } from '../../types';
import { resolveDoctorAvatar } from '../../utils/doctorAvatarHelper';
import sawaLogo from '../../assets/sawa-logo.png';

export type NavTab = 'dashboard' | 'children' | 'requests' | 'plans' | 'sessions' | 'notes' | 'progress' | 'settings' | 'change-password';

interface SidebarProps {
  currentTab: NavTab;
  onSelectTab: (tab: NavTab) => void;
  doctorProfile: DoctorProfile;
  onLogout?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  onSelectTab,
  doctorProfile,
  onLogout,
}) => {
  const navItems: { key: NavTab; label: string; icon: React.ReactNode; isComingSoon?: boolean }[] = [
    { key: 'dashboard', label: 'الرئيسيه', icon: <Home className="w-5 h-5" /> },
    { key: 'children', label: 'الأطفال', icon: <Users className="w-5 h-5" /> },
    { key: 'requests', label: 'طلبات الربط', icon: <UserPlus className="w-5 h-5" /> },
    { key: 'plans', label: 'خطط العلاج', icon: <ClipboardCheck className="w-5 h-5" />, isComingSoon: true },
    { key: 'sessions', label: 'الجلسات', icon: <Calendar className="w-5 h-5" />, isComingSoon: true },
    { key: 'notes', label: 'التعليقات', icon: <MessageSquare className="w-5 h-5" />, isComingSoon: true },
    { key: 'progress', label: 'التقدم', icon: <BarChart3 className="w-5 h-5" />, isComingSoon: true },
    { key: 'settings', label: 'الإعدادات', icon: <Settings className="w-5 h-5" />, isComingSoon: true },
  ];

  return (
    <aside className="w-64 bg-white border-l border-[#E4D4FF] flex flex-col justify-between p-6 shrink-0 select-none min-h-screen shadow-2xs">
      {/* Top Navigation */}
      <div>
        {/* Brand with Sawa Logo */}
        <div className="mb-8 px-2 flex items-center gap-3">
          <img
            src={sawaLogo}
            alt="Sawa Logo"
            className="h-14 w-auto object-contain drop-shadow-sm hover:scale-105 transition-transform"
          />
          <div className="flex flex-col">
            <h1 className="text-base font-black text-[#432F62] leading-tight">سـوا | SAWA</h1>
            <span className="text-[11px] font-bold text-[#8456D2] bg-[#F0E8FF] px-2 py-0.5 rounded-md mt-1 w-fit border border-[#E4D4FF]">
              لوحة الطبيب
            </span>
          </div>
        </div>

        {/* Navigation List */}
        <nav className="space-y-2">
          {navItems.map((item) => {
            const isActive = currentTab === item.key;
            return (
              <button
                key={item.key}
                onClick={() => onSelectTab(item.key)}
                className={`w-full flex items-center justify-between px-4 py-3 rounded-2xl text-base font-bold transition-all duration-200 cursor-pointer ${
                  isActive
                    ? 'bg-[#F0E8FF] text-[#432F62] border border-[#E4D4FF] shadow-xs'
                    : 'text-[#74728A] hover:bg-[#F3EFFF] hover:text-[#432F62]'
                }`}
              >
                <div className="flex items-center gap-3.5">
                  <span className={isActive ? 'text-[#8456D2]' : 'text-[#74728A]'}>
                    {item.icon}
                  </span>
                  <span>{item.label}</span>
                </div>
                {item.isComingSoon && (
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-md bg-[#F0E8FF] text-[#8456D2] border border-[#E4D4FF]/80">
                    قريباً
                  </span>
                )}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Bottom Profile & Logout */}
      <div className="pt-6 border-t border-[#E4D4FF] space-y-4">
        {/* Doctor Info Pill with Avatar Switcher */}
        <div className="flex items-center gap-3 p-2.5 rounded-2xl bg-[#F7FAFC] border border-[#E4D4FF]/70 hover:bg-[#F0E8FF]/50 transition-all shadow-2xs">
          <div className="relative w-12 h-12 rounded-full border-2 border-[#E4D4FF] shadow-xs overflow-hidden flex items-center justify-center shrink-0 bg-[#F0E8FF]">
            <img
              src={doctorProfile.avatarUrl || resolveDoctorAvatar(doctorProfile.gender)}
              alt={doctorProfile.name}
              className="w-full h-full object-cover"
              onError={(e) => {
                e.currentTarget.src = resolveDoctorAvatar(doctorProfile.gender);
              }}
            />
          </div>
          <div className="min-w-0 flex-1 text-right">
            <h4 className="text-sm font-bold text-[#432F62] truncate">{doctorProfile.name}</h4>
            <p className="text-[11px] font-medium text-[#74728A] truncate leading-tight mt-0.5">
              {doctorProfile.specialization}
            </p>
          </div>
        </div>

        {/* Change Password Button */}
        <button
          onClick={() => onSelectTab('change-password')}
          className={`w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-bold transition-colors cursor-pointer ${
            currentTab === 'change-password'
              ? 'bg-[#F0E8FF] text-[#8456D2] border border-[#E4D4FF]'
              : 'text-[#74728A] hover:text-[#432F62] hover:bg-[#F3EFFF]'
          }`}
        >
          <KeyRound className="w-4 h-4 text-[#8456D2]" />
          <span>تغيير كلمة المرور</span>
        </button>

        {/* Logout Button */}
        <button
          onClick={onLogout}
          className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-bold text-[#74728A] hover:text-[#BD3737] hover:bg-[#FFD4CA]/30 transition-colors cursor-pointer"
        >
          <LogOut className="w-5 h-5" />
          <span>تسجيل الخروج</span>
        </button>
      </div>
    </aside>
  );
};

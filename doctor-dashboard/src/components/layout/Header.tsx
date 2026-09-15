import React, { useState } from 'react';
import { Search, Bell, Copy, Check, QrCode, X } from 'lucide-react';
import type { DoctorProfile } from '../../types';
import { resolveDoctorAvatar } from '../../utils/doctorAvatarHelper';
import { DoctorReferralQr } from '../common/DoctorReferralQr';

interface HeaderProps {
  title?: string;
  subtitle?: string;
  doctorProfile: DoctorProfile;
  searchValue?: string;
  onSearchChange?: (value: string) => void;
  showSearch?: boolean;
}

export const Header: React.FC<HeaderProps> = ({
  title = 'صباح الخير',
  subtitle = 'هنا لمحة عامة عن تقدم أطفالك اليوم',
  doctorProfile,
  searchValue = '',
  onSearchChange,
  showSearch = true,
}) => {
  const [copied, setCopied] = useState(false);
  const [showQrModal, setShowQrModal] = useState(false);
  const [showNotificationToast, setShowNotificationToast] = useState(false);

  const handleCopyCode = () => {
    if (!doctorProfile.referralCode) return;
    navigator.clipboard.writeText(doctorProfile.referralCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleNotificationClick = () => {
    setShowNotificationToast(true);
    setTimeout(() => setShowNotificationToast(false), 3500);
  };

  return (
    <>
      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
        {/* Right Side: Title & Subtitle (RTL) */}
        <div>
          <h2 className="text-2xl font-black text-[#432F62] tracking-tight">{title}</h2>
          <p className="text-sm font-semibold text-[#74728A] mt-1">{subtitle}</p>
        </div>

        {/* Left Side: Referral Code + Search + Notification */}
        <div className="flex items-center gap-3 self-start md:self-auto flex-wrap sm:flex-nowrap relative">
          {/* Doctor Referral Code with Copy & QR Action */}
          {doctorProfile.referralCode ? (
            <div className="flex items-center gap-2 px-3.5 py-2 bg-[#F0E8FF] border border-[#E4D4FF] rounded-2xl text-xs font-bold text-[#432F62] shadow-xs">
              <span className="text-[#74728A]">كود الإحالة:</span>
              <span className="tracking-wider font-mono text-sm font-extrabold text-[#8456D2]">
                {doctorProfile.referralCode}
              </span>
              <button
                onClick={handleCopyCode}
                title="نسخ كود الإحالة"
                className="p-1 hover:bg-[#E4D4FF] rounded-lg transition-colors cursor-pointer text-[#8456D2]"
                aria-label="نسخ كود الإحالة"
              >
                {copied ? <Check className="w-3.5 h-3.5 text-[#6DAA60]" /> : <Copy className="w-3.5 h-3.5" />}
              </button>
              <button
                onClick={() => setShowQrModal(true)}
                title="عرض رمز QR لربط الطفل"
                className="p-1 hover:bg-[#E4D4FF] rounded-lg transition-colors cursor-pointer text-[#8456D2]"
                aria-label="عرض رمز QR"
              >
                <QrCode className="w-3.5 h-3.5" />
              </button>
              {copied && (
                <span className="text-[11px] text-[#6DAA60] font-bold">تم النسخ!</span>
              )}
            </div>
          ) : (
            <div className="flex items-center gap-2 px-3.5 py-2 bg-[#F7FAFC] border border-[#E4D4FF] rounded-2xl text-xs font-bold text-[#74728A]">
              <span>جاري تحميل كود الإحالة...</span>
            </div>
          )}

          {/* Search Capsule Input */}
          {showSearch && (
            <div className="relative w-48 sm:w-64">
              <input
                type="text"
                value={searchValue}
                onChange={(e) => onSearchChange?.(e.target.value)}
                placeholder="البحث"
                className="w-full bg-[#F0E8FF]/60 hover:bg-[#F0E8FF] focus:bg-white text-sm text-[#432F62] placeholder-[#74728A] pl-4 pr-10 py-2.5 rounded-full border border-[#E4D4FF] focus:border-[#8456D2] focus:outline-none transition-all shadow-xs font-medium"
              />
              <Search className="w-4 h-4 text-[#74728A] absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            </div>
          )}

          {/* Notification Bell */}
          <div className="relative">
            <button
              onClick={handleNotificationClick}
              className="relative w-11 h-11 bg-[#F0E8FF] hover:bg-[#E4D4FF] rounded-2xl flex items-center justify-center text-[#8456D2] transition-colors cursor-pointer shadow-xs border border-[#E4D4FF]"
              title="الإشعارات"
              aria-label="الإشعارات"
            >
              <Bell className="w-5 h-5" />
            </button>

            {/* Notification Popover Toast */}
            {showNotificationToast && (
              <div className="absolute left-0 top-12 z-30 w-56 p-3 bg-white border border-[#E4D4FF] rounded-2xl shadow-lg text-xs font-bold text-[#432F62] text-center animate-fade-in">
                لا توجد إشعارات أو تنبيهات سريرية جديدة حالياً
              </div>
            )}
          </div>

          {/* Doctor Identity Pill (consistent with Sidebar) */}
          <div className="flex items-center gap-2.5 px-3 py-1.5 bg-white border border-[#E4D4FF] rounded-2xl shadow-2xs">
            <div className="w-8 h-8 rounded-full border border-[#E4D4FF] overflow-hidden shrink-0 bg-[#F0E8FF] flex items-center justify-center">
              <img
                src={doctorProfile.avatarUrl || resolveDoctorAvatar(doctorProfile.gender)}
                alt={doctorProfile.name}
                className="w-full h-full object-cover"
                onError={(e) => {
                  e.currentTarget.src = resolveDoctorAvatar(doctorProfile.gender);
                }}
              />
            </div>
            <div className="hidden sm:flex flex-col text-right">
              <span className="text-xs font-bold text-[#432F62] leading-tight truncate max-w-[140px]">
                {doctorProfile.name}
              </span>
              <span className="text-[10px] text-[#74728A] font-medium leading-tight truncate max-w-[140px]">
                {doctorProfile.specialization}
              </span>
            </div>
          </div>
        </div>
      </header>

      {/* QR Referral Code Modal */}
      {showQrModal && doctorProfile.referralCode && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-xs p-4 animate-fade-in"
          onClick={() => setShowQrModal(false)}
        >
          <div
            className="relative bg-white rounded-3xl p-6 max-w-sm w-full shadow-2xl border border-[#E4D4FF]"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onClick={() => setShowQrModal(false)}
              className="absolute top-4 left-4 p-1.5 rounded-xl hover:bg-[#F0E8FF] text-[#74728A] hover:text-[#432F62] transition-colors cursor-pointer"
              title="إغلاق"
              aria-label="إغلاق نافذة رمز QR"
            >
              <X className="w-5 h-5" />
            </button>
            <DoctorReferralQr
              referralCode={doctorProfile.referralCode}
              size={200}
              showCard={false}
              showActions={true}
            />
          </div>
        </div>
      )}
    </>
  );
};

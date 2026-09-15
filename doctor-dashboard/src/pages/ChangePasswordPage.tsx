import React, { useState } from 'react';
import { Lock, AlertCircle, Loader2, Eye, EyeOff, CheckCircle2, XCircle, ArrowRight, ShieldAlert, KeyRound } from 'lucide-react';
import { authApi } from '../api/authApi';

interface ChangePasswordPageProps {
  onBack?: () => void;
}

export const ChangePasswordPage: React.FC<ChangePasswordPageProps> = ({ onBack }) => {
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Requirements check
  const hasMinLength = newPassword.length >= 8;
  const hasDigit = /\d/.test(newPassword);
  const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(newPassword);
  const passwordsMatch = newPassword.length > 0 && newPassword === confirmPassword;

  const isFormValid = currentPassword.length > 0 && hasMinLength && hasDigit && hasSpecialChar && passwordsMatch;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccessMessage(null);

    if (!currentPassword.trim()) {
      setError('يرجى إدخال كلمة المرور الحالية.');
      return;
    }

    if (!isFormValid) {
      if (!passwordsMatch) {
        setError('كلمتا المرور الجديدتان غير متطابقتين.');
      } else {
        setError('يرجى استيفاء كافة شروط كلمة المرور الجديدة.');
      }
      return;
    }

    try {
      setLoading(true);
      const res = await authApi.changePassword(currentPassword, newPassword, confirmPassword);
      setSuccessMessage(res.message || 'تم تغيير كلمة المرور بنجاح.');
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message || 'فشل تغيير كلمة المرور، يرجى التأكد من كلمة المرور الحالية.');
      } else {
        setError('تعذر الاتصال بالخادم، يرجى المحاولة لاحقاً.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto space-y-6 animate-fade-in" dir="rtl">
      {/* Top action / back link */}
      {onBack && (
        <button
          onClick={onBack}
          className="inline-flex items-center gap-2 text-xs font-bold text-[#74728A] hover:text-[#432F62] transition-colors cursor-pointer"
        >
          <ArrowRight className="w-4 h-4" />
          <span>العودة إلى لوحة التحكم</span>
        </button>
      )}

      {/* Main Card */}
      <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 sm:p-8 shadow-xs">
        {/* Header */}
        <div className="flex items-center gap-3.5 mb-6 pb-6 border-b border-[#F0E8FF]">
          <div className="w-12 h-12 rounded-2xl bg-[#F0E8FF] border border-[#E4D4FF] text-[#8456D2] flex items-center justify-center shrink-0">
            <KeyRound className="w-6 h-6" />
          </div>
          <div className="text-right">
            <h2 className="text-xl sm:text-2xl font-black text-[#432F62]">تغيير كلمة المرور</h2>
            <p className="text-xs sm:text-sm font-semibold text-[#74728A] mt-0.5">
              قم بتحديث كلمة المرور لحسابك الطبي لضمان أعلى معايير الأمان والخصوصية
            </p>
          </div>
        </div>

        {/* Alerts */}
        {error && (
          <div className="mb-6 p-4 rounded-2xl bg-[#FFD4CA]/50 border border-[#BD3737]/30 flex items-start gap-3 text-right">
            <AlertCircle className="w-5 h-5 text-[#BD3737] shrink-0 mt-0.5" />
            <div className="flex-1 text-xs sm:text-sm font-bold text-[#BD3737] leading-relaxed">
              {error}
            </div>
          </div>
        )}

        {successMessage && (
          <div className="mb-6 p-4 rounded-2xl bg-[#EEF3EE] border border-[#6DAA60]/30 flex items-start gap-3 text-right">
            <div className="w-5 h-5 rounded-full bg-[#6DAA60] text-white flex items-center justify-center shrink-0 mt-0.5 text-xs font-black">
              ✓
            </div>
            <div className="flex-1 text-xs sm:text-sm font-bold text-[#6DAA60] leading-relaxed">
              {successMessage}
            </div>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Current Password */}
          <div>
            <label className="block text-xs font-bold text-[#432F62] mb-1.5 text-right">
              كلمة المرور الحالية
            </label>
            <div className="relative">
              <input
                type={showCurrentPassword ? 'text' : 'password'}
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                placeholder="••••••••"
                required
                disabled={loading}
                className="w-full bg-[#F7FAFC] focus:bg-white text-sm text-[#432F62] placeholder-[#74728A] pl-11 pr-11 py-3 rounded-2xl border border-[#E4D4FF] focus:border-[#8456D2] focus:outline-none transition-all font-medium text-right"
              />
              <Lock className="w-5 h-5 text-[#74728A] absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
              <button
                type="button"
                onClick={() => setShowCurrentPassword(!showCurrentPassword)}
                className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#74728A] hover:text-[#432F62] p-1 transition-colors cursor-pointer"
              >
                {showCurrentPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {/* New Password */}
            <div>
              <label className="block text-xs font-bold text-[#432F62] mb-1.5 text-right">
                كلمة المرور الجديدة
              </label>
              <div className="relative">
                <input
                  type={showNewPassword ? 'text' : 'password'}
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  disabled={loading}
                  className="w-full bg-[#F7FAFC] focus:bg-white text-sm text-[#432F62] placeholder-[#74728A] pl-11 pr-11 py-3 rounded-2xl border border-[#E4D4FF] focus:border-[#8456D2] focus:outline-none transition-all font-medium text-right"
                />
                <Lock className="w-5 h-5 text-[#74728A] absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                <button
                  type="button"
                  onClick={() => setShowNewPassword(!showNewPassword)}
                  className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#74728A] hover:text-[#432F62] p-1 transition-colors cursor-pointer"
                >
                  {showNewPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {/* Confirm Password */}
            <div>
              <label className="block text-xs font-bold text-[#432F62] mb-1.5 text-right">
                تأكيد كلمة المرور الجديدة
              </label>
              <div className="relative">
                <input
                  type={showConfirmPassword ? 'text' : 'password'}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  disabled={loading}
                  className="w-full bg-[#F7FAFC] focus:bg-white text-sm text-[#432F62] placeholder-[#74728A] pl-11 pr-11 py-3 rounded-2xl border border-[#E4D4FF] focus:border-[#8456D2] focus:outline-none transition-all font-medium text-right"
                />
                <Lock className="w-5 h-5 text-[#74728A] absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                <button
                  type="button"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#74728A] hover:text-[#432F62] p-1 transition-colors cursor-pointer"
                >
                  {showConfirmPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>
          </div>

          {/* Checklist */}
          <div className="p-4 rounded-2xl bg-[#F7FAFC] border border-[#E4D4FF] space-y-2.5 text-right">
            <p className="text-xs font-bold text-[#432F62]">شروط كلمة المرور الجديدة:</p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs font-medium">
              <div className={`flex items-center gap-2 ${hasMinLength ? 'text-[#6DAA60]' : 'text-[#74728A]'}`}>
                {hasMinLength ? <CheckCircle2 className="w-4 h-4 shrink-0" /> : <XCircle className="w-4 h-4 shrink-0" />}
                <span>8 أحرف على الأقل</span>
              </div>
              <div className={`flex items-center gap-2 ${hasDigit ? 'text-[#6DAA60]' : 'text-[#74728A]'}`}>
                {hasDigit ? <CheckCircle2 className="w-4 h-4 shrink-0" /> : <XCircle className="w-4 h-4 shrink-0" />}
                <span>رقم واحد على الأقل (0-9)</span>
              </div>
              <div className={`flex items-center gap-2 ${hasSpecialChar ? 'text-[#6DAA60]' : 'text-[#74728A]'}`}>
                {hasSpecialChar ? <CheckCircle2 className="w-4 h-4 shrink-0" /> : <XCircle className="w-4 h-4 shrink-0" />}
                <span>رمز خاص واحد على الأقل (!@#$%)</span>
              </div>
              <div className={`flex items-center gap-2 ${passwordsMatch ? 'text-[#6DAA60]' : 'text-[#74728A]'}`}>
                {passwordsMatch ? <CheckCircle2 className="w-4 h-4 shrink-0" /> : <XCircle className="w-4 h-4 shrink-0" />}
                <span>تطابق كلمة المرور الجديدة</span>
              </div>
            </div>
          </div>

          {/* Security Notice */}
          <div className="p-3.5 rounded-2xl bg-[#FFF5F2] border border-[#FFD4CA] flex items-start gap-2.5 text-right">
            <ShieldAlert className="w-4 h-4 text-[#BD3737] shrink-0 mt-0.5" />
            <p className="text-[11px] font-semibold text-[#BD3737] leading-relaxed">
              عند تغيير كلمة المرور، سيتم إنهاء أي جلسات نشطة سابقة على أجهزة أخرى لضمان أمان حسابك.
            </p>
          </div>

          {/* Submit */}
          <div className="pt-2 flex items-center justify-end gap-3">
            {onBack && (
              <button
                type="button"
                onClick={onBack}
                disabled={loading}
                className="px-5 py-3 rounded-2xl bg-[#F0E8FF] hover:bg-[#E4D4FF] text-[#432F62] text-xs font-bold transition-colors cursor-pointer border border-[#E4D4FF]"
              >
                إلغاء
              </button>
            )}
            <button
              type="submit"
              disabled={loading || !isFormValid}
              className="py-3 px-6 rounded-2xl bg-[#8456D2] hover:bg-[#7243C6] text-white text-xs sm:text-sm font-bold transition-all shadow-xs hover:shadow-md cursor-pointer flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>جاري تحديث كلمة المرور...</span>
                </>
              ) : (
                <span>تحديث كلمة المرور</span>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

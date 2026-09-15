import React, { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Lock, AlertCircle, Loader2, Eye, EyeOff, CheckCircle2, XCircle, ArrowRight, Check } from 'lucide-react';
import sawaLogo from '../assets/sawa-logo.png';
import { authApi } from '../api/authApi';

interface LocationState {
  email?: string;
  resetToken?: string;
}

export const ResetPasswordPage: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();

  const state = location.state as LocationState | null;
  const resetToken = state?.resetToken;

  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSuccess, setIsSuccess] = useState(false);

  // Requirement checks for client-side UX
  const hasMinLength = newPassword.length >= 8;
  const hasDigit = /\d/.test(newPassword);
  const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(newPassword);
  const passwordsMatch = newPassword.length > 0 && newPassword === confirmPassword;

  const isFormValid = hasMinLength && hasDigit && hasSpecialChar && passwordsMatch;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!resetToken) {
      setError('رمز إعادة التعيين مفقود أو منتهي الصلاحية، يرجى طلب رمز تحقق جديد.');
      return;
    }

    if (!isFormValid) {
      if (!passwordsMatch) {
        setError('كلمتا المرور غير متطابقتين.');
      } else {
        setError('يرجى التأكد من استيفاء كافة متطلبات كلمة المرور.');
      }
      return;
    }

    try {
      setLoading(true);
      await authApi.resetPassword(resetToken, newPassword, confirmPassword);
      setIsSuccess(true);
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message || 'فشل إعادة تعيين كلمة المرور، يرجى التحقق والبدء من جديد.');
      } else {
        setError('تعذر الاتصال بالخادم، يرجى المحاولة مرة أخرى.');
      }
    } finally {
      setLoading(false);
    }
  };

  // Guard: If accessed directly without token
  if (!resetToken && !isSuccess) {
    return (
      <div className="min-h-screen bg-[#F7FAFC] flex flex-col justify-center items-center p-4 sm:p-6" dir="rtl">
        <div className="w-full max-w-md bg-white rounded-3xl border border-[#E4D4FF] p-8 text-center shadow-sm">
          <div className="w-14 h-14 rounded-2xl bg-[#FFF5F2] border border-[#FFD4CA] text-[#BD3737] flex items-center justify-center mx-auto mb-4">
            <AlertCircle className="w-7 h-7" />
          </div>
          <h2 className="text-xl font-black text-[#432F62] mb-2">انتهت صلاحية جلسة إعادة التعيين</h2>
          <p className="text-xs sm:text-sm text-[#74728A] font-medium mb-6 leading-relaxed">
            لأسباب أمنية، لا يمكن الوصول إلى هذه الصفحة دون التحقق المسبق من رمز الـ OTP.
          </p>
          <button
            onClick={() => navigate('/forgot-password')}
            className="w-full py-3 px-6 rounded-2xl bg-[#8456D2] hover:bg-[#7243C6] text-white text-xs sm:text-sm font-bold transition-all shadow-xs cursor-pointer"
          >
            العودة إلى استعادة كلمة المرور
          </button>
        </div>
      </div>
    );
  }

  // Success view
  if (isSuccess) {
    return (
      <div className="min-h-screen bg-[#F7FAFC] flex flex-col justify-center items-center p-4 sm:p-6" dir="rtl">
        <div className="w-full max-w-md bg-white rounded-3xl border border-[#E4D4FF] p-8 text-center shadow-sm">
          <div className="w-16 h-16 rounded-full bg-[#EEF3EE] border-2 border-[#6DAA60] text-[#6DAA60] flex items-center justify-center mx-auto mb-5 shadow-xs">
            <Check className="w-8 h-8 stroke-[3]" />
          </div>
          <h2 className="text-2xl font-black text-[#432F62] mb-2">تم تعيين كلمة المرور بنجاح!</h2>
          <p className="text-xs sm:text-sm text-[#74728A] font-medium mb-6 leading-relaxed">
            تم تحديث كلمة المرور الخاصة بحسابك في منصة سوا بنجاح. يمكنك الآن تسجيل الدخول مباشرة بالبيانات الجديدة.
          </p>
          <button
            onClick={() => navigate('/login', { replace: true })}
            className="w-full py-3.5 px-6 rounded-2xl bg-[#8456D2] hover:bg-[#7243C6] text-white text-sm font-bold transition-all shadow-xs hover:shadow-md cursor-pointer flex items-center justify-center gap-2"
          >
            <span>تسجيل الدخول إلى لوحة التحكم</span>
            <ArrowRight className="w-4 h-4 rotate-180" />
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F7FAFC] flex flex-col justify-center items-center p-4 sm:p-6" dir="rtl">
      {/* Ambient background glows */}
      <div className="fixed top-0 left-1/4 w-96 h-96 bg-[#E4D4FF]/40 rounded-full blur-3xl pointer-events-none -z-10" />
      <div className="fixed bottom-0 right-1/4 w-96 h-96 bg-[#F0E8FF]/60 rounded-full blur-3xl pointer-events-none -z-10" />

      <div className="w-full max-w-md">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center p-3 bg-white rounded-3xl border border-[#E4D4FF] shadow-xs mb-4">
            <img src={sawaLogo} alt="Sawa Logo" className="h-12 w-auto object-contain" />
          </div>
          <div className="flex items-center justify-center gap-2 mb-2">
            <span className="px-3 py-1 bg-[#F0E8FF] border border-[#E4D4FF] rounded-full text-xs font-black text-[#8456D2] inline-flex items-center gap-1.5">
              <Lock className="w-3.5 h-3.5" />
              <span>تعيين كلمة المرور</span>
            </span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black text-[#432F62]">كلمة المرور الجديدة</h1>
          <p className="text-xs sm:text-sm font-semibold text-[#74728A] mt-1">
            أنشئ كلمة مرور قوية لتأمين حسابك الطبي في منصة سوا
          </p>
        </div>

        {/* Form Card */}
        <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 sm:p-8 shadow-sm">
          {error && (
            <div className="mb-6 p-4 rounded-2xl bg-[#FFD4CA]/50 border border-[#BD3737]/30 flex items-start gap-3 text-right">
              <AlertCircle className="w-5 h-5 text-[#BD3737] shrink-0 mt-0.5" />
              <div className="flex-1 text-xs sm:text-sm font-bold text-[#BD3737] leading-relaxed">
                {error}
              </div>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
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

            {/* Password Requirements Checklist */}
            <div className="p-3.5 rounded-2xl bg-[#F7FAFC] border border-[#E4D4FF] space-y-2 text-right">
              <p className="text-[11px] font-bold text-[#432F62]">شروط كلمة المرور:</p>
              <div className="grid grid-cols-2 gap-2 text-[11px] font-medium">
                <div className={`flex items-center gap-1.5 ${hasMinLength ? 'text-[#6DAA60]' : 'text-[#74728A]'}`}>
                  {hasMinLength ? <CheckCircle2 className="w-3.5 h-3.5 shrink-0" /> : <XCircle className="w-3.5 h-3.5 shrink-0" />}
                  <span>8 أحرف على الأقل</span>
                </div>
                <div className={`flex items-center gap-1.5 ${hasDigit ? 'text-[#6DAA60]' : 'text-[#74728A]'}`}>
                  {hasDigit ? <CheckCircle2 className="w-3.5 h-3.5 shrink-0" /> : <XCircle className="w-3.5 h-3.5 shrink-0" />}
                  <span>رقم واحد على الأقل</span>
                </div>
                <div className={`flex items-center gap-1.5 ${hasSpecialChar ? 'text-[#6DAA60]' : 'text-[#74728A]'}`}>
                  {hasSpecialChar ? <CheckCircle2 className="w-3.5 h-3.5 shrink-0" /> : <XCircle className="w-3.5 h-3.5 shrink-0" />}
                  <span>رمز خاص (!@#$)</span>
                </div>
                <div className={`flex items-center gap-1.5 ${passwordsMatch ? 'text-[#6DAA60]' : 'text-[#74728A]'}`}>
                  {passwordsMatch ? <CheckCircle2 className="w-3.5 h-3.5 shrink-0" /> : <XCircle className="w-3.5 h-3.5 shrink-0" />}
                  <span>تطابق كلمتي المرور</span>
                </div>
              </div>
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={loading || !isFormValid}
              className="w-full mt-3 py-3.5 px-6 rounded-2xl bg-[#8456D2] hover:bg-[#7243C6] text-white text-sm font-bold transition-all shadow-xs hover:shadow-md cursor-pointer flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>جاري تعيين كلمة المرور...</span>
                </>
              ) : (
                <span>حفظ كلمة المرور الجديدة</span>
              )}
            </button>
          </form>

          {/* Back button */}
          <div className="mt-5 pt-4 border-t border-[#F0E8FF] text-center">
            <button
              type="button"
              onClick={() => navigate('/login')}
              className="inline-flex items-center gap-1.5 text-xs font-bold text-[#74728A] hover:text-[#432F62] transition-colors cursor-pointer"
            >
              <ArrowRight className="w-4 h-4" />
              <span>إلغاء والعودة لتسجيل الدخول</span>
            </button>
          </div>
        </div>

        {/* Footer info */}
        <p className="text-center text-xs text-[#74728A] font-medium mt-6">
          Mindora Platform • بوابة أطباء التأهيل السريري 2026
        </p>
      </div>
    </div>
  );
};

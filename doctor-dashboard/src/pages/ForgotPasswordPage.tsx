import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, AlertCircle, Loader2, ArrowRight, KeyRound } from 'lucide-react';
import sawaLogo from '../assets/sawa-logo.png';
import { authApi } from '../api/authApi';

export const ForgotPasswordPage: React.FC = () => {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccessMessage(null);

    const trimmedEmail = email.trim();
    if (!trimmedEmail) {
      setError('يرجى إدخال البريد الإلكتروني.');
      return;
    }

    try {
      setLoading(true);
      const res = await authApi.forgotPassword(trimmedEmail);

      if (res.status === 'WrongPlatform') {
        setError(res.message || 'هذا الحساب مسجل على SAWA APP.\nلاستعادة كلمة المرور، يرجى استخدام تطبيق SAWA APP.');
        return;
      }

      setSuccessMessage(res.message || 'إذا كان البريد الإلكتروني مسجلاً، سيتم إرسال رمز التحقق.');

      // Brief delay to allow reading the anti-enumeration feedback, then navigate to OTP step
      setTimeout(() => {
        navigate('/verify-otp', {
          state: { email: trimmedEmail },
          replace: false,
        });
      }, 1000);
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message || 'تعذر إرسال رمز التحقق، يرجى المحاولة مرة أخرى.');
      } else {
        setError('تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F7FAFC] flex flex-col justify-center items-center p-4 sm:p-6" dir="rtl">
      {/* Ambient background glows */}
      <div className="fixed top-0 left-1/4 w-96 h-96 bg-[#E4D4FF]/40 rounded-full blur-3xl pointer-events-none -z-10" />
      <div className="fixed bottom-0 right-1/4 w-96 h-96 bg-[#F0E8FF]/60 rounded-full blur-3xl pointer-events-none -z-10" />

      <div className="w-full max-w-md">
        {/* Logo and Brand Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center p-3 bg-white rounded-3xl border border-[#E4D4FF] shadow-xs mb-4">
            <img src={sawaLogo} alt="Sawa Logo" className="h-12 w-auto object-contain" />
          </div>
          <div className="flex items-center justify-center gap-2 mb-2">
            <span className="px-3 py-1 bg-[#F0E8FF] border border-[#E4D4FF] rounded-full text-xs font-black text-[#8456D2] inline-flex items-center gap-1.5">
              <KeyRound className="w-3.5 h-3.5" />
              <span>استعادة كلمة المرور</span>
            </span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black text-[#432F62]">نسيت كلمة المرور؟</h1>
          <p className="text-sm font-semibold text-[#74728A] mt-1">
            أدخل بريدك الإلكتروني المسجل وسنرسل لك رمز التحقق المكون من 6 أرقام.
          </p>
        </div>

        {/* Form Card */}
        <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 sm:p-8 shadow-sm">
          {error && (
            <div className="mb-6 p-4 rounded-2xl bg-[#FFD4CA]/50 border border-[#BD3737]/30 flex items-start gap-3 text-right">
              <AlertCircle className="w-5 h-5 text-[#BD3737] shrink-0 mt-0.5" />
              <div className="flex-1 text-xs sm:text-sm font-bold text-[#BD3737] leading-relaxed whitespace-pre-line">
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
            <div>
              <label className="block text-xs font-bold text-[#432F62] mb-2 text-right">
                البريد الإلكتروني المسجل
              </label>
              <div className="relative">
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="doctor@mindora.com"
                  required
                  disabled={loading}
                  className="w-full bg-[#F7FAFC] focus:bg-white text-sm text-[#432F62] placeholder-[#74728A] pl-4 pr-11 py-3 rounded-2xl border border-[#E4D4FF] focus:border-[#8456D2] focus:outline-none transition-all font-medium text-right"
                />
                <Mail className="w-5 h-5 text-[#74728A] absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full mt-2 py-3.5 px-6 rounded-2xl bg-[#8456D2] hover:bg-[#7243C6] text-white text-sm font-bold transition-all shadow-xs hover:shadow-md cursor-pointer flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>جاري إرسال رمز التحقق...</span>
                </>
              ) : (
                <span>إرسال رمز التحقق</span>
              )}
            </button>
          </form>

          {/* Back to Login */}
          <div className="mt-5 pt-4 border-t border-[#F0E8FF] text-center">
            <button
              type="button"
              onClick={() => navigate('/login')}
              className="inline-flex items-center gap-1.5 text-xs font-bold text-[#8456D2] hover:text-[#432F62] transition-colors cursor-pointer"
            >
              <ArrowRight className="w-4 h-4" />
              <span>العودة إلى تسجيل الدخول</span>
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

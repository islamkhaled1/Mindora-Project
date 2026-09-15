import React, { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Lock, Mail, AlertCircle, CheckCircle2, Loader2, Eye, EyeOff, Stethoscope } from 'lucide-react';
import sawaLogo from '../assets/sawa-logo.png';
import { authApi } from '../api/authApi';
import type { CurrentUserDto } from '../api/types';

interface LoginPageProps {
  onLoginSuccess: (user: CurrentUserDto, token: string) => void;
  sessionExpiredMessage?: string | null;
  onNavigateToRegister?: () => void;
  onNavigateToForgotPassword?: () => void;
}

export const LoginPage: React.FC<LoginPageProps> = ({
  onLoginSuccess,
  sessionExpiredMessage,
  onNavigateToRegister,
  onNavigateToForgotPassword,
}) => {
  const location = useLocation();
  const navigate = useNavigate();
  const locationState = location.state as { verifiedEmail?: string; notification?: string } | null;

  const [email, setEmail] = useState(() => locationState?.verifiedEmail || (import.meta.env.DEV ? 'doctor@mindora.com' : ''));
  const [password, setPassword] = useState(import.meta.env.DEV ? 'Doctor123!' : '');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(sessionExpiredMessage || null);
  const [notification] = useState<string | null>(locationState?.notification || null);
  const [unconfirmedEmail, setUnconfirmedEmail] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!email.trim() || !password.trim()) {
      setError('يرجى إدخال البريد الإلكتروني وكلمة المرور.');
      return;
    }

    try {
      setLoading(true);
      const authRes = await authApi.login({
        email: email.trim(),
        password: password.trim(),
      });

      // Fetch user profile and verify Doctor role
      const me = await authApi.getMe();
      if (me.role !== 'Doctor') {
        authApi.logout();
        setError('عذراً، هذا الحساب ليس لديه صلاحية الوصول إلى لوحة تحكم الطبيب.');
        setLoading(false);
        return;
      }

      if (authRes.token) {
        onLoginSuccess(me, authRes.token);
      } else {
        setError('تعذر استلام رمز المصادقة من الخادم.');
      }
    } catch (err: unknown) {
      if (err instanceof Error) {
        const msg = err.message || '';
        if (msg.includes('تأكيد البريد') || msg.includes('تأكيد حسابك') || msg.includes('EmailNotConfirmed')) {
          setError(msg);
          setUnconfirmedEmail(email.trim());
        } else {
          setError(msg || 'فشل تسجيل الدخول. يرجى التحقق من البيانات والمحاولة مجدداً.');
          setUnconfirmedEmail(null);
        }
      } else {
        setError('تعذر الاتصال بالخادم، يرجى المحاولة مرة أخرى.');
        setUnconfirmedEmail(null);
      }
    } finally {
      setLoading(false);
    }
  };

  const handleQuickFill = (demoEmail: string, demoPass: string) => {
    setEmail(demoEmail);
    setPassword(demoPass);
    setError(null);
    setUnconfirmedEmail(null);
  };

  return (
    <div className="min-h-screen bg-[#F7FAFC] flex flex-col justify-center items-center p-4 sm:p-6" dir="rtl">
      {/* Decorative ambient background glows */}
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
              <Stethoscope className="w-3.5 h-3.5" />
              <span>لوحة تحكم الطبيب والمختص</span>
            </span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black text-[#432F62]">تسجيل الدخول</h1>
          <p className="text-sm font-semibold text-[#74728A] mt-1">
            مرحباً بك مجدداً في منصة سوا لمتابعة التأهيل النمائي للأطفال
          </p>
        </div>

        {/* Login Card */}
        <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 sm:p-8 shadow-sm">
          {notification && (
            <div className="mb-6 p-4 rounded-2xl bg-[#E6F8F0] border border-[#10B981]/30 flex items-start gap-3 text-right">
              <CheckCircle2 className="w-5 h-5 text-[#10B981] shrink-0 mt-0.5" />
              <div className="flex-1 text-xs sm:text-sm font-bold text-[#065F46] leading-relaxed">
                {notification}
              </div>
            </div>
          )}

          {error && (
            <div className="mb-6 p-4 rounded-2xl bg-[#FFD4CA]/50 border border-[#BD3737]/30 flex items-start gap-3 text-right">
              <AlertCircle className="w-5 h-5 text-[#BD3737] shrink-0 mt-0.5" />
              <div className="flex-1 text-xs sm:text-sm font-bold text-[#BD3737] leading-relaxed">
                <div>{error}</div>
                {unconfirmedEmail && (
                  <button
                    type="button"
                    onClick={() => navigate('/verify-email', { state: { email: unconfirmedEmail } })}
                    className="mt-2 text-xs font-black underline text-[#BD3737] hover:text-[#8456D2] cursor-pointer block"
                  >
                    الانتقال لتأكيد البريد الإلكتروني الآن ←
                  </button>
                )}
              </div>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Email Field */}
            <div>
              <label className="block text-xs font-bold text-[#432F62] mb-2 text-right">
                البريد الإلكتروني
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

            {/* Password Field */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="block text-xs font-bold text-[#432F62] text-right">
                  كلمة المرور
                </label>
                {onNavigateToForgotPassword && (
                  <button
                    type="button"
                    onClick={onNavigateToForgotPassword}
                    className="text-xs font-bold text-[#8456D2] hover:text-[#7243C6] transition-colors cursor-pointer"
                  >
                    نسيت كلمة المرور؟
                  </button>
                )}
              </div>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  disabled={loading}
                  className="w-full bg-[#F7FAFC] focus:bg-white text-sm text-[#432F62] placeholder-[#74728A] pl-11 pr-11 py-3 rounded-2xl border border-[#E4D4FF] focus:border-[#8456D2] focus:outline-none transition-all font-medium text-right"
                />
                <Lock className="w-5 h-5 text-[#74728A] absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#74728A] hover:text-[#432F62] p-1 transition-colors cursor-pointer"
                  title={showPassword ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور'}
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading}
              className="w-full mt-2 py-3.5 px-6 rounded-2xl bg-[#8456D2] hover:bg-[#7243C6] text-white text-sm font-bold transition-all shadow-xs hover:shadow-md cursor-pointer flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>جاري التحقق وتسجيل الدخول...</span>
                </>
              ) : (
                <span>تسجيل الدخول إلى لوحة التحكم</span>
              )}
            </button>
          </form>

          {/* Quick Demo Credentials Helpers (Dev Only) */}
          {import.meta.env.DEV && (
            <div className="mt-6 pt-5 border-t border-[#F0E8FF]">
              <p className="text-xs font-bold text-[#74728A] text-center mb-3">
                حسابات تجريبية سريعة للفحص والتقييم:
              </p>
              <div className="flex flex-col sm:flex-row gap-2">
                <button
                  type="button"
                  onClick={() => handleQuickFill('doctor@mindora.com', 'Doctor123!')}
                  className="flex-1 py-2 px-3 rounded-xl bg-[#F0E8FF] hover:bg-[#E4D4FF] border border-[#E4D4FF] text-xs font-bold text-[#432F62] transition-colors cursor-pointer text-center"
                >
                  د. إيلينا (الافتراضي)
                </button>
                <button
                  type="button"
                  onClick={() => handleQuickFill('dr.sara@mindora.com', 'Doctor123!')}
                  className="flex-1 py-2 px-3 rounded-xl bg-[#F0E8FF] hover:bg-[#E4D4FF] border border-[#E4D4FF] text-xs font-bold text-[#432F62] transition-colors cursor-pointer text-center"
                >
                  د. سارة أحمد
                </button>
              </div>
            </div>
          )}

          {/* Register Link */}
          {onNavigateToRegister && (
            <div className="mt-5 pt-4 border-t border-[#F0E8FF] text-center">
              <p className="text-xs font-semibold text-[#74728A]">
                ليس لديك حساب طبيب حتى الآن؟{' '}
                <button
                  type="button"
                  onClick={onNavigateToRegister}
                  className="font-black text-[#8456D2] hover:text-[#432F62] transition-colors cursor-pointer mr-1"
                >
                  إنشاء حساب طبيب جديد
                </button>
              </p>
            </div>
          )}
        </div>

        {/* Footer info */}
        <p className="text-center text-xs text-[#74728A] font-medium mt-6">
          Mindora Platform • بوابة أطباء التأهيل السريري 2026
        </p>
      </div>
    </div>
  );
};

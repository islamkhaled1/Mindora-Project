import React, { useState, useEffect, useRef } from 'react';
import { useLocation, useNavigate, Link } from 'react-router-dom';
import { ShieldCheck, AlertCircle, CheckCircle2, Loader2, ArrowRight, RefreshCw, Stethoscope } from 'lucide-react';
import sawaLogo from '../assets/sawa-logo.png';
import { authApi } from '../api/authApi';

interface LocationState {
  email?: string;
  registeredJustNow?: boolean;
}

export const VerifyEmailPage: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();

  const state = location.state as LocationState | null;
  const targetEmail = state?.email || '';

  const [otp, setOtp] = useState<string[]>(['', '', '', '', '', '']);
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [cooldown, setCooldown] = useState<number>(60);

  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

  // 60-second cooldown timer for resending verification code
  useEffect(() => {
    if (cooldown <= 0) return;
    const interval = setInterval(() => {
      setCooldown((prev) => prev - 1);
    }, 1000);
    return () => clearInterval(interval);
  }, [cooldown]);

  // Focus first input on mount
  useEffect(() => {
    if (targetEmail && inputRefs.current[0]) {
      inputRefs.current[0].focus();
    }
  }, [targetEmail]);

  // Handle single digit entry
  const handleDigitChange = (index: number, value: string) => {
    const cleanValue = value.replace(/\D/g, '');
    if (!cleanValue && value !== '') return;

    const newOtp = [...otp];

    // Handle multi-digit paste in a single cell
    if (cleanValue.length > 1) {
      const digits = cleanValue.slice(0, 6).split('');
      for (let i = 0; i < 6; i++) {
        newOtp[i] = digits[i] || '';
      }
      setOtp(newOtp);
      const nextIndex = Math.min(digits.length, 5);
      inputRefs.current[nextIndex]?.focus();
      return;
    }

    newOtp[index] = cleanValue;
    setOtp(newOtp);
    setError(null);

    // Auto advance to next cell
    if (cleanValue && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  // Handle backspace navigation
  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  // Handle paste across all cells
  const handlePaste = (e: React.ClipboardEvent) => {
    e.preventDefault();
    const pastedData = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6);
    if (!pastedData) return;

    const newOtp = [...otp];
    for (let i = 0; i < 6; i++) {
      newOtp[i] = pastedData[i] || '';
    }
    setOtp(newOtp);
    setError(null);

    const focusIdx = Math.min(pastedData.length, 5);
    inputRefs.current[focusIdx]?.focus();
  };

  // Submit OTP Verification
  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccessMessage(null);

    const completeOtp = otp.join('');
    if (completeOtp.length !== 6) {
      setError('يرجى إدخال رمز التحقق المكون من 6 أرقام كاملاً.');
      return;
    }

    if (!targetEmail.trim()) {
      setError('لم يتم تحديد البريد الإلكتروني. يرجى العودة لصفحة التسجيل والمحاولة مجدداً.');
      return;
    }

    try {
      setLoading(true);
      const res = await authApi.verifyEmail(targetEmail, completeOtp);

      setSuccessMessage(res.message || 'تم تأكيد البريد الإلكتروني بنجاح!');

      // Redirect to login after brief delay for smooth doctor onboarding
      setTimeout(() => {
        navigate('/login', {
          state: {
            verifiedEmail: targetEmail,
            notification: 'تم تأكيد حسابك الطبي بنجاح! يمكنك الآن تسجيل الدخول مباشرة.',
          },
          replace: true,
        });
      }, 1500);
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message || 'رمز التحقق غير صحيح أو انتهت صلاحيته.');
      } else {
        setError('تعذر الاتصال بالخادم، يرجى المحاولة لاحقاً.');
      }
    } finally {
      setLoading(false);
    }
  };

  // Resend OTP handler
  const handleResend = async () => {
    if (cooldown > 0 || resending) return;
    setError(null);
    setSuccessMessage(null);

    if (!targetEmail.trim()) {
      setError('لم يتم تحديد البريد الإلكتروني لإعادة الإرسال.');
      return;
    }

    try {
      setResending(true);
      const res = await authApi.sendVerificationOtp(targetEmail);
      setSuccessMessage(res.message || 'تم إرسال رمز تحقق جديد إلى بريدك الإلكتروني بنجاح.');
      setCooldown(60);
      setOtp(['', '', '', '', '', '']);
      inputRefs.current[0]?.focus();
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message || 'تعذر إعادة إرسال رمز التحقق حالياً.');
      } else {
        setError('حدث خطأ أثناء محاولة إرسال الرمز.');
      }
    } finally {
      setResending(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F7FAFC] flex flex-col justify-center items-center p-4 sm:p-6" dir="rtl">
      {/* Decorative ambient background glows */}
      <div className="fixed top-0 left-1/4 w-96 h-96 bg-[#E4D4FF]/40 rounded-full blur-3xl pointer-events-none -z-10" />
      <div className="fixed bottom-0 right-1/4 w-96 h-96 bg-[#F0E8FF]/60 rounded-full blur-3xl pointer-events-none -z-10" />

      <div className="w-full max-w-md">
        {/* Logo and Brand Header */}
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center p-3 bg-white rounded-3xl border border-[#E4D4FF] shadow-xs mb-3">
            <img src={sawaLogo} alt="Sawa Logo" className="h-12 w-auto object-contain" />
          </div>
          <div className="flex items-center justify-center gap-2 mb-2">
            <span className="px-3 py-1 bg-[#F0E8FF] border border-[#E4D4FF] rounded-full text-xs font-black text-[#8456D2] inline-flex items-center gap-1.5">
              <Stethoscope className="w-3.5 h-3.5" />
              <span>تأكيد حساب الطبيب</span>
            </span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black text-[#432F62]">تأكيد البريد الإلكتروني</h1>
          <p className="text-sm font-semibold text-[#74728A] mt-2 leading-relaxed">
            لقد أرسلنا رمز تحقق مكوّن من 6 أرقام إلى:
            <br />
            <strong className="text-[#432F62] font-black dir-ltr inline-block mt-0.5" dir="ltr">
              {targetEmail || 'بريدك الإلكتروني المسجل'}
            </strong>
          </p>
        </div>

        {/* Verification Card */}
        <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 sm:p-8 shadow-sm">
          {/* Missing Email Alert */}
          {!targetEmail && (
            <div className="mb-6 p-4 rounded-2xl bg-[#FFF7E8] border border-[#F39C12]/30 flex items-start gap-3 text-right">
              <AlertCircle className="w-5 h-5 text-[#F39C12] shrink-0 mt-0.5" />
              <div className="flex-1 text-xs sm:text-sm font-bold text-[#A06200] leading-relaxed">
                لم يتم تمرير البريد الإلكتروني تلقائياً. يمكنك{' '}
                <Link to="/login" className="underline font-black hover:text-[#432F62]">
                  العودة لتسجيل الدخول
                </Link>{' '}
                أو إدخال البريد عبر صفحة التسجيل.
              </div>
            </div>
          )}

          {/* Success Message Alert */}
          {successMessage && (
            <div className="mb-6 p-4 rounded-2xl bg-[#E6F8F0] border border-[#10B981]/30 flex items-start gap-3 text-right animate-fade-in">
              <CheckCircle2 className="w-5 h-5 text-[#10B981] shrink-0 mt-0.5" />
              <div className="flex-1 text-xs sm:text-sm font-bold text-[#065F46] leading-relaxed">
                {successMessage}
              </div>
            </div>
          )}

          {/* Error Alert */}
          {error && (
            <div className="mb-6 p-4 rounded-2xl bg-[#FFD4CA]/50 border border-[#BD3737]/30 flex items-start gap-3 text-right animate-shake">
              <AlertCircle className="w-5 h-5 text-[#BD3737] shrink-0 mt-0.5" />
              <div className="flex-1 text-xs sm:text-sm font-bold text-[#BD3737] leading-relaxed">
                {error}
              </div>
            </div>
          )}

          <form onSubmit={handleVerify} className="space-y-6">
            {/* 6-Digit Code Input Cells */}
            <div>
              <label className="block text-xs font-black text-[#432F62] mb-3 text-center">
                أدخل رمز التحقق (OTP)
              </label>
              <div className="flex justify-center gap-2 sm:gap-3" dir="ltr" onPaste={handlePaste}>
                {otp.map((digit, index) => (
                  <input
                    key={index}
                    ref={(el) => { inputRefs.current[index] = el; }}
                    type="text"
                    inputMode="numeric"
                    maxLength={2}
                    value={digit}
                    onChange={(e) => handleDigitChange(index, e.target.value)}
                    onKeyDown={(e) => handleKeyDown(index, e)}
                    disabled={loading}
                    className="w-11 h-13 sm:w-12 sm:h-14 text-center text-xl sm:text-2xl font-black rounded-2xl border-2 border-[#E4D4FF] focus:border-[#8456D2] focus:ring-4 focus:ring-[#8456D2]/15 outline-hidden transition-all bg-[#F7FAFC] text-[#432F62] disabled:opacity-50"
                  />
                ))}
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading || otp.join('').length !== 6 || !targetEmail}
              className="w-full py-3.5 px-4 rounded-2xl bg-[#8456D2] hover:bg-[#7243C6] active:bg-[#6335B5] text-white text-sm font-black transition-all shadow-xs hover:shadow-md disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 cursor-pointer"
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>جارٍ التحقق وتأكيد الحساب...</span>
                </>
              ) : (
                <>
                  <ShieldCheck className="w-4 h-4" />
                  <span>تأكيد الحساب وتفعيله</span>
                </>
              )}
            </button>

            {/* Resend OTP Section */}
            <div className="pt-2 text-center border-t border-[#F0E8FF]">
              <p className="text-xs font-semibold text-[#74728A] mb-2">لم يصلك رمز التحقق؟</p>
              {cooldown > 0 ? (
                <span className="text-xs font-black text-[#8456D2] inline-flex items-center gap-1.5 bg-[#F0E8FF] px-3 py-1.5 rounded-xl border border-[#E4D4FF]">
                  <span>إعادة الإرسال بعد ({cooldown} ثانية)</span>
                </span>
              ) : (
                <button
                  type="button"
                  onClick={handleResend}
                  disabled={resending || !targetEmail}
                  className="text-xs font-black text-[#8456D2] hover:text-[#7243C6] transition-colors inline-flex items-center gap-1.5 cursor-pointer disabled:opacity-50"
                >
                  {resending ? (
                    <>
                      <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      <span>جارٍ إرسال الرمز...</span>
                    </>
                  ) : (
                    <>
                      <RefreshCw className="w-3.5 h-3.5" />
                      <span>إعادة إرسال رمز التحقق</span>
                    </>
                  )}
                </button>
              )}
            </div>
          </form>
        </div>

        {/* Footer Navigation */}
        <div className="mt-6 text-center">
          <Link
            to="/login"
            className="inline-flex items-center gap-2 text-xs sm:text-sm font-black text-[#74728A] hover:text-[#432F62] transition-colors"
          >
            <ArrowRight className="w-4 h-4" />
            <span>العودة إلى صفحة تسجيل الدخول</span>
          </Link>
        </div>
      </div>
    </div>
  );
};

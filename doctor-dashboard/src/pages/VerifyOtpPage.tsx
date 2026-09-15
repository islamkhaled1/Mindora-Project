import React, { useState, useEffect, useRef } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { ShieldCheck, AlertCircle, Loader2, ArrowRight, RefreshCw } from 'lucide-react';
import sawaLogo from '../assets/sawa-logo.png';
import { authApi } from '../api/authApi';

interface LocationState {
  email?: string;
}

export const VerifyOtpPage: React.FC = () => {
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

  // 60-second cooldown timer for resend
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

  // Handle single digit input
  const handleDigitChange = (index: number, value: string) => {
    // Only accept numeric characters
    const cleanValue = value.replace(/\D/g, '');
    if (!cleanValue && value !== '') return;

    const newOtp = [...otp];
    // If pasted multiple digits
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

    // Auto advance
    if (cleanValue && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  // Handle backspace
  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  // Handle paste on any cell
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

    const completeOtp = otp.join('');
    if (completeOtp.length !== 6) {
      setError('يرجى إدخال رمز التحقق المكون من 6 أرقام كاملاً.');
      return;
    }

    try {
      setLoading(true);
      const res = await authApi.verifyOtp(targetEmail, completeOtp);

      // On successful OTP verification, navigate to reset password step with transient state
      navigate('/reset-password', {
        state: {
          email: targetEmail,
          resetToken: res.resetToken,
        },
        replace: true,
      });
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message || 'رمز التحقق غير صحيح أو منتهي الصلاحية.');
      } else {
        setError('تعذر التحقق من الرمز، يرجى المحاولة مرة أخرى.');
      }
    } finally {
      setLoading(false);
    }
  };

  // Resend OTP
  const handleResendOtp = async () => {
    if (cooldown > 0 || resending) return;

    try {
      setResending(true);
      setError(null);
      await authApi.forgotPassword(targetEmail);
      setSuccessMessage('تم إرسال رمز تحقق جديد بنجاح.');
      setCooldown(60);
      setOtp(['', '', '', '', '', '']);
      inputRefs.current[0]?.focus();
      setTimeout(() => setSuccessMessage(null), 4000);
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message || 'تعذر إعادة إرسال الرمز، يرجى المحاولة بعد قليل.');
      } else {
        setError('تعذر الاتصال بالخادم.');
      }
    } finally {
      setResending(false);
    }
  };

  // Guard: If refreshed without email state
  if (!targetEmail) {
    return (
      <div className="min-h-screen bg-[#F7FAFC] flex flex-col justify-center items-center p-4 sm:p-6" dir="rtl">
        <div className="w-full max-w-md bg-white rounded-3xl border border-[#E4D4FF] p-8 text-center shadow-sm">
          <div className="w-14 h-14 rounded-2xl bg-[#FFF5F2] border border-[#FFD4CA] text-[#BD3737] flex items-center justify-center mx-auto mb-4">
            <AlertCircle className="w-7 h-7" />
          </div>
          <h2 className="text-xl font-black text-[#432F62] mb-2">لم يتم العثور على جلسة استعادة نشطة</h2>
          <p className="text-xs sm:text-sm text-[#74728A] font-medium mb-6 leading-relaxed">
            لأسباب أمنية، يرجى إدخال بريدك الإلكتروني أولاً للبدء في إجراءات استعادة كلمة المرور.
          </p>
          <button
            onClick={() => navigate('/forgot-password')}
            className="w-full py-3 px-6 rounded-2xl bg-[#8456D2] hover:bg-[#7243C6] text-white text-xs sm:text-sm font-bold transition-all shadow-xs cursor-pointer"
          >
            الذهاب إلى استعادة كلمة المرور
          </button>
        </div>
      </div>
    );
  }

  const isOtpComplete = otp.every((digit) => digit.length === 1);

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
              <ShieldCheck className="w-3.5 h-3.5" />
              <span>التحقق من الرمز</span>
            </span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black text-[#432F62]">رمز التحقق</h1>
          <p className="text-xs sm:text-sm font-semibold text-[#74728A] mt-1">
            أدخل الرمز المكون من 6 أرقام المرسل إلى:
          </p>
          <div className="inline-block mt-2 px-3 py-1 bg-[#F0E8FF] rounded-xl text-xs font-bold text-[#432F62] border border-[#E4D4FF]">
            {targetEmail}
          </div>
        </div>

        {/* Card */}
        <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 sm:p-8 shadow-sm">
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

          <form onSubmit={handleVerify} className="space-y-6">
            {/* 6-Digit PIN Inputs */}
            <div>
              <label className="block text-xs font-bold text-[#432F62] mb-3 text-center">
                أدخل رمز التأكيد (6 أرقام)
              </label>
              <div className="flex justify-center items-center gap-2 sm:gap-3" dir="ltr">
                {otp.map((digit, index) => (
                  <input
                    key={index}
                    ref={(el) => {
                      inputRefs.current[index] = el;
                    }}
                    type="text"
                    inputMode="numeric"
                    pattern="[0-9]*"
                    maxLength={1}
                    value={digit}
                    onChange={(e) => handleDigitChange(index, e.target.value)}
                    onKeyDown={(e) => handleKeyDown(index, e)}
                    onPaste={handlePaste}
                    disabled={loading}
                    className={`w-11 h-14 sm:w-12 sm:h-14 text-center text-xl sm:text-2xl font-black rounded-2xl border transition-all focus:outline-none ${
                      digit
                        ? 'border-[#8456D2] bg-[#F0E8FF]/30 text-[#432F62]'
                        : 'border-[#E4D4FF] bg-[#F7FAFC] focus:bg-white focus:border-[#8456D2] text-[#432F62]'
                    }`}
                  />
                ))}
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading || !isOtpComplete}
              className="w-full py-3.5 px-6 rounded-2xl bg-[#8456D2] hover:bg-[#7243C6] text-white text-sm font-bold transition-all shadow-xs hover:shadow-md cursor-pointer flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>جاري التحقق من الرمز...</span>
                </>
              ) : (
                <span>تأكيد الرمز والمتابعة</span>
              )}
            </button>

            {/* Resend Cooldown Section */}
            <div className="pt-2 text-center">
              {cooldown > 0 ? (
                <p className="text-xs font-semibold text-[#74728A]">
                  لم يصلك الرمز؟ يمكنك إعادة الإرسال خلال{' '}
                  <span className="font-bold text-[#8456D2] font-mono">
                    ({Math.floor(cooldown / 60).toString().padStart(2, '0')}:{(cooldown % 60).toString().padStart(2, '0')})
                  </span>
                </p>
              ) : (
                <button
                  type="button"
                  onClick={handleResendOtp}
                  disabled={resending}
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-[#8456D2] hover:text-[#7243C6] transition-colors cursor-pointer disabled:opacity-50"
                >
                  <RefreshCw className={`w-3.5 h-3.5 ${resending ? 'animate-spin' : ''}`} />
                  <span>إعادة إرسال الرمز الآن</span>
                </button>
              )}
            </div>
          </form>

          {/* Back button */}
          <div className="mt-5 pt-4 border-t border-[#F0E8FF] text-center">
            <button
              type="button"
              onClick={() => navigate('/forgot-password')}
              className="inline-flex items-center gap-1.5 text-xs font-bold text-[#74728A] hover:text-[#432F62] transition-colors cursor-pointer"
            >
              <ArrowRight className="w-4 h-4" />
              <span>تغيير البريد الإلكتروني</span>
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

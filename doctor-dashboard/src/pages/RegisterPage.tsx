import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Lock, Mail, AlertCircle, Loader2, Eye, EyeOff, Stethoscope, User, Building, Award, ArrowRight } from 'lucide-react';
import sawaLogo from '../assets/sawa-logo.png';
import { authApi } from '../api/authApi';
import { ApiError } from '../api/client';
import type { CurrentUserDto } from '../api/types';

interface RegisterPageProps {
  onRegisterSuccess: (user: CurrentUserDto, token: string) => void;
  onNavigateToLogin: () => void;
}

const COMMON_SPECIALIZATIONS = [
  'علاج وظيفي وتأهيل حركي للأطفال',
  'علاج طبيعي للأطفال',
  'تخاطب واضطرابات نطق وتواصل',
  'علاج سلوكي وتنمية مهارات',
  'طب أطفال ونمو سلوكي',
];

export const RegisterPage: React.FC<RegisterPageProps> = ({
  onRegisterSuccess,
  onNavigateToLogin,
}) => {
  const navigate = useNavigate();
  const [fullName, setFullName] = useState('');
  const [gender, setGender] = useState<'Female' | 'Male'>('Female');
  const [specialization, setSpecialization] = useState('');
  const [clinicName, setClinicName] = useState('');
  const [licenseNumber, setLicenseNumber] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Client-side validations
    const trimmedName = fullName.trim();
    const trimmedEmail = email.trim();
    const trimmedPassword = password.trim();
    const trimmedSpec = specialization.trim();

    if (!trimmedName) {
      setError('يرجى إدخال اسم الطبيب بالكامل.');
      return;
    }

    if (!gender) {
      setError('يرجى تحديد جنس الطبيب.');
      return;
    }

    if (!trimmedEmail) {
      setError('يرجى إدخال البريد الإلكتروني.');
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(trimmedEmail)) {
      setError('يرجى إدخال بريد إلكتروني صحيح ومكتمل (مثال: dr.name@mindora.com).');
      return;
    }

    if (!trimmedPassword) {
      setError('يرجى إدخال كلمة المرور.');
      return;
    }

    if (trimmedPassword.length < 8) {
      setError('يجب أن تتكون كلمة المرور من 8 أحرف على الأقل.');
      return;
    }

    if (!/\d/.test(trimmedPassword)) {
      setError('يجب أن تحتوي كلمة المرور على رقم واحد على الأقل.');
      return;
    }

    if (!trimmedSpec) {
      setError('يرجى إدخال أو تحديد التخصص الطبي أو التأهيلي.');
      return;
    }

    try {
      setLoading(true);

      const registerRes = await authApi.registerDoctor({
        email: trimmedEmail,
        password: trimmedPassword,
        fullName: trimmedName,
        specialization: trimmedSpec,
        clinicName: clinicName.trim() || undefined,
        licenseNumber: licenseNumber.trim() || undefined,
        gender,
      });

      if (registerRes.requiresEmailVerification) {
        navigate('/verify-email', {
          state: {
            email: trimmedEmail,
            registeredJustNow: true,
          },
        });
        return;
      }

      if (registerRes.token) {
        const me = await authApi.getMe();
        if (me.role !== 'Doctor') {
          authApi.logout();
          setError('تم إنشاء الحساب بنجاح ولكن لم يتم تعيين صلاحيات الطبيب بشكل صحيح.');
          setLoading(false);
          return;
        }
        onRegisterSuccess(me, registerRes.token);
      }
    } catch (err: unknown) {
      if (err instanceof ApiError) {
        const msg = err.message || '';
        if (msg.includes('SAWA APP') || msg.includes('لوحة تحكم الطبيب')) {
          setError(msg);
        } else if (
          err.status === 409 ||
          msg.includes('already registered') ||
          msg.includes('Email already in use') ||
          msg.includes('already exists') ||
          msg.includes('مسجل بالفعل') ||
          msg.includes('duplicate') ||
          msg.includes('Conflict')
        ) {
          setError(msg || 'هذا البريد الإلكتروني مسجل بالفعل في المنصة، يرجى تسجيل الدخول أو استخدام بريد آخر.');
        } else if (msg.includes('Password') || msg.includes('password') || msg.includes('كلمة المرور')) {
          setError(
            msg.includes('digit') || msg.includes('رقم')
              ? 'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل وتتكون من 8 أحرف على الأقل.'
              : 'كلمة المرور لا تفي بالمعايير الأمنية المطلوبة (8 أحرف على الأقل ورقم واحد).'
          );
        } else {
          setError(msg || 'فشل تسجيل حساب الطبيب. يرجى مراجعة البيانات المدخلة والمحاولة مجدداً.');
        }
      } else if (err instanceof Error) {
        const msg = err.message || '';
        if (msg.includes('Failed to fetch') || msg.includes('NetworkError')) {
          setError('تعذر الاتصال بالخادم، يرجى التحقق من تشغيل الخدمة والاتصال بالإنترنت.');
        } else {
          setError(msg || 'فشل تسجيل حساب الطبيب. يرجى مراجعة البيانات المدخلة والمحاولة مجدداً.');
        }
      } else {
        setError('تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت والمحاولة لاحقاً.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F7FAFC] flex flex-col justify-center items-center p-4 sm:p-6" dir="rtl">
      {/* Decorative ambient glows */}
      <div className="fixed top-0 left-1/4 w-96 h-96 bg-[#E4D4FF]/40 rounded-full blur-3xl pointer-events-none -z-10" />
      <div className="fixed bottom-0 right-1/4 w-96 h-96 bg-[#F0E8FF]/60 rounded-full blur-3xl pointer-events-none -z-10" />

      <div className="w-full max-w-xl">
        {/* Header Branding */}
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center p-3 bg-white rounded-3xl border border-[#E4D4FF] shadow-xs mb-3">
            <img src={sawaLogo} alt="Sawa Logo" className="h-12 w-auto object-contain" />
          </div>
          <div className="flex items-center justify-center gap-2 mb-2">
            <span className="px-3 py-1 bg-[#F0E8FF] border border-[#E4D4FF] rounded-full text-xs font-black text-[#8456D2] inline-flex items-center gap-1.5">
              <Stethoscope className="w-3.5 h-3.5" />
              <span>انضمام كطبيب ومختص نمائي</span>
            </span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black text-[#432F62]">إنشاء حساب طبيب جديد</h1>
          <p className="text-xs sm:text-sm font-semibold text-[#74728A] mt-1">
            سجّل بياناتك السريرية للبدء في متابعة برامج التأهيل النمائي للأطفال
          </p>
        </div>

        {/* Card */}
        <div className="bg-white rounded-3xl border border-[#E4D4FF] p-6 sm:p-8 shadow-sm">
          {error && (
            <div className="mb-5 p-4 rounded-2xl bg-[#FFD4CA]/50 border border-[#BD3737]/30 flex items-start gap-3 text-right">
              <AlertCircle className="w-5 h-5 text-[#BD3737] shrink-0 mt-0.5" />
              <div className="flex-1 text-xs sm:text-sm font-bold text-[#BD3737] leading-relaxed">
                {error}
              </div>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Full Name */}
            <div>
              <label className="block text-xs font-bold text-[#432F62] mb-1.5 text-right">
                اسم الطبيب / الأخصائي بالكامل <span className="text-[#BD3737]">*</span>
              </label>
              <div className="relative">
                <input
                  type="text"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="مثال: د. سارة أحمد أو د. أحمد خالد"
                  required
                  disabled={loading}
                  className="w-full bg-[#F7FAFC] focus:bg-white text-sm text-[#432F62] placeholder-[#74728A] pl-4 pr-11 py-2.5 rounded-2xl border border-[#E4D4FF] focus:border-[#8456D2] focus:outline-none transition-all font-medium text-right"
                />
                <User className="w-5 h-5 text-[#74728A] absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>
            </div>

            {/* Gender Selection */}
            <div>
              <label className="block text-xs font-bold text-[#432F62] mb-1.5 text-right">
                الجنس <span className="text-[#BD3737]">*</span>
              </label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setGender('Female')}
                  disabled={loading}
                  className={`py-2.5 px-3 rounded-2xl border text-xs font-bold transition-all flex items-center justify-center gap-2 cursor-pointer ${
                    gender === 'Female'
                      ? 'bg-[#F0E8FF] border-[#8456D2] text-[#432F62] shadow-xs'
                      : 'bg-[#F7FAFC] border-[#E4D4FF] text-[#74728A] hover:bg-[#F0E8FF]/40'
                  }`}
                >
                  <span className="text-base">👩‍⚕️</span>
                  <span>أنثى</span>
                </button>
                <button
                  type="button"
                  onClick={() => setGender('Male')}
                  disabled={loading}
                  className={`py-2.5 px-3 rounded-2xl border text-xs font-bold transition-all flex items-center justify-center gap-2 cursor-pointer ${
                    gender === 'Male'
                      ? 'bg-[#F0E8FF] border-[#8456D2] text-[#432F62] shadow-xs'
                      : 'bg-[#F7FAFC] border-[#E4D4FF] text-[#74728A] hover:bg-[#F0E8FF]/40'
                  }`}
                >
                  <span className="text-base">👨‍⚕️</span>
                  <span>ذكر</span>
                </button>
              </div>
            </div>

            {/* Specialization */}
            <div>
              <label className="block text-xs font-bold text-[#432F62] mb-1.5 text-right">
                التخصص الطبي أو التأهيلي <span className="text-[#BD3737]">*</span>
              </label>
              <div className="relative">
                <input
                  type="text"
                  value={specialization}
                  onChange={(e) => setSpecialization(e.target.value)}
                  placeholder="مثال: علاج وظيفي وتأهيل أطفال"
                  required
                  disabled={loading}
                  className="w-full bg-[#F7FAFC] focus:bg-white text-sm text-[#432F62] placeholder-[#74728A] pl-4 pr-11 py-2.5 rounded-2xl border border-[#E4D4FF] focus:border-[#8456D2] focus:outline-none transition-all font-medium text-right"
                />
                <Stethoscope className="w-5 h-5 text-[#74728A] absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>
              {/* Quick suggestions */}
              <div className="flex flex-wrap gap-1.5 mt-2">
                {COMMON_SPECIALIZATIONS.map((spec) => (
                  <button
                    key={spec}
                    type="button"
                    onClick={() => setSpecialization(spec)}
                    className="text-[10px] font-bold px-2 py-1 rounded-lg bg-[#F0E8FF] hover:bg-[#E4D4FF] text-[#432F62] border border-[#E4D4FF] transition-colors cursor-pointer"
                  >
                    {spec}
                  </button>
                ))}
              </div>
            </div>

            {/* Clinic Name & License Number in Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
              <div>
                <label className="block text-xs font-bold text-[#432F62] mb-1.5 text-right">
                  المركز الطبي أو العيادة <span className="text-[#74728A] text-[10px]">(اختياري)</span>
                </label>
                <div className="relative">
                  <input
                    type="text"
                    value={clinicName}
                    onChange={(e) => setClinicName(e.target.value)}
                    placeholder="مركز الأمل للتأهيل"
                    disabled={loading}
                    className="w-full bg-[#F7FAFC] focus:bg-white text-sm text-[#432F62] placeholder-[#74728A] pl-4 pr-11 py-2.5 rounded-2xl border border-[#E4D4FF] focus:border-[#8456D2] focus:outline-none transition-all font-medium text-right"
                  />
                  <Building className="w-5 h-5 text-[#74728A] absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#432F62] mb-1.5 text-right">
                  رقم ترخيص مزاولة المهنة <span className="text-[#74728A] text-[10px]">(اختياري)</span>
                </label>
                <div className="relative">
                  <input
                    type="text"
                    value={licenseNumber}
                    onChange={(e) => setLicenseNumber(e.target.value)}
                    placeholder="LIC-123456"
                    disabled={loading}
                    className="w-full bg-[#F7FAFC] focus:bg-white text-sm text-[#432F62] placeholder-[#74728A] pl-4 pr-11 py-2.5 rounded-2xl border border-[#E4D4FF] focus:border-[#8456D2] focus:outline-none transition-all font-medium text-right"
                  />
                  <Award className="w-5 h-5 text-[#74728A] absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                </div>
              </div>
            </div>

            {/* Email Field */}
            <div>
              <label className="block text-xs font-bold text-[#432F62] mb-1.5 text-right">
                البريد الإلكتروني المهني <span className="text-[#BD3737]">*</span>
              </label>
              <div className="relative">
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="doctor@clinic.com"
                  required
                  disabled={loading}
                  className="w-full bg-[#F7FAFC] focus:bg-white text-sm text-[#432F62] placeholder-[#74728A] pl-4 pr-11 py-2.5 rounded-2xl border border-[#E4D4FF] focus:border-[#8456D2] focus:outline-none transition-all font-medium text-right"
                />
                <Mail className="w-5 h-5 text-[#74728A] absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>
            </div>

            {/* Password Field */}
            <div>
              <label className="block text-xs font-bold text-[#432F62] mb-1.5 text-right">
                كلمة المرور <span className="text-[#BD3737]">*</span> <span className="text-[#74728A] text-[10px]">(8 أحرف على الأقل)</span>
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  disabled={loading}
                  className="w-full bg-[#F7FAFC] focus:bg-white text-sm text-[#432F62] placeholder-[#74728A] pl-11 pr-11 py-2.5 rounded-2xl border border-[#E4D4FF] focus:border-[#8456D2] focus:outline-none transition-all font-medium text-right"
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
              className="w-full mt-3 py-3.5 px-6 rounded-2xl bg-[#8456D2] hover:bg-[#7243C6] text-white text-sm font-bold transition-all shadow-xs hover:shadow-md cursor-pointer flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>جاري إنشاء الحساب والدخول...</span>
                </>
              ) : (
                <span>إنشاء حساب الطبيب والبدء فوراً</span>
              )}
            </button>
          </form>

          {/* Switch to Login Link */}
          <div className="mt-5 pt-4 border-t border-[#F0E8FF] text-center">
            <p className="text-xs font-semibold text-[#74728A]">
              لديك حساب طبيب بالفعل؟{' '}
              <button
                type="button"
                onClick={onNavigateToLogin}
                className="font-black text-[#8456D2] hover:text-[#432F62] transition-colors cursor-pointer inline-flex items-center gap-1 mr-1"
              >
                <span>تسجيل الدخول</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </p>
          </div>
        </div>

        {/* Footer info */}
        <p className="text-center text-xs text-[#74728A] font-medium mt-6">
          Mindora Platform • بوابة أطباء ومختصي التأهيل النمائي 2026
        </p>
      </div>
    </div>
  );
};

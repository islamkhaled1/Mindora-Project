import { useState, useEffect } from 'react';
import { Routes, Route, Navigate, useNavigate, useLocation } from 'react-router-dom';
import { Sidebar, type NavTab } from './components/layout/Sidebar';
import { Header } from './components/layout/Header';
import { DashboardOverviewPage } from './pages/DashboardOverviewPage';
import { ChildrenDirectoryPage } from './pages/ChildrenDirectoryPage';
import { ChildDetailPage } from './pages/ChildDetailPage';
import { ConnectionRequestsPage } from './pages/ConnectionRequestsPage';
import { LoginPage } from './pages/LoginPage';
import { RegisterPage } from './pages/RegisterPage';
import { ForgotPasswordPage } from './pages/ForgotPasswordPage';
import { VerifyOtpPage } from './pages/VerifyOtpPage';
import { VerifyEmailPage } from './pages/VerifyEmailPage';
import { ResetPasswordPage } from './pages/ResetPasswordPage';
import { ChangePasswordPage } from './pages/ChangePasswordPage';
import { authApi } from './api/authApi';
import { doctorApi } from './api/doctorApi';
import { getStoredToken, onUnauthorized } from './api/client';
import type { CurrentUserDto } from './api/types';
import type { DoctorProfile } from './types';
import { resolveDoctorAvatar } from './utils/doctorAvatarHelper';
import { Menu, X, Loader2 } from 'lucide-react';
import sawaLogo from './assets/sawa-logo.png';

interface LocationState {
  from?: {
    pathname: string;
  };
}

interface ComingSoonViewProps {
  tab: string;
  onNavigateTab: (tab: NavTab) => void;
}

const ComingSoonView: React.FC<ComingSoonViewProps> = ({ tab, onNavigateTab }) => {
  return (
    <div className="bg-white rounded-3xl border border-[#E4D4FF] p-10 text-center shadow-xs animate-fade-in" dir="rtl">
      <div className="w-14 h-14 rounded-2xl bg-[#F0E8FF] text-[#8456D2] flex items-center justify-center mx-auto mb-4 text-2xl font-black border border-[#E4D4FF]">
        🔒
      </div>
      <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#F0E8FF] text-[#8456D2] text-xs font-bold border border-[#E4D4FF] mb-3">
        <span>ميزة قادمة في التحديث القادم</span>
      </div>
      <h3 className="text-xl font-black text-[#432F62] mb-2">
        قسم {tab === 'plans' ? 'خطط العلاج' : tab === 'sessions' ? 'الجلسات' : tab === 'notes' ? 'التعليقات والملاحظات' : tab === 'progress' ? 'التقدم الإجمالي' : 'إعدادات العيادة'}
      </h3>
      <p className="text-xs text-[#74728A] max-w-md mx-auto mb-6 font-semibold leading-relaxed">
        {tab === 'notes' || tab === 'progress' || tab === 'sessions'
          ? 'يمكنك الاطلاع على الملاحظات السريرية، تاريخ الجلسات، وتطور أداء كل طفل مباشرةً من خلال فتح ملف الطفل في "دليل الأطفال".'
          : 'هذا القسم قيد التطوير للتكامل مع التحديثات المستقبلية لمنظومة سوا. يمكنك متابعة الأطفال الحاليين عبر شاشتي "الرئيسية" و"الأطفال".'}
      </p>
      <div className="flex items-center justify-center gap-3">
        <button
          onClick={() => onNavigateTab('children')}
          className="px-5 py-2.5 rounded-2xl bg-[#8456D2] hover:bg-[#7243C6] text-white text-xs font-black transition-colors cursor-pointer shadow-xs"
        >
          الانتقال إلى دليل الأطفال
        </button>
        <button
          onClick={() => onNavigateTab('dashboard')}
          className="px-5 py-2.5 rounded-2xl bg-[#F0E8FF] hover:bg-[#E4D4FF] text-[#432F62] text-xs font-black transition-colors cursor-pointer border border-[#E4D4FF]"
        >
          العودة إلى الرئيسية
        </button>
      </div>
    </div>
  );
};

export function App() {
  const navigate = useNavigate();
  const location = useLocation();

  const [currentUser, setCurrentUser] = useState<CurrentUserDto | null>(null);
  const [authChecking, setAuthChecking] = useState<boolean>(() => Boolean(getStoredToken()));
  const [sessionExpiredMessage, setSessionExpiredMessage] = useState<string | null>(null);

  const [dynamicReferralCode, setDynamicReferralCode] = useState<string>('');
  const [globalSearch, setGlobalSearch] = useState<string>('');
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState<boolean>(false);

  // Initialize and verify authentication on app start
  useEffect(() => {
    const unsubscribe = onUnauthorized(() => {
      setCurrentUser(null);
      setSessionExpiredMessage('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً.');
      navigate('/login', { replace: true, state: { from: location } });
    });

    const token = getStoredToken();
    if (token) {
      authApi
        .getMe()
        .then((me) => {
          if (me.role === 'Doctor') {
            setCurrentUser(me);
          } else {
            authApi.logout();
            setCurrentUser(null);
            setSessionExpiredMessage('عذراً، هذا الحساب ليس لديه صلاحية طبيب.');
          }
        })
        .catch(() => {
          authApi.logout();
          setCurrentUser(null);
        })
        .finally(() => {
          setAuthChecking(false);
        });
    } else {
      setAuthChecking(false);
    }

    return () => unsubscribe();
  }, [navigate, location]);

  // Preload referral code when authenticated
  useEffect(() => {
    if (currentUser && !dynamicReferralCode) {
      doctorApi
        .getDashboard()
        .then((dto) => {
          if (dto.referralCode) {
            setDynamicReferralCode(dto.referralCode);
          }
        })
        .catch((err) => {
          console.warn('Could not preload referral code:', err);
        });
    }
  }, [currentUser, dynamicReferralCode]);

  const handleLoginSuccess = (user: CurrentUserDto) => {
    setCurrentUser(user);
    setSessionExpiredMessage(null);
    const locState = location.state as LocationState | null;
    const targetPath = locState?.from?.pathname || '/dashboard';
    navigate(targetPath, { replace: true });
  };

  const handleLogout = () => {
    authApi.logout();
    setCurrentUser(null);
    setDynamicReferralCode('');
    navigate('/login', { replace: true });
  };

  // Determine current active navigation tab based on URL path
  const getCurrentTab = (pathname: string): NavTab => {
    if (pathname.startsWith('/children')) return 'children';
    if (pathname.startsWith('/requests')) return 'requests';
    if (pathname.startsWith('/plans')) return 'plans';
    if (pathname.startsWith('/sessions')) return 'sessions';
    if (pathname.startsWith('/notes')) return 'notes';
    if (pathname.startsWith('/progress')) return 'progress';
    if (pathname.startsWith('/settings')) return 'settings';
    if (pathname.startsWith('/change-password')) return 'change-password';
    return 'dashboard';
  };

  const currentTab = getCurrentTab(location.pathname);

  // Dynamic doctor profile derived strictly from authenticated user & API
  const doctorProfile: DoctorProfile = {
    name: currentUser?.fullName || 'طبيب سوا',
    specialization: currentUser?.specialization ?? 'غير محدد',
    clinicName: currentUser?.clinicName ?? undefined,
    avatarUrl: resolveDoctorAvatar(currentUser?.gender),
    referralCode: dynamicReferralCode || currentUser?.referralCode || '',
    gender: currentUser?.gender ?? undefined,
  };

  const handleSelectTab = (tab: NavTab) => {
    setMobileSidebarOpen(false);
    navigate(`/${tab}`);
  };

  // Header Search handles navigation if searching from another tab
  const handleHeaderSearchChange = (value: string) => {
    setGlobalSearch(value);
    if (value.trim().length > 0 && !location.pathname.startsWith('/children')) {
      navigate('/children');
    }
  };

  // Dynamic header titles based on state
  const doctorDisplayName = currentUser?.fullName
    ? (currentUser.fullName.startsWith('د.') || currentUser.fullName.startsWith('Dr.')
        ? currentUser.fullName
        : `د. ${currentUser.fullName}`)
    : 'د. الطبيب';

  const isChildDetail = location.pathname.startsWith('/children/') && location.pathname !== '/children';

  let headerTitle = `صباح الخير ${doctorDisplayName}`;
  let headerSubtitle = 'هنا لمحة عامة عن تقدم أطفالك اليوم';

  if (isChildDetail) {
    headerSubtitle = 'تفاصيل الملف النمائي وملاحظات المتابعة';
  } else if (currentTab === 'children') {
    headerSubtitle = 'دليل الأطفال المتابعين والتقييمات الدورية';
  } else if (currentTab === 'requests') {
    headerSubtitle = 'مراجعة واعتماد طلبات أولياء الأمور لربط الأطفال';
  } else if (currentTab === 'plans') {
    headerSubtitle = 'خطط الرعاية والتأهيل النمائي';
  } else if (currentTab === 'sessions') {
    headerSubtitle = 'جدول الجلسات وسجل الحضور';
  } else if (currentTab === 'notes') {
    headerSubtitle = 'الملاحظات والتقارير السريرية';
  } else if (currentTab === 'progress') {
    headerSubtitle = 'تحليلات الأداء ومعدلات التحسن العامة';
  } else if (currentTab === 'settings') {
    headerSubtitle = 'إعدادات الحساب والعيادة';
  } else if (currentTab === 'change-password') {
    headerSubtitle = 'تحديث كلمة المرور لحساب الطبيب والمختص';
  }

  // 1. Initial Authentication Checking Screen
  if (authChecking) {
    return (
      <div className="min-h-screen bg-[#F7FAFC] flex flex-col items-center justify-center p-6 text-center" dir="rtl">
        <div className="w-16 h-16 rounded-3xl bg-white border border-[#E4D4FF] shadow-xs flex items-center justify-center mb-4">
          <img src={sawaLogo} alt="Sawa" className="w-10 h-10 object-contain" />
        </div>
        <Loader2 className="w-8 h-8 text-[#8456D2] animate-spin mb-3" />
        <p className="text-sm font-bold text-[#432F62]">جاري التحقق من الجلسة والصلاحيات...</p>
      </div>
    );
  }

  // 2. Unauthenticated Screen -> Render LoginPage or RegisterPage
  if (!currentUser) {
    return (
      <Routes>
        <Route
          path="/login"
          element={
            <LoginPage
              onLoginSuccess={handleLoginSuccess}
              sessionExpiredMessage={sessionExpiredMessage}
              onNavigateToRegister={() => navigate('/register')}
              onNavigateToForgotPassword={() => navigate('/forgot-password')}
            />
          }
        />
        <Route
          path="/register"
          element={
            <RegisterPage
              onRegisterSuccess={handleLoginSuccess}
              onNavigateToLogin={() => navigate('/login')}
            />
          }
        />
        <Route path="/forgot-password" element={<ForgotPasswordPage />} />
        <Route path="/verify-otp" element={<VerifyOtpPage />} />
        <Route path="/verify-email" element={<VerifyEmailPage />} />
        <Route path="/reset-password" element={<ResetPasswordPage />} />
        {/* Any protected route redirect to /login keeping current location */}
        <Route path="*" element={<Navigate to="/login" state={{ from: location }} replace />} />
      </Routes>
    );
  }

  // 3. Authenticated Doctor Dashboard Application
  return (
    <div className="min-h-screen bg-[#F7FAFC] text-[#000424] flex flex-col md:flex-row antialiased font-['Cairo',sans-serif]">
      {/* Mobile Top Bar with Hamburger Menu & Sawa Logo */}
      <div className="md:hidden flex items-center justify-between p-4 bg-white border-b border-[#E4D4FF] z-40 sticky top-0 shadow-2xs">
        <div className="flex items-center gap-2">
          <img src={sawaLogo} alt="Sawa" className="w-10 h-10 object-contain" />
          <span className="font-black text-base text-[#432F62]">سـوا | SAWA</span>
        </div>
        <button
          onClick={() => setMobileSidebarOpen(!mobileSidebarOpen)}
          className="p-2 rounded-xl bg-[#F0E8FF] text-[#432F62] border border-[#E4D4FF]"
          aria-label="القائمة"
        >
          {mobileSidebarOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5 text-[#432F62]" />}
        </button>
      </div>

      {/* Sidebar Overlay for Mobile */}
      {mobileSidebarOpen && (
        <div
          onClick={() => setMobileSidebarOpen(false)}
          className="fixed inset-0 bg-black/30 backdrop-blur-xs z-40 md:hidden"
        />
      )}

      {/* Sidebar Container */}
      <div
        className={`fixed md:sticky top-0 right-0 h-screen z-50 md:z-auto transition-transform duration-300 md:translate-x-0 ${
          mobileSidebarOpen ? 'translate-x-0' : 'translate-x-full md:translate-x-0'
        }`}
      >
        <Sidebar
          currentTab={currentTab}
          onSelectTab={handleSelectTab}
          doctorProfile={doctorProfile}
          onLogout={handleLogout}
        />
      </div>

      {/* Main Content Area */}
      <main className="flex-1 p-4 sm:p-6 lg:p-8 max-w-7xl mx-auto w-full min-w-0">
        <Header
          title={headerTitle}
          subtitle={headerSubtitle}
          doctorProfile={doctorProfile}
          searchValue={globalSearch}
          onSearchChange={handleHeaderSearchChange}
          showSearch={!isChildDetail}
        />

        {/* View Router */}
        <Routes>
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route
            path="/dashboard"
            element={
              <DashboardOverviewPage
                onSelectChild={(childId) => navigate(`/children/${childId}`)}
                onNavigateToChildren={() => navigate('/children')}
                onReferralCodeLoaded={(code) => setDynamicReferralCode(code)}
              />
            }
          />
          <Route
            path="/children"
            element={
              <ChildrenDirectoryPage
                onSelectChild={(childId) => navigate(`/children/${childId}`)}
                externalSearch={globalSearch}
              />
            }
          />
          <Route
            path="/children/:id"
            element={<ChildDetailPage onBack={() => navigate('/children')} />}
          />
          <Route
            path="/requests"
            element={
              <ConnectionRequestsPage
                onNavigateToChild={(childId) => navigate(`/children/${childId}`)}
              />
            }
          />
          <Route path="/plans" element={<ComingSoonView tab="plans" onNavigateTab={handleSelectTab} />} />
          <Route path="/sessions" element={<ComingSoonView tab="sessions" onNavigateTab={handleSelectTab} />} />
          <Route path="/notes" element={<ComingSoonView tab="notes" onNavigateTab={handleSelectTab} />} />
          <Route path="/progress" element={<ComingSoonView tab="progress" onNavigateTab={handleSelectTab} />} />
          <Route path="/settings" element={<ComingSoonView tab="settings" onNavigateTab={handleSelectTab} />} />
          <Route
            path="/change-password"
            element={<ChangePasswordPage onBack={() => navigate('/dashboard')} />}
          />
          {/* If authenticated user visits /login or /register, redirect to /dashboard */}
          <Route path="/login" element={<Navigate to="/dashboard" replace />} />
          <Route path="/register" element={<Navigate to="/dashboard" replace />} />
          <Route path="/forgot-password" element={<Navigate to="/dashboard" replace />} />
          <Route path="/verify-otp" element={<Navigate to="/dashboard" replace />} />
          <Route path="/verify-email" element={<Navigate to="/dashboard" replace />} />
          <Route path="/reset-password" element={<Navigate to="/dashboard" replace />} />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </main>
    </div>
  );
}

export default App;

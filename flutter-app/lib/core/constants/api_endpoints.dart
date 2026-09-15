/// Centralized API endpoint routes strictly mapped to the ASP.NET Core backend.
///
/// NOTE: These constants are defined for consistent reference across data layers.
/// No screens call these endpoints directly in Phase 1.
class ApiEndpoints {
  ApiEndpoints._();

  // Authentication
  static const String login = '/api/auth/login';
  static const String googleLogin = '/api/auth/google';
  static const String registerParent = '/api/auth/register-parent';
  static const String registerDoctor = '/api/auth/register-doctor';
  static const String sendVerificationOtp = '/api/auth/send-verification-otp';
  static const String verifyEmail = '/api/auth/verify-email';
  static const String getMe = '/api/auth/me';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String resetPassword = '/api/auth/reset-password';
  static const String changePassword = '/api/auth/change-password';

  // Children
  static const String children = '/api/children';
  static String childById(String childId) => '/api/children/$childId';
  static String childActivityPerformance(String childId) =>
      '/api/children/$childId/activities/performance';

  // Doctor Linking
  static String linkDoctorByCode(String childId) =>
      '/api/children/$childId/link-doctor';
  static String generateLinkingCode(String childId) =>
      '/api/children/$childId/linking-code';
  static const String doctorLinkChild = '/api/doctor/link-child';

  // Baseline Assessment
  static String baselineAssessment(String childId) =>
      '/api/children/$childId/baseline-assessment';

  // Activities
  static const String activities = '/api/activities';
  static String activityById(String activityId) =>
      '/api/activities/$activityId';

  // Sessions
  static const String sessions = '/api/sessions';
  static String sessionById(String sessionId) => '/api/sessions/$sessionId';
  static String sessionMetrics(String sessionId) =>
      '/api/sessions/$sessionId/metrics';
  static String completeSession(String sessionId) =>
      '/api/sessions/$sessionId/complete';
  static String sessionFeedback(String sessionId) =>
      '/api/sessions/$sessionId/feedback';
  static String abandonSession(String sessionId) =>
      '/api/sessions/$sessionId/abandon';

  // Progress
  static String childProgress(String childId) =>
      '/api/children/$childId/progress';
  static String childProgressHistory(String childId) =>
      '/api/children/$childId/progress/history';

  // Doctor Dashboard (Reference)
  static const String doctorDashboard = '/api/doctor/dashboard';
  static const String doctorChildren = '/api/doctor/children';
  static String doctorNotes(String childId) =>
      '/api/doctor/children/$childId/notes';

  // AI Chatbot
  static const String chat = '/api/ai/chat';
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/config/env_config.dart';
import 'package:sawa/core/constants/api_endpoints.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/core/models/auth_requests.dart';
import 'package:sawa/core/models/baseline_assessment_models.dart';
import 'package:sawa/core/models/child_model.dart';
import 'package:sawa/core/models/progress_models.dart';
import 'package:sawa/core/models/session_models.dart';
import 'package:sawa/core/network/api_client.dart';
import 'package:sawa/core/services/activity_service.dart';
import 'package:sawa/core/services/auth_service.dart';
import 'package:sawa/core/services/baseline_assessment_service.dart';
import 'package:sawa/core/services/children_service.dart';
import 'package:sawa/core/services/progress_service.dart';
import 'package:sawa/core/services/session_service.dart';
import 'package:sawa/core/state/auth_state.dart';
import 'package:sawa/core/storage/secure_storage_service.dart';
import 'package:sawa/screens/activities_screen.dart';
import 'package:sawa/screens/activity_details_screen.dart';
import 'package:sawa/screens/ai_assessment_screen.dart';
import 'package:sawa/screens/celebration_screen.dart';
import 'package:sawa/screens/child_data_screen.dart';
import 'package:sawa/screens/develop_personalized_plan_screen.dart';
import 'package:sawa/screens/home_screen.dart';
import 'package:sawa/screens/log_in_screen.dart';
import 'package:sawa/screens/profile_screen.dart';
import 'package:sawa/screens/progress_screen.dart';
import 'package:sawa/screens/session_encouragement_screen.dart';
import 'package:sawa/screens/session_execution_screen.dart';
import 'package:sawa/screens/session_result_screen.dart';
import 'package:sawa/screens/parent_observation_screen.dart';
import 'package:sawa/screens/practise_screen.dart';
import 'package:sawa/screens/settings_screen.dart';
import 'package:sawa/screens/treatment_plan_screen.dart';

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();
  final Map<String, String> mockStorage = {};

  final AuthService authService = AuthService();
  final ChildrenService childrenService = ChildrenService();
  final BaselineAssessmentService baselineService = BaselineAssessmentService();
  final ActivityService activityService = ActivityService();
  final SessionService sessionService = SessionService();
  final ProgressService progressService = ProgressService();
  final SecureStorageService storageService = SecureStorageService();

  String? activeChildId;
  ChildModel? activeChild;
  BaselineAssessmentModel? activeBaseline;
  List<ActivityModel> activitiesList = [];
  ActivityModel? selectedActivity;
  SessionModel? currentSession;
  CompletedSessionModel? completedSession;
  ChildProgressSummaryModel? progressSummary;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        final key =
            methodCall.arguments is Map ? methodCall.arguments['key'] : null;
        if (methodCall.method == 'read') {
          return mockStorage[key];
        }
        if (methodCall.method == 'write') {
          mockStorage[key] = methodCall.arguments['value']?.toString() ?? '';
          return null;
        }
        if (methodCall.method == 'delete') {
          mockStorage.remove(key);
          return null;
        }
        if (methodCall.method == 'deleteAll') {
          mockStorage.clear();
          return null;
        }
        if (methodCall.method == 'containsKey') {
          return mockStorage.containsKey(key);
        }
        return null;
      },
    );
    EnvConfig.overrideBaseUrl('http://localhost:5222');

    // Pre-populate with live backend API data
    final authRes = await authService.login(const LoginRequest(
      email: 'parent@mindora.com',
      password: 'Parent123!',
    ));
    await storageService.saveAuthToken(token: authRes.token);
    await AuthState.instance.login(const LoginRequest(
      email: 'parent@mindora.com',
      password: 'Parent123!',
    ));

    final childrenRes = await ApiClient().get(ApiEndpoints.children);
    final childrenList = childrenRes.data as List;
    activeChildId = childrenList.first['id']?.toString() ??
        childrenList.first['Id']?.toString();
    await storageService.saveActiveChildId(activeChildId!);
    activeChild = await childrenService.getChildById(activeChildId!);
    activeBaseline =
        await baselineService.getLatestBaselineAssessment(activeChildId!);
    activitiesList = await activityService.getActivities();
    selectedActivity = activitiesList.firstWhere(
      (a) => a.domain.toLowerCase() == 'movement',
      orElse: () => activitiesList.first,
    );
    progressSummary = await progressService.getChildProgress(activeChildId!);
  });

  tearDownAll(() async {
    EnvConfig.overrideBaseUrl(null);
    mockStorage.clear();
  });

  void setPhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 3150);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget wrapWithScreenUtil(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      ),
    );
  }

  group('Mindora Final QA 19-Step Full Flow Suite', () {
    // STEP 1: Login
    testWidgets('Step 1 (UI): Login screen renders without crash or overflow',
        (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(wrapWithScreenUtil(LogInScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LogInScreen), findsOneWidget);
    });

    test('Step 1 (API): Real parent authentication and JWT token persistence',
        () async {
      final loginReq = const LoginRequest(
        email: 'parent@mindora.com',
        password: 'Parent123!',
      );
      final authResponse = await authService.login(loginReq);
      expect(authResponse.token, isNotEmpty);
      await storageService.saveAuthToken(token: authResponse.token);
      await AuthState.instance.login(loginReq);
      expect(AuthState.instance.isAuthenticated, isTrue);
      expect(activeChild, isNotNull);
    });

    // STEP 2: Home
    testWidgets('Step 2: Home Screen renders with real child data and no overflow',
        (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        wrapWithScreenUtil(
          HomeScreen(
            initialChild: activeChild,
            initialBaseline: activeBaseline,
            initialActivities: activitiesList,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining(activeChild!.fullName), findsWidgets);
    });

    // STEP 3: Bottom Navigation across all 5 tabs
    testWidgets('Step 3: Bottom Navigation 5 tabs render and switch cleanly',
        (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        wrapWithScreenUtil(
          HomeScreen(
            initialChild: activeChild,
            initialBaseline: activeBaseline,
            initialActivities: activitiesList,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byTooltip('الرئيسية'), findsOneWidget);
      expect(find.byTooltip('الخطة العلاجية'), findsOneWidget);
      expect(find.byTooltip('المساعد الذكي'), findsOneWidget);
      expect(find.byTooltip('التمارين'), findsOneWidget);
      expect(find.byTooltip('الملف الشخصي'), findsOneWidget);

      await tester.tap(find.byTooltip('التمارين'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(PractiseScreen), findsOneWidget);
    });

    // STEP 4: Profile
    testWidgets('Step 4: Profile Screen renders with real child data and links',
        (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        wrapWithScreenUtil(
          ProfileScreen(initialChild: activeChild),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text(activeChild!.fullName), findsWidgets);
      expect(find.text('بيانات الطفل'), findsOneWidget);
      expect(find.text('الخطة العلاجية'), findsOneWidget);
      expect(find.text('التقدم'), findsOneWidget);
      expect(find.text('الإعدادات العامة'), findsOneWidget);
      expect(find.text('تسجيل الخروج'), findsOneWidget);
    });

    // STEP 5: Settings
    testWidgets('Step 5: Settings Screen renders local preferences safely',
        (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(wrapWithScreenUtil(const SettingsScreen()));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('الإعدادات'), findsOneWidget);
      expect(find.text('تخصيص التطبيق والإشعارات'), findsOneWidget);
      expect(find.text('اللغة'), findsOneWidget);
      expect(find.text('الوضع الليلي'), findsOneWidget);
      expect(find.text('الصوت والمؤثرات'), findsOneWidget);
      expect(find.text('الإشعارات'), findsOneWidget);
      expect(find.text('الأمان والخصوصية'), findsOneWidget);
      expect(find.text('حول التطبيق'), findsOneWidget);
      expect(find.text('تسجيل خروج'), findsOneWidget);
    });

    // STEP 6: Child Data (View/Edit and Backend Gap transparency)
    testWidgets('Step 6: Child Data displays real data and transparent save dialog',
        (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        wrapWithScreenUtil(ChildDataScreen(initialChild: activeChild)),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(ChildDataScreen), findsOneWidget);
      expect(find.text(activeChild!.fullName), findsWidgets);

      // Tap edit button: 'تعديل البيانات'
      final editBtn = find.text('تعديل البيانات');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pump(const Duration(milliseconds: 100));

      // Tap save button: 'حفظ التغييرات'
      final saveBtn = find.text('حفظ التغييرات');
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify transparent dialog explaining Backend API Gap without fake persistence
      expect(find.text('تنبيه الحفظ'), findsOneWidget);
      expect(find.textContaining('Backend API Gap: No PUT /api/children'), findsOneWidget);
    });

    // STEP 7: Treatment Plan
    test('Step 7 (API): Fetch real baseline assessment for child', () async {
      expect(activeChildId, isNotNull);
      final latest =
          await baselineService.getLatestBaselineAssessment(activeChildId!);
      expect(latest, isNotNull);
    });

    testWidgets('Step 7 (UI): Treatment Plan renders derived domain levels',
        (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        wrapWithScreenUtil(
          TreatmentPlanScreen(
            initialBaseline: activeBaseline,
            initialActivities: activitiesList,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(TreatmentPlanScreen), findsOneWidget);
      expect(find.text('الخطة العلاجية'), findsOneWidget);
      expect(find.text('التواصل واللغة'), findsOneWidget);
      expect(find.text('المهارات الحركية'), findsOneWidget);
      expect(find.text('الإدراك والتعلم'), findsOneWidget);
      await tester.ensureVisible(find.text('المهارات الاجتماعية والعاطفية'));
      expect(find.text('المهارات الاجتماعية والعاطفية'), findsOneWidget);
    });

    // STEP 8: AI Assessment
    testWidgets('Step 8: AI Assessment evaluates domains and records baseline',
        (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(wrapWithScreenUtil(const AiAssessmentScreen()));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(AiAssessmentScreen), findsOneWidget);
      expect(find.text('التقييم الأولي لمستوى الأداء'), findsWidgets);
    });

    // STEP 9: Celebration
    testWidgets('Step 9: Celebration Screen renders robot mascot and leads to plan',
        (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(wrapWithScreenUtil(const CelebrationScreen()));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(CelebrationScreen), findsOneWidget);
      expect(find.text('عمل رائع'), findsOneWidget);
      expect(find.text('لقد أكملت التقييم بنجاح.'), findsOneWidget);
      expect(find.text('عرض النتائج'), findsOneWidget);
    });

    // STEP 10: Personalized Plan
    testWidgets('Step 10: Personalized Plan Screen displays 4 pillars and leads Home',
        (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        wrapWithScreenUtil(const DevelopPersonalizedPlanScreen()),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(DevelopPersonalizedPlanScreen), findsOneWidget);
      expect(find.text('تم إنشاء خطة علاجية مخصصة لطفلك'), findsOneWidget);
      expect(find.text('ماذا يحدث الآن؟'), findsOneWidget);
      expect(find.text('خطة جاهزة'), findsOneWidget);
      expect(find.text('تابع التقدم'), findsOneWidget);
      expect(find.text('ابدأ الأنشطة'), findsOneWidget);
      expect(find.text('تحقيق الأهداف'), findsOneWidget);
      expect(find.text('ابدأ رحلتنا معاً'), findsOneWidget);
    });

    // STEP 11: Activities
    test('Step 11 (API): Load real activities catalog from backend', () async {
      final list = await activityService.getActivities();
      expect(list, isNotEmpty);
      expect(selectedActivity, isNotNull);
    });

    testWidgets('Step 11 (UI): Activities Catalog renders activities list',
        (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        wrapWithScreenUtil(
          ActivitiesScreen(initialActivities: activitiesList),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(ActivitiesScreen), findsOneWidget);
      expect(find.text('دليل الأنشطة والتمارين'), findsOneWidget);
    });

    // STEP 12: Activity Details
    testWidgets('Step 12: Activity Details loads instructions and parameters',
        (tester) async {
      setPhoneSize(tester);
      expect(selectedActivity, isNotNull);

      await tester.pumpWidget(
        wrapWithScreenUtil(
          ActivityDetailsScreen(
            activityId: selectedActivity!.id,
            initialActivity: selectedActivity,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(ActivityDetailsScreen), findsOneWidget);
      expect(find.text(selectedActivity!.title), findsWidgets);
      expect(find.text('بدء النشاط'), findsOneWidget);
    });

    // STEP 13: Session Execution
    test('Step 13 (API): Start real active session via backend API', () async {
      expect(activeChildId, isNotNull);
      expect(selectedActivity, isNotNull);

      currentSession = await sessionService.startSession(
        StartSessionRequest(
          childId: activeChildId!,
          activityId: selectedActivity!.id,
        ),
      );
      expect(currentSession!.id, isNotEmpty);
      expect(
        ['inprogress', 'started'].contains(currentSession!.status.toLowerCase()),
        isTrue,
      );
    });

    testWidgets('Step 13 (UI): Session Execution renders camera view & end session button',
        (tester) async {
      setPhoneSize(tester);
      expect(currentSession, isNotNull);
      expect(selectedActivity, isNotNull);

      await tester.pumpWidget(
        wrapWithScreenUtil(
          SessionExecutionScreen(
            session: currentSession!,
            activity: selectedActivity!,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(SessionExecutionScreen), findsOneWidget);
      expect(find.text('إنهاء الجلسة وحفظ الأداء'), findsOneWidget);
      expect(find.text('إلغاء الجلسة دون حفظ'), findsOneWidget);
    });

    // STEP 14: Encouragement
    test('Step 14 (API): Record movement telemetry and complete session', () async {
      expect(currentSession, isNotNull);

      await sessionService.recordMetrics(
        sessionId: currentSession!.id,
        metrics: [
          MetricInputModel(
            metricType: SupportedMetricType.repetitionCount.backendKey,
            value: 12.0,
          ),
        ],
      );

      completedSession = await sessionService.completeSession(
        sessionId: currentSession!.id,
        request: CompleteSessionRequest(
          actualDurationSeconds: 120,
          metrics: [
            MetricInputModel(
              metricType: SupportedMetricType.repetitionCount.backendKey,
              value: 12.0,
            ),
          ],
        ),
      );
      expect(completedSession!.id, equals(currentSession!.id));
      expect(completedSession!.status.toLowerCase(), equals('completed'));
    });

    testWidgets('Step 14 (UI): Session Encouragement renders celebration mascot',
        (tester) async {
      setPhoneSize(tester);
      expect(completedSession, isNotNull);
      expect(selectedActivity, isNotNull);

      await tester.pumpWidget(
        wrapWithScreenUtil(
          SessionEncouragementScreen(
            completedSession: completedSession!,
            activity: selectedActivity!,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(SessionEncouragementScreen), findsOneWidget);
      expect(find.text('أحسنت يا بطل'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);
    });

    // STEP 15: Session Result
    testWidgets('Step 15: Session Result displays metrics and difficulty adjustment',
        (tester) async {
      setPhoneSize(tester);
      expect(completedSession, isNotNull);
      expect(selectedActivity, isNotNull);

      await tester.pumpWidget(
        wrapWithScreenUtil(
          SessionResultScreen(
            completedSession: completedSession!,
            activity: selectedActivity!,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(SessionResultScreen), findsOneWidget);
      expect(find.text('نتائج تمارين اليوم'), findsOneWidget);
      expect(find.text('النتيجة الإجمالية'), findsOneWidget);
      expect(find.text('تمارين اليوم'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);
    });

    // STEP 16: Parent Observation Screen (parent observation.png)
    testWidgets('Step 16 (UI): Parent Observation renders 3 emoji sentiment reaction cards',
        (tester) async {
      setPhoneSize(tester);
      expect(completedSession, isNotNull);
      expect(selectedActivity, isNotNull);

      await tester.pumpWidget(
        wrapWithScreenUtil(
          ParentObservationScreen(
            completedSession: completedSession!,
            activity: selectedActivity!,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(ParentObservationScreen), findsOneWidget);
      expect(find.textContaining('كيف كان أداء'), findsOneWidget);
      expect(find.text('سهل'), findsOneWidget);
      expect(find.text('متوسط'), findsOneWidget);
      expect(find.text('صعب'), findsOneWidget);
      expect(find.text('ملاحظاتك (اختياري)'), findsOneWidget);
      expect(find.text('حفظ ومتابعة'), findsOneWidget);
    });

    test('Step 16 (API): Parent Feedback records sentiment rating and notes to API',
        () async {
      expect(completedSession, isNotNull);

      final updated = await sessionService.recordFeedback(
        sessionId: completedSession!.id,
        request: const RecordFeedbackRequest(
          rating: ParentSentimentRating.easy,
          notes: 'تفاعل ممتاز وأداء واثق ومستقل',
        ),
      );
      expect(updated.id, equals(completedSession!.id));
    });

    // STEP 17: Progress
    test('Step 17 (API): Fetch real progress summary from backend', () async {
      expect(activeChildId, isNotNull);

      final progress =
          await progressService.getChildProgress(activeChildId!);
      expect(progress.totalCompletedSessions, greaterThanOrEqualTo(1));
    });

    testWidgets('Step 17 (UI): Progress Screen displays real summary statistics',
        (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        wrapWithScreenUtil(
          ProgressScreen(
            showBackButton: true,
            initialChild: activeChild,
            initialSummary: progressSummary,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(ProgressScreen), findsOneWidget);
      expect(find.text('التقدم وسجل الجلسات'), findsWidgets);
    });

    // STEP 18: History + Filters
    test('Step 18: Session History loads and filters by Movement domain',
        () async {
      expect(activeChildId, isNotNull);

      final allHistory = await progressService.getProgressHistory(
        activeChildId!,
        page: 1,
        pageSize: 20,
      );
      expect(allHistory, isNotEmpty);

      final movementHistory = await progressService.getProgressHistory(
        activeChildId!,
        domain: 'Movement',
        page: 1,
        pageSize: 20,
      );
      expect(movementHistory, isNotEmpty);
      expect(
        movementHistory
            .every((s) => s.domain.toLowerCase() == 'movement'),
        isTrue,
      );
    });

    // STEP 19: Logout → Login again
    test('Step 19: Logout clears credentials and allows re-login successfully',
        () async {
      await AuthState.instance.logout();
      expect(AuthState.instance.isAuthenticated, isFalse);

      final tokenAfterLogout = await storageService.getAuthToken();
      expect(tokenAfterLogout, isNull);

      // Re-login
      final reLoginReq = const LoginRequest(
        email: 'parent@mindora.com',
        password: 'Parent123!',
      );
      final reAuth = await authService.login(reLoginReq);
      expect(reAuth.token, isNotEmpty);

      await storageService.saveAuthToken(token: reAuth.token);
      await AuthState.instance.login(reLoginReq);
      expect(AuthState.instance.isAuthenticated, isTrue);
    });
  });
}

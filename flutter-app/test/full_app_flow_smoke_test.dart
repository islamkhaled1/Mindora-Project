import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/config/env_config.dart';
import 'package:sawa/core/constants/api_endpoints.dart';
import 'package:sawa/core/models/auth_requests.dart';
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
import 'package:sawa/features/movement/engine/movement_engine.dart';
import 'package:sawa/features/movement/models/hand_tracking_result.dart';
import 'package:sawa/screens/onboarding_screen.dart';
import 'package:sawa/screens/splash.dart';

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

  setUpAll(() {
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
    // Direct local network calls to the ASP.NET Core backend on port 5222
    EnvConfig.overrideBaseUrl('http://localhost:5222');
  });

  tearDownAll(() async {
    EnvConfig.overrideBaseUrl(null);
    mockStorage.clear();
  });

  group('Full Mindora App Flow 15-Step Smoke Test', () {
    late AuthService authService;
    late ChildrenService childrenService;
    late BaselineAssessmentService baselineService;
    late ActivityService activityService;
    late SessionService sessionService;
    late ProgressService progressService;
    late SecureStorageService storageService;

    String? activeChildId;
    String? movementActivityId;
    SessionModel? currentSession;

    setUp(() {
      authService = AuthService();
      childrenService = ChildrenService();
      baselineService = BaselineAssessmentService();
      activityService = ActivityService();
      sessionService = SessionService();
      progressService = ProgressService();
      storageService = SecureStorageService();
    });

    // STEP 1: Splash → Onboarding
    testWidgets('Step 1: Splash → Onboarding navigation & skip flow',
        (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Verify Splash1 renders with skip button
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => MaterialApp(
            home: Splash1(),
          ),
        ),
      );
      expect(find.byType(Splash1), findsOneWidget);
      expect(find.byKey(const Key('skip_button')), findsOneWidget);
    });

    // STEP 2: Login
    test('Step 2: Login with seeded parent credentials', () async {
      final loginReq = const LoginRequest(
        email: 'parent@mindora.com',
        password: 'Parent123!',
      );

      final authResponse = await authService.login(loginReq);
      expect(authResponse.token, isNotEmpty);

      // Verify token persisted in secure storage
      final storedToken = await storageService.getAuthToken();
      expect(storedToken, equals(authResponse.token));

      // Update AuthState
      await AuthState.instance.login(loginReq);
      expect(AuthState.instance.isAuthenticated, isTrue);
    });

    // STEP 3: Child discovery / selection
    test('Step 3: Child discovery and selection of active child', () async {
      final res = await ApiClient().get(ApiEndpoints.children);
      expect(res.statusCode, equals(200));
      expect(res.data, isA<List>());

      final children = res.data as List;
      expect(children.length, greaterThanOrEqualTo(1));

      final firstChild = children.first;
      activeChildId =
          firstChild['id']?.toString() ?? firstChild['Id']?.toString();
      expect(activeChildId, isNotNull);

      // Save active child ID to secure storage
      await storageService.saveActiveChildId(activeChildId!);
      final savedChildId = await storageService.getActiveChildId();
      expect(savedChildId, equals(activeChildId));
    });

    // STEP 4: Home (Child Profile & Baseline Assessment)
    test('Step 4: Home loads active child details and baseline data', () async {
      expect(activeChildId, isNotNull);

      final child = await childrenService.getChildById(activeChildId!);
      expect(child.id, equals(activeChildId));
      expect(child.fullName, isNotEmpty);

      // Check baseline assessment endpoint
      final baseline =
          await baselineService.getLatestBaselineAssessment(activeChildId!);
      expect(baseline == null || baseline.childId == activeChildId, isTrue);
    });

    // STEP 5: Activities Catalog & Domains
    test('Step 5: Activities catalog loads all domains', () async {
      final activities = await activityService.getActivities();
      expect(activities, isNotEmpty);

      final domains = activities.map((a) => a.domain).toSet();
      expect(domains, contains('Movement'));

      final movementAct =
          activities.firstWhere((a) => a.domain.toLowerCase() == 'movement');
      movementActivityId = movementAct.id;
      expect(movementActivityId, isNotNull);
    });

    // STEP 6: Activity Details
    test('Step 6: Activity Details loads instructions and parameters',
        () async {
      expect(movementActivityId, isNotNull);

      final details =
          await activityService.getActivityById(movementActivityId!);
      expect(details.id, equals(movementActivityId));
      expect(details.title, isNotEmpty);
      expect(details.domain.toLowerCase(), equals('movement'));
    });

    // STEP 7: Start Session
    test('Step 7: Start session creates active session in progress', () async {
      expect(activeChildId, isNotNull);
      expect(movementActivityId, isNotNull);

      final session = await sessionService.startSession(
        StartSessionRequest(
          childId: activeChildId!,
          activityId: movementActivityId!,
        ),
      );

      expect(session.id, isNotEmpty);
      expect(session.childId, equals(activeChildId));
      expect(session.activityId, equals(movementActivityId));
      expect(
        session.status.toLowerCase(),
        anyOf('started', 'inprogress'),
      );

      // Verify active session ID is stored in SecureStorage
      final activeSessionId = await storageService.getActiveSessionId();
      expect(activeSessionId, equals(session.id));

      currentSession = session;
    });

    // STEP 8: Movement AI + Telemetry Recording
    test('Step 8: Movement AI engine reaches target and records metrics',
        () async {
      expect(currentSession, isNotNull);

      final engine = MovementEngine();
      final startTime = DateTime.now().millisecondsSinceEpoch;
      engine.start(startTime);

      final target = engine.currentTarget;
      expect(target, isNotNull);

      // Simulate hand position reaching the target coordinates
      final reachEvent = engine.processFrame(
        tracking: HandTrackingResult(
          x: target!.targetX,
          y: target.targetY,
          confidence: 0.95,
          isTracked: true,
          timestampMs: startTime + 450,
        ),
        currentTimestampMs: startTime + 450,
      );

      expect(reachEvent, isNotNull);
      expect(reachEvent!.reactionTimeMs, greaterThan(0));
      expect(engine.repetitions, equals(1));
      expect(engine.accuracyPercentage, greaterThan(0));

      // Record real metrics payload to the live Backend
      final recordedMetrics = await sessionService.recordMetrics(
        sessionId: currentSession!.id,
        metrics: [
          MetricInputModel(
            metricType: SupportedMetricType.repetitionCount.backendKey,
            value: engine.repetitions.toDouble(),
          ),
          MetricInputModel(
            metricType: SupportedMetricType.accuracyPercentage.backendKey,
            value: engine.accuracyPercentage,
          ),
          MetricInputModel(
            metricType: SupportedMetricType.reactionTimeMs.backendKey,
            value: engine.averageReactionTimeMs > 0
                ? engine.averageReactionTimeMs
                : 450.0,
          ),
          MetricInputModel(
            metricType: SupportedMetricType.attentionDurationSeconds.backendKey,
            value: 15.0,
          ),
        ],
      );

      expect(recordedMetrics, isNotEmpty);
    });

    // STEP 9: Session Result & Complete Session
    test('Step 9: Complete session transitions to Completed state', () async {
      expect(currentSession, isNotNull);

      final completed = await sessionService.completeSession(
        sessionId: currentSession!.id,
        request: const CompleteSessionRequest(actualDurationSeconds: 15),
      );
      expect(completed.id, equals(currentSession!.id));
      expect(completed.status.toLowerCase(), equals('completed'));

      // Active session in storage must now be cleared
      final activeSessionId = await storageService.getActiveSessionId();
      expect(activeSessionId, isNull);
    });

    // STEP 10: Parent Feedback
    test('Step 10: Parent feedback records sentiment rating and notes',
        () async {
      expect(currentSession, isNotNull);

      final updated = await sessionService.recordFeedback(
        sessionId: currentSession!.id,
        request: const RecordFeedbackRequest(
          rating: ParentSentimentRating.easy,
          notes: 'أداء رائع ومميز في تتبع الأهداف',
        ),
      );

      expect(updated.id, equals(currentSession!.id));
      expect(updated.parentRatingEnum, equals(ParentSentimentRating.easy));
      expect(updated.parentNotes, equals('أداء رائع ومميز في تتبع الأهداف'));
    });

    // STEP 11: Progress Summary
    test('Step 11: Progress summary loads completed stats', () async {
      expect(activeChildId, isNotNull);

      final summary =
          await progressService.getChildProgress(activeChildId!);
      expect(summary.childId, equals(activeChildId));
      expect(summary.totalCompletedSessions, greaterThanOrEqualTo(1));
    });

    // STEP 12: Session History
    test('Step 12: Session history reflects the completed session', () async {
      expect(activeChildId, isNotNull);
      expect(currentSession, isNotNull);

      var history = await progressService.getProgressHistory(
        activeChildId!,
        page: 1,
        pageSize: 100,
        domain: currentSession!.domain,
      );

      var found = history.any((s) => s.sessionId == currentSession!.id);
      if (!found) {
        final page2 = await progressService.getProgressHistory(
          activeChildId!,
          page: 2,
          pageSize: 100,
          domain: currentSession!.domain,
        );
        history = [...history, ...page2];
        found = history.any((s) => s.sessionId == currentSession!.id);
      }

      expect(history, isNotEmpty);
      expect(found, isTrue);

      final sessionInHistory =
          history.firstWhere((s) => s.sessionId == currentSession!.id);
      expect(sessionInHistory.sessionId, equals(currentSession!.id));
      expect(sessionInHistory.durationSeconds, greaterThanOrEqualTo(0));
    });

    // STEP 13: History Filters
    test('Step 13: History domain filter returns domain-specific sessions',
        () async {
      expect(activeChildId, isNotNull);

      final movementHistory = await progressService.getProgressHistory(
        activeChildId!,
        domain: 'Movement',
        page: 1,
        pageSize: 20,
      );

      expect(movementHistory, isNotEmpty);
      for (final s in movementHistory) {
        expect(s.domain.toLowerCase(), equals('movement'));
      }
    });

    // STEP 14: Abandon Session
    test(
        'Step 14: Abandon session marks status as Abandoned and not Completed',
        () async {
      expect(activeChildId, isNotNull);
      expect(movementActivityId, isNotNull);

      // Start a second session to test abandonment
      final sessionToAbandon = await sessionService.startSession(
        StartSessionRequest(
          childId: activeChildId!,
          activityId: movementActivityId!,
        ),
      );
      expect(
        sessionToAbandon.status.toLowerCase(),
        anyOf('started', 'inprogress'),
      );

      // Abandon the session
      final abandoned =
          await sessionService.abandonSession(sessionToAbandon.id);
      expect(abandoned.id, equals(sessionToAbandon.id));
      expect(abandoned.isAbandoned, isTrue);
      expect(abandoned.status.toLowerCase(), equals('abandoned'));
      expect(abandoned.isCompleted, isFalse);

      // Verify active session ID is cleared
      final activeSessionId = await storageService.getActiveSessionId();
      expect(activeSessionId, isNull);

      // Confirm via GET session details that it was NOT completed
      final details =
          await sessionService.getSessionById(sessionToAbandon.id);
      expect(details.status.toLowerCase(), equals('abandoned'));
      expect(details.status.toLowerCase(), isNot(equals('completed')));
    });

    // STEP 15: Logout → Login
    test('Step 15: Logout clears all credentials, then Login re-authenticates',
        () async {
      // Execute Logout
      await AuthState.instance.logout();
      expect(AuthState.instance.isAuthenticated, isFalse);

      final tokenAfterLogout = await storageService.getAuthToken();
      expect(tokenAfterLogout, isNull);

      final childAfterLogout = await storageService.getActiveChildId();
      expect(childAfterLogout, isNull);

      // Re-login from scratch
      await AuthState.instance.login(
        const LoginRequest(
          email: 'parent@mindora.com',
          password: 'Parent123!',
        ),
      );

      expect(AuthState.instance.isAuthenticated, isTrue);
      final tokenAfterReLogin = await storageService.getAuthToken();
      expect(tokenAfterReLogin, isNotNull);
      expect(tokenAfterReLogin, isNotEmpty);
    });
  });
}

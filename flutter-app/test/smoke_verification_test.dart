import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/core/models/baseline_assessment_models.dart';
import 'package:sawa/core/models/child_model.dart';
import 'package:sawa/core/models/session_models.dart';
import 'package:sawa/screens/ai_assessment_screen.dart';
import 'package:sawa/screens/ai_chat_screen.dart';
import 'package:sawa/screens/home_screen.dart';
import 'package:sawa/screens/parent_observation_screen.dart';
import 'package:sawa/screens/practise_screen.dart';
import 'package:sawa/screens/profile_screen.dart';
import 'package:sawa/screens/session_result_screen.dart';
import 'package:sawa/screens/treatment_plan_screen.dart';

import 'package:flutter/services.dart';
import 'package:sawa/core/config/env_config.dart';

void main() {
  final Map<String, String> mockStorage = {
    'active_child_id': 'test-child-1',
  };

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    EnvConfig.overrideBaseUrl('http://localhost:5222');
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
  });

  Widget wrapWithApp(Widget child) {
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

  final dummyChild = ChildModel.fromJson({
    'id': 'test-child-1',
    'parentId': 'parent-1',
    'fullName': 'عمر خالد',
    'dateOfBirth': '2019-05-01',
    'gender': 'Male',
  });

  final dummyBaseline = BaselineAssessmentModel.fromJson({
    'id': 'test-baseline-1',
    'childId': 'test-child-1',
    'overallScore': 82.5,
    'cognitiveScore': 80.0,
    'communicationScore': 75.0,
    'motorScore': 85.0,
    'emotionalScore': 90.0,
    'aiAnalysis': 'أداء متميز وتطور ملحوظ في التفاعل والاستجابة الحركية.',
    'recommendedPillars': ['Motor', 'Cognitive', 'Communication'],
  });

  final dummyActivity = ActivityModel.fromJson({
    'id': 'act-1',
    'title': 'تمرين التوازن الحركي',
    'description': 'تمرين تعزيز التوازن والتحكم الحركي للطفل',
    'domain': 'Movement',
    'durationMinutes': 10,
    'instructions': ['قف باستقامة', 'ارفع اليد اليمنى'],
  });

  final dummySession = CompletedSessionModel.fromJson({
    'id': 'session-1',
    'childId': 'test-child-1',
    'activityId': 'act-1',
    'domain': 'Movement',
    'status': 'Completed',
    'startTimeUtc': DateTime.now().toIso8601String(),
    'actualDurationSeconds': 600,
    'metrics': [],
    'analysisResult': {
      'score': 85.0,
      'encouragementMessage': 'عمل رائع!',
      'strengths': ['سرعة الاستجابة'],
      'improvements': ['التوازن'],
      'suggestedNextDifficulty': 'Medium',
    },
  });

  group('Final UI Smoke Tests', () {
    // 1. Home -> Bottom Navigation -> 5 tabs
    testWidgets('Smoke Test 1: Home -> Bottom Navigation -> 5 tabs switch cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithApp(HomeScreen(
        initialChild: dummyChild,
        initialBaseline: dummyBaseline,
        initialActivities: [dummyActivity],
      )));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byTooltip('الرئيسية'), findsOneWidget);
      expect(find.byTooltip('الخطة العلاجية'), findsOneWidget);
      expect(find.byTooltip('المساعد الذكي'), findsOneWidget);
      expect(find.byTooltip('التمارين'), findsOneWidget);
      expect(find.byTooltip('الملف الشخصي'), findsOneWidget);

      // Switch to Treatment Plan
      await tester.tap(find.byTooltip('الخطة العلاجية'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(TreatmentPlanScreen), findsOneWidget);

      // Switch to AI Chat
      await tester.tap(find.byTooltip('المساعد الذكي'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(AiChatScreen), findsOneWidget);

      // Switch to Practice
      await tester.tap(find.byTooltip('التمارين'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(PractiseScreen), findsOneWidget);

      // Switch to Profile
      await tester.tap(find.byTooltip('الملف الشخصي'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Return to Home
      await tester.tap(find.byTooltip('الرئيسية'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.textContaining('عمر'), findsWidgets);
    });

    // 2. AI Assessment -> Result AI -> Treatment Plan
    testWidgets('Smoke Test 2: AI Assessment -> Result AI -> Treatment Plan', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithApp(AiAssessmentScreen(initialResult: dummyBaseline)));
      await tester.pumpAndSettle();

      // Check gauge and labels
      expect(find.text('النتيجة الإجماليه'), findsOneWidget);
      expect(find.text('83%'), findsOneWidget);
      expect(find.text('جيد جدًا'), findsOneWidget);
      expect(find.text('المهارات الإدراكية'), findsOneWidget);
      expect(find.text('التواصل'), findsOneWidget);
      expect(find.text('المهارات الحركية'), findsOneWidget);
      expect(find.text('المهارات العاطفية'), findsOneWidget);
      expect(find.textContaining('يحرز طفلك تقدماً رائعاً'), findsOneWidget);
      expect(find.text('عرض الخطة العلاجية'), findsOneWidget);

      // Tap to navigate to Treatment Plan
      final buttonFinder = find.text('عرض الخطة العلاجية');
      await tester.ensureVisible(buttonFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(find.byType(TreatmentPlanScreen), findsOneWidget);
    });

    // 3. Practice -> Session -> Result -> Parent Observation -> Session Complete
    testWidgets('Smoke Test 3: Session Result Step 1 -> Parent Observation -> Session Complete Step 2', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Step 1: Result.png
      await tester.pumpWidget(wrapWithApp(SessionResultScreen(
        completedSession: dummySession,
        activity: dummyActivity,
      )));
      await tester.pumpAndSettle();

      expect(find.text('نتائج تمارين اليوم'), findsOneWidget);
      expect(find.text('النتيجة الإجمالية'), findsOneWidget);
      expect(find.text('85%'), findsWidgets);
      expect(find.text('تمارين اليوم'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);

      // Parent Observation: parent observation.png
      await tester.pumpWidget(wrapWithApp(ParentObservationScreen(
        completedSession: dummySession,
        activity: dummyActivity,
      )));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.textContaining('كيف كان أداء'), findsOneWidget);
      expect(find.text('سهل'), findsOneWidget);
      expect(find.text('متوسط'), findsOneWidget);
      expect(find.text('صعب'), findsOneWidget);
      expect(find.text('حفظ ومتابعة'), findsOneWidget);

      // Step 2: session complete.png
      await tester.pumpWidget(wrapWithApp(SessionResultScreen(
        completedSession: dummySession,
        activity: dummyActivity,
        initialStep: 2,
      )));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('انتهت الجلسة'), findsOneWidget);
      expect(find.text('ملخص الجلسة'), findsOneWidget);
      expect(find.text('الوقت الكلي'), findsOneWidget);
      expect(find.text('متوسط الأداء'), findsOneWidget);
      expect(find.text('تمارين مكتملة'), findsOneWidget);
      expect(find.text('العوده للرئيسية'), findsOneWidget);
      expect(find.text('عرض التقدم'), findsOneWidget);
    });

    // 4. AI Chat -> Welcome -> Start Chat
    testWidgets('Smoke Test 4: AI Chat -> Welcome state -> Start active chat', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithApp(const AiChatScreen()));
      await tester.pump(const Duration(milliseconds: 150));

      // Welcome state
      expect(find.text('مساعد الذكاء الاصطناعي'), findsOneWidget);
      expect(find.text('بدء المحادثة'), findsOneWidget);

      // Tap to start chat
      await tester.tap(find.text('بدء المحادثة'));
      await tester.pump(const Duration(milliseconds: 200));

      // Active chat
      expect(find.text('المساعد الذكي Mindora'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });
  });
}

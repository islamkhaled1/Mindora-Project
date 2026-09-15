import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/models/activity_models.dart';
import 'package:sawa/core/models/session_models.dart';
import 'package:sawa/screens/parent_observation_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  final dummySession = CompletedSessionModel(
    id: 'session-123',
    childId: 'child-123',
    activityId: 'act-123',
    domain: 'Communication',
    status: 'Completed',
    startTimeUtc: DateTime.now().subtract(const Duration(minutes: 10)),
    endTimeUtc: DateTime.now(),
    actualDurationSeconds: 600,
    metrics: const [],
  );

  const dummyActivity = ActivityModel(
    id: 'act-123',
    title: 'تمرين النطق',
    description: 'تمرين لتحسين النطق والتواصل',
    domain: 'Communication',
    baseDifficulty: 'Medium',
  );

  Widget createObservationScreen() {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          home: ParentObservationScreen(
            completedSession: dummySession,
            activity: dummyActivity,
            childName: 'أحمد',
          ),
        );
      },
    );
  }

  testWidgets('ParentObservationScreen renders sentiments, handles selection and text input', (WidgetTester tester) async {
    await tester.pumpWidget(createObservationScreen());
    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('كيف كان أداء أحمد اليوم؟'), findsOneWidget);
    expect(find.text('ملاحظاتك تساعدنا على تحسين الخطة.'), findsOneWidget);

    // Verify Sentiment options
    expect(find.text('سهل'), findsOneWidget);
    expect(find.text('متوسط'), findsOneWidget);
    expect(find.text('صعب'), findsOneWidget);

    // Select 'سهل' sentiment
    await tester.tap(find.text('سهل'));
    await tester.pumpAndSettle();

    // Enter notes
    final notesField = find.byType(TextField);
    expect(notesField, findsOneWidget);
    await tester.enterText(notesField, 'الطفل كان متفاعلاً وسعيداً جداً');
    await tester.pumpAndSettle();

    // Verify button
    expect(find.text('حفظ ومتابعة'), findsOneWidget);
  });
}

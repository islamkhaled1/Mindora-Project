import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/attention/attention_audio_service.dart';
import 'package:sawa/core/attention/attention_session_engine.dart';
import 'package:sawa/screens/attention_screen.dart';
import 'package:sawa/screens/encouragement_screen.dart';

void setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3150);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildTestableAttentionScreen({
  AttentionSessionEngine? engine,
  AttentionAudioService? audioService,
}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: AttentionScreen(
          engine: engine,
          audioService: audioService,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AttentionScreen Widget & Flow Tests', () {
    testWidgets('1. Initial render displays app bar, AiStatusBanner, round 1 of 4, and 4 items',
        (tester) async {
      setPhoneSize(tester);
      final mockAudio = NoOpAttentionAudioService();
      final engine = AttentionSessionEngine(random: Random(42));

      await tester.pumpWidget(buildTestableAttentionScreen(
        engine: engine,
        audioService: mockAudio,
      ));
      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('اسمع وابحث'), findsOneWidget);

      // Verify AiStatusBanner
      expect(find.text('التحليل الذكي المتقدم قريبًا'), findsOneWidget);

      // Verify Round Indicator
      expect(find.text('الجولة 1 من 4'), findsOneWidget);

      // Verify Prompt Text
      expect(find.text(engine.currentTarget.promptText), findsOneWidget);

      // Verify 4 Image widgets rendered in Grid
      expect(find.byType(Image), findsNWidgets(4));

      // Verify audio instruction was triggered on load
      expect(mockAudio.playCount, equals(1));
      expect(mockAudio.lastPlayedAsset, equals(engine.currentTarget.audioPath));
    });

    testWidgets('2. Replay button and speaker icon trigger audio instruction without resetting timer',
        (tester) async {
      setPhoneSize(tester);
      final mockAudio = NoOpAttentionAudioService();
      var simulatedTime = DateTime(2026, 9, 13, 10, 0, 0);

      final engine = AttentionSessionEngine(
        random: Random(42),
        nowProvider: () => simulatedTime,
      );

      await tester.pumpWidget(buildTestableAttentionScreen(
        engine: engine,
        audioService: mockAudio,
      ));
      await tester.pumpAndSettle();

      final initialStartTime = engine.roundStartTime;
      expect(mockAudio.playCount, equals(1));

      // Advance simulated time
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 500));

      // Tap 'اسمع مرة أخرى' button
      await tester.tap(find.text('اسمع مرة أخرى'));
      await tester.pump();

      expect(mockAudio.playCount, equals(2));
      expect(mockAudio.lastPlayedAsset, equals(engine.currentTarget.audioPath));
      // Timing reference remains untouched
      expect(engine.roundStartTime, equals(initialStartTime));

      // Tap speaker icon
      await tester.tap(find.byKey(const Key('replay_speaker_button')));
      await tester.pump();

      expect(mockAudio.playCount, equals(3));
      expect(engine.roundStartTime, equals(initialStartTime));
    });

    testWidgets('3. Complete 4-round flow end-to-end and display final results view',
        (tester) async {
      setPhoneSize(tester);
      final mockAudio = NoOpAttentionAudioService();
      var simulatedTime = DateTime(2026, 9, 13, 10, 0, 0);

      final engine = AttentionSessionEngine(
        random: Random(42),
        nowProvider: () => simulatedTime,
      );

      await tester.pumpWidget(buildTestableAttentionScreen(
        engine: engine,
        audioService: mockAudio,
      ));
      await tester.pumpAndSettle();

      // Play 4 rounds: 3 correct, 1 wrong
      for (int round = 0; round < 4; round++) {
        expect(find.text('الجولة ${round + 1} من 4'), findsOneWidget);
        final target = engine.currentTarget;

        // On round 2 (0-indexed 1), intentionally tap wrong shape
        final itemToTap = (round == 1)
            ? engine.currentOptions.firstWhere((i) => i.id != target.id)
            : target;

        // Advance simulated time by 750ms for reaction time
        simulatedTime = simulatedTime.add(const Duration(milliseconds: 750));

        // Tap the card via Key
        final cardFinder = find.byKey(Key('shape_card_${itemToTap.id}'));
        expect(cardFinder, findsOneWidget);
        await tester.tap(cardFinder);
        await tester.pump();

        if (round == 1) {
          expect(find.text('إجابة خاطئة'), findsOneWidget);
        } else {
          expect(find.text('إجابة صحيحة!'), findsOneWidget);
        }

        // Test duplicate tap prevention: tapping again should be ignored
        await tester.tap(cardFinder);
        await tester.pump();

        // Advance time past the 1.2s auto-transition
        simulatedTime = simulatedTime.add(const Duration(milliseconds: 1300));
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();
      }

      // Verification of Final Result View
      expect(find.text('نتائج التمرين'), findsOneWidget);
      expect(find.text('الإجابات الصحيحة'), findsOneWidget);
      expect(find.text('3 من 4'), findsOneWidget);

      expect(find.text('الإجابات الخاطئة'), findsOneWidget);
      expect(find.text('1 من 4'), findsOneWidget);

      expect(find.text('الدقة'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);

      expect(find.text('متوسط سرعة الاستجابة'), findsOneWidget);
      expect(find.text('0.75 ثانية'), findsOneWidget);

      // Verify Actions
      expect(find.text('إعادة التمرين'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);

      // Tap 'التالي' to navigate to EncouragementScreen
      await tester.tap(find.byKey(const Key('next_session_button')));
      await tester.pumpAndSettle();

      expect(find.byType(EncouragementScreen), findsOneWidget);
      expect(find.text('تم إكمال جميع الأنشطة بنجاح'), findsOneWidget);
    });

    testWidgets('4. Restart button resets session back to Round 1 of 4',
        (tester) async {
      setPhoneSize(tester);
      final mockAudio = NoOpAttentionAudioService();
      final engine = AttentionSessionEngine(random: Random(42));

      await tester.pumpWidget(buildTestableAttentionScreen(
        engine: engine,
        audioService: mockAudio,
      ));
      await tester.pumpAndSettle();

      // Complete 4 rounds quickly
      for (int round = 0; round < 4; round++) {
        final target = engine.currentTarget;
        final cardFinder = find.byKey(Key('shape_card_${target.id}'));
        expect(cardFinder, findsOneWidget);
        await tester.tap(cardFinder);
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();
      }

      expect(find.text('نتائج التمرين'), findsOneWidget);

      // Tap 'إعادة التمرين'
      await tester.tap(find.byKey(const Key('restart_session_button')));
      await tester.pumpAndSettle();

      // Should be back to Round 1 of 4
      expect(find.text('الجولة 1 من 4'), findsOneWidget);
      expect(engine.isSessionCompleted, isFalse);
      expect(engine.results.isEmpty, isTrue);
    });

    testWidgets('5. Results screen displays 6750 ms as "6.75 ثانية" and NEVER as "67.50 ثانية"',
        (tester) async {
      setPhoneSize(tester);
      final mockAudio = NoOpAttentionAudioService();
      var simulatedTime = DateTime(2026, 9, 14, 10, 0, 0);

      final engine = AttentionSessionEngine(
        random: Random(100),
        nowProvider: () => simulatedTime,
      );

      await tester.pumpWidget(buildTestableAttentionScreen(
        engine: engine,
        audioService: mockAudio,
      ));
      await tester.pumpAndSettle();

      // Complete 4 rounds: all correct with exact 6750 ms each
      for (int round = 0; round < 4; round++) {
        final target = engine.currentTarget;
        simulatedTime = simulatedTime.add(const Duration(milliseconds: 6750));

        final cardFinder = find.byKey(Key('shape_card_${target.id}'));
        await tester.tap(cardFinder);
        await tester.pump();

        simulatedTime = simulatedTime.add(const Duration(milliseconds: 1300));
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();
      }

      expect(find.text('نتائج التمرين'), findsOneWidget);
      expect(engine.averageReactionTimeMs, equals(6750.0));

      // Must display exactly "6.75 ثانية"
      expect(find.text('6.75 ثانية'), findsOneWidget);
      // Must NOT display "67.50 ثانية"
      expect(find.text('67.50 ثانية'), findsNothing);
    });

    testWidgets('6. Results screen displays 1000 ms as "1.00 ثانية"',
        (tester) async {
      setPhoneSize(tester);
      final mockAudio = NoOpAttentionAudioService();
      var simulatedTime = DateTime(2026, 9, 14, 10, 0, 0);

      final engine = AttentionSessionEngine(
        random: Random(101),
        nowProvider: () => simulatedTime,
      );

      await tester.pumpWidget(buildTestableAttentionScreen(
        engine: engine,
        audioService: mockAudio,
      ));
      await tester.pumpAndSettle();

      for (int round = 0; round < 4; round++) {
        final target = engine.currentTarget;
        simulatedTime = simulatedTime.add(const Duration(milliseconds: 1000));

        final cardFinder = find.byKey(Key('shape_card_${target.id}'));
        await tester.tap(cardFinder);
        await tester.pump();

        simulatedTime = simulatedTime.add(const Duration(milliseconds: 1300));
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();
      }

      expect(find.text('نتائج التمرين'), findsOneWidget);
      expect(engine.averageReactionTimeMs, equals(1000.0));
      expect(find.text('1.00 ثانية'), findsOneWidget);
    });

    testWidgets('7. Results screen averages reaction time for successful rounds only',
        (tester) async {
      setPhoneSize(tester);
      final mockAudio = NoOpAttentionAudioService();
      var simulatedTime = DateTime(2026, 9, 14, 10, 0, 0);

      final engine = AttentionSessionEngine(
        random: Random(102),
        nowProvider: () => simulatedTime,
      );

      await tester.pumpWidget(buildTestableAttentionScreen(
        engine: engine,
        audioService: mockAudio,
      ));
      await tester.pumpAndSettle();

      // Round 1: Correct with 1500 ms
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 1500));
      await tester.tap(find.byKey(Key('shape_card_${engine.currentTarget.id}')));
      await tester.pump();
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 1300));
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      // Rounds 2-4: Wrong with 8000 ms each
      for (int round = 1; round < 4; round++) {
        final wrongItem = engine.currentOptions.firstWhere((i) => i.id != engine.currentTarget.id);
        simulatedTime = simulatedTime.add(const Duration(milliseconds: 8000));
        await tester.tap(find.byKey(Key('shape_card_${wrongItem.id}')));
        await tester.pump();
        simulatedTime = simulatedTime.add(const Duration(milliseconds: 1300));
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();
      }

      expect(find.text('نتائج التمرين'), findsOneWidget);
      expect(find.text('1 من 4'), findsOneWidget); // 1 correct
      // Average reaction time must be strictly from the 1 correct round (1500 ms -> 1.50 ثانية)
      // and must NOT include the 8000 ms wrong rounds
      expect(engine.averageReactionTimeMs, equals(1500.0));
      expect(find.text('1.50 ثانية'), findsOneWidget);
    });
  });
}

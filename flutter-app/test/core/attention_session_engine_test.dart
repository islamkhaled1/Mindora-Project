import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/attention/attention_session_engine.dart';

void main() {
  group('AttentionSessionEngine Unit Tests', () {
    test('1. Asset Mappings: correct audio, image, and labels for all 4 items', () {
      expect(AttentionItem.car.id, equals('car'));
      expect(AttentionItem.car.imagePath, equals('assets/images/car.png'));
      expect(AttentionItem.car.audioPath, equals('assets/audio/car.mp3'));

      expect(AttentionItem.cat.id, equals('cat'));
      expect(AttentionItem.cat.imagePath, equals('assets/images/cat.png'));
      expect(AttentionItem.cat.audioPath, equals('assets/audio/cat.mp3'));

      // Case-sensitive check for Ball.png
      expect(AttentionItem.ball.id, equals('ball'));
      expect(AttentionItem.ball.imagePath, equals('assets/images/Ball.png'));
      expect(AttentionItem.ball.audioPath, equals('assets/audio/ball.mp3'));

      expect(AttentionItem.star.id, equals('star'));
      expect(AttentionItem.star.imagePath, equals('assets/images/star.png'));
      expect(AttentionItem.star.audioPath, equals('assets/audio/star.mp3'));
    });

    test('2. Exactly 4 rounds per session', () {
      final engine = AttentionSessionEngine();
      expect(AttentionSessionEngine.totalRounds, equals(4));
      expect(engine.targetsSequence.length, equals(4));
      expect(engine.roundLayouts.length, equals(4));
    });

    test('3. No duplicate targets: each target appears exactly once in the session', () {
      final engine = AttentionSessionEngine();
      final targetIds = engine.targetsSequence.map((t) => t.id).toList();
      expect(targetIds.toSet().length, equals(4));
      expect(targetIds.contains('car'), isTrue);
      expect(targetIds.contains('cat'), isTrue);
      expect(targetIds.contains('ball'), isTrue);
      expect(targetIds.contains('star'), isTrue);
    });

    test('4. Randomized target order across different random seeds', () {
      // With different seeds, target sequences should show permutation variety
      final sequences = <String>{};
      for (int seed = 0; seed < 30; seed++) {
        final engine = AttentionSessionEngine(random: Random(seed));
        final order = engine.targetsSequence.map((t) => t.id).join(',');
        sequences.add(order);
      }
      // There are 24 permutations; 30 different seeds will produce multiple distinct sequences
      expect(sequences.length, greaterThan(1));
    });

    test('5. Randomized shape positions: all 4 items present in every round layout', () {
      final engine = AttentionSessionEngine(random: Random(42));
      for (int r = 0; r < 4; r++) {
        final layoutIds = engine.roundLayouts[r].map((i) => i.id).toSet();
        expect(layoutIds.length, equals(4));
        expect(layoutIds.contains('car'), isTrue);
        expect(layoutIds.contains('cat'), isTrue);
        expect(layoutIds.contains('ball'), isTrue);
        expect(layoutIds.contains('star'), isTrue);
      }
    });

    test('6. No identical consecutive layouts in any session', () {
      // Test across multiple sessions and seeds to verify consecutive layout invariance
      for (int seed = 0; seed < 50; seed++) {
        final engine = AttentionSessionEngine(random: Random(seed));
        for (int r = 1; r < 4; r++) {
          final prevLayout = engine.roundLayouts[r - 1].map((i) => i.id).toList();
          final currLayout = engine.roundLayouts[r].map((i) => i.id).toList();
          final isIdentical = prevLayout.length == currLayout.length &&
              List.generate(prevLayout.length, (i) => prevLayout[i] == currLayout[i])
                  .every((match) => match);
          expect(isIdentical, isFalse,
              reason: 'Consecutive layouts at rounds ${r - 1} and $r must not be identical (seed $seed)');
        }
      }
    });

    test('7. Correct answer evaluation updates correctAnswers count', () {
      final engine = AttentionSessionEngine(random: Random(100));
      final target = engine.currentTarget;

      final res = engine.recordAnswer(target.id);
      expect(res, isNotNull);
      expect(res!.isCorrect, isTrue);
      expect(res.selectedId, equals(target.id));
      expect(engine.correctAnswers, equals(1));
      expect(engine.wrongAnswers, equals(0));
    });

    test('8. Wrong answer evaluation updates wrongAnswers count', () {
      final engine = AttentionSessionEngine(random: Random(100));
      final target = engine.currentTarget;
      final wrongId = AttentionItem.allItems.firstWhere((i) => i.id != target.id).id;

      final res = engine.recordAnswer(wrongId);
      expect(res, isNotNull);
      expect(res!.isCorrect, isFalse);
      expect(res.selectedId, equals(wrongId));
      expect(engine.correctAnswers, equals(0));
      expect(engine.wrongAnswers, equals(1));
    });

    test('9. Duplicate answer prevention: ignores subsequent taps in same round', () {
      final engine = AttentionSessionEngine(random: Random(100));
      final target = engine.currentTarget;

      final firstRes = engine.recordAnswer(target.id);
      expect(firstRes, isNotNull);
      expect(engine.hasAnsweredCurrentRound, isTrue);

      // Attempt second tap with wrong id
      final secondRes = engine.recordAnswer('cat');
      expect(secondRes, isNull);

      // Attempt third tap
      final thirdRes = engine.recordAnswer('car');
      expect(thirdRes, isNull);

      // Counts remain untouched
      expect(engine.results.length, equals(1));
      expect(engine.correctAnswers, equals(1));
    });

    test('10. Reaction time calculation using injected nowProvider', () {
      var simulatedTime = DateTime(2026, 9, 13, 10, 0, 0);

      final engine = AttentionSessionEngine(
        random: Random(1),
        nowProvider: () => simulatedTime,
      );

      // Advance time by 850 milliseconds
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 850));

      final target = engine.currentTarget;
      final result = engine.recordAnswer(target.id);

      expect(result, isNotNull);
      expect(result!.reactionTimeMs, equals(850));
    });

    test('11. Replay behavior: does not reset roundStartTime or timer reference', () {
      var simulatedTime = DateTime(2026, 9, 13, 10, 0, 0);

      final engine = AttentionSessionEngine(
        random: Random(1),
        nowProvider: () => simulatedTime,
      );

      final initialStartTime = engine.roundStartTime;
      expect(initialStartTime, equals(simulatedTime));

      // Advance time by 400ms and simulate user pressing Replay
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 400));
      final audioPath = engine.currentAudioPath;
      expect(audioPath, equals(engine.currentTarget.audioPath));

      // Replay should NOT alter roundStartTime
      expect(engine.roundStartTime, equals(initialStartTime));

      // Advance another 300ms (total 700ms from start) and answer
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 300));
      final result = engine.recordAnswer(engine.currentTarget.id);

      expect(result!.reactionTimeMs, equals(700));
    });

    test('12. Final score calculation: correctAnswers / 4 * 100', () {
      final engine = AttentionSessionEngine(random: Random(10));

      // Round 1: Correct
      engine.recordAnswer(engine.currentTarget.id);
      engine.nextRound();

      // Round 2: Correct
      engine.recordAnswer(engine.currentTarget.id);
      engine.nextRound();

      // Round 3: Wrong
      final wrongId = AttentionItem.allItems.firstWhere((i) => i.id != engine.currentTarget.id).id;
      engine.recordAnswer(wrongId);
      engine.nextRound();

      // Round 4: Correct
      engine.recordAnswer(engine.currentTarget.id);

      expect(engine.isSessionCompleted, isTrue);
      expect(engine.correctAnswers, equals(3));
      expect(engine.wrongAnswers, equals(1));
      expect(engine.score, equals(75.0));
      expect(engine.accuracy, equals(75.0));
    });

    test('13. Average Reaction Time: strictly calculated from successful rounds only', () {
      var simulatedTime = DateTime(2026, 9, 13, 10, 0, 0);

      final engine = AttentionSessionEngine(
        random: Random(10),
        nowProvider: () => simulatedTime,
      );

      // Round 1: Correct, reaction time 600ms
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 600));
      engine.recordAnswer(engine.currentTarget.id);

      // Advance to round 2
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 1000));
      engine.nextRound();

      // Round 2: WRONG, reaction time 4000ms (MUST BE EXCLUDED!)
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 4000));
      final wrongId = AttentionItem.allItems.firstWhere((i) => i.id != engine.currentTarget.id).id;
      engine.recordAnswer(wrongId);

      // Advance to round 3
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 1000));
      engine.nextRound();

      // Round 3: Correct, reaction time 1200ms
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 1200));
      engine.recordAnswer(engine.currentTarget.id);

      // Advance to round 4
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 1000));
      engine.nextRound();

      // Round 4: Correct, reaction time 900ms
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 900));
      engine.recordAnswer(engine.currentTarget.id);

      // Successful rounds: 600, 1200, 900
      // Sum = 2700, count = 3 -> Average = 900ms.
      // (If wrong answer 4000 was included, average would have been (600 + 4000 + 1200 + 900) / 4 = 1675ms)
      expect(engine.correctAnswers, equals(3));
      expect(engine.wrongAnswers, equals(1));
      expect(engine.averageReactionTimeMs, equals(900.0));
    });

    test('14. Average Reaction Time returns 0.0 when 0 correct answers', () {
      final engine = AttentionSessionEngine(random: Random(10));
      for (int i = 0; i < 4; i++) {
        final wrongId = AttentionItem.allItems.firstWhere((item) => item.id != engine.currentTarget.id).id;
        engine.recordAnswer(wrongId);
        if (i < 3) engine.nextRound();
      }
      expect(engine.correctAnswers, equals(0));
      expect(engine.wrongAnswers, equals(4));
      expect(engine.averageReactionTimeMs, equals(0.0));
      expect(engine.formattedAverageReactionTimeSeconds, equals('غير متوفر'));
    });

    test('15. 1000 ms displays as 1.00 seconds ("1.00 ثانية")', () {
      // Direct utility check
      expect(AttentionSessionEngine.formatMillisecondsToSeconds(1000.0), equals('1.00 ثانية'));

      // Engine integration check
      var simulatedTime = DateTime(2026, 9, 14, 12, 0, 0);
      final engine = AttentionSessionEngine(
        random: Random(1),
        nowProvider: () => simulatedTime,
      );

      // Round 1: answer correctly after 1000 ms
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 1000));
      engine.recordAnswer(engine.currentTarget.id);

      // Complete remaining 3 rounds with wrong answers
      for (int i = 1; i < 4; i++) {
        engine.nextRound();
        simulatedTime = simulatedTime.add(const Duration(milliseconds: 5000));
        final wrongId = AttentionItem.allItems.firstWhere((item) => item.id != engine.currentTarget.id).id;
        engine.recordAnswer(wrongId);
      }

      // Internal metric MUST be 1000.0 ms (milliseconds, NOT seconds)
      expect(engine.averageReactionTimeMs, equals(1000.0));
      // Display metric MUST be "1.00 ثانية"
      expect(engine.formattedAverageReactionTimeSeconds, equals('1.00 ثانية'));
    });

    test('16. 6750 ms displays as 6.75 seconds ("6.75 ثانية") and never as 67.50', () {
      // Direct utility check
      expect(AttentionSessionEngine.formatMillisecondsToSeconds(6750.0), equals('6.75 ثانية'));

      var simulatedTime = DateTime(2026, 9, 14, 12, 0, 0);
      final engine = AttentionSessionEngine(
        random: Random(2),
        nowProvider: () => simulatedTime,
      );

      // Round 1: answer correctly after 6500 ms
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 6500));
      engine.recordAnswer(engine.currentTarget.id);

      // Round 2: answer correctly after 7000 ms
      engine.nextRound();
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 7000));
      engine.recordAnswer(engine.currentTarget.id);

      // Round 3: wrong answer after 15000 ms (must be ignored in average)
      engine.nextRound();
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 15000));
      final wrongId3 = AttentionItem.allItems.firstWhere((item) => item.id != engine.currentTarget.id).id;
      engine.recordAnswer(wrongId3);

      // Round 4: wrong answer after 20000 ms (must be ignored in average)
      engine.nextRound();
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 20000));
      final wrongId4 = AttentionItem.allItems.firstWhere((item) => item.id != engine.currentTarget.id).id;
      engine.recordAnswer(wrongId4);

      // Average of successful rounds: (6500 + 7000) / 2 = 6750.0 ms
      expect(engine.correctAnswers, equals(2));
      expect(engine.wrongAnswers, equals(2));
      expect(engine.averageReactionTimeMs, equals(6750.0));

      // Formatted display MUST be "6.75 ثانية", NEVER "67.50 ثانية"
      expect(engine.formattedAverageReactionTimeSeconds, equals('6.75 ثانية'));
      expect(engine.formattedAverageReactionTimeSeconds, isNot(contains('67.50')));
    });

    test('17. 1250 ms displays as 1.25 seconds ("1.25 ثانية")', () {
      expect(AttentionSessionEngine.formatMillisecondsToSeconds(1250.0), equals('1.25 ثانية'));
    });

    test('18. Average reaction time uses successful rounds only and avoids double conversion', () {
      var simulatedTime = DateTime(2026, 9, 14, 12, 0, 0);
      final engine = AttentionSessionEngine(
        random: Random(3),
        nowProvider: () => simulatedTime,
      );

      // 4 rounds: 1 correct (2500ms), 3 wrong (8000ms each)
      simulatedTime = simulatedTime.add(const Duration(milliseconds: 2500));
      engine.recordAnswer(engine.currentTarget.id);

      for (int i = 1; i < 4; i++) {
        engine.nextRound();
        simulatedTime = simulatedTime.add(const Duration(milliseconds: 8000));
        final wrongId = AttentionItem.allItems.firstWhere((item) => item.id != engine.currentTarget.id).id;
        engine.recordAnswer(wrongId);
      }

      // Average is strictly from the single correct round (2500 ms)
      expect(engine.averageReactionTimeMs, equals(2500.0));
      // Display string converted exactly once to seconds
      expect(engine.formattedAverageReactionTimeSeconds, equals('2.50 ثانية'));
    });
  });
}

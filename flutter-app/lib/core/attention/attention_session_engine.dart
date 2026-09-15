import 'dart:math';

/// Representation of an interactive target item in the Attention Exercise.
class AttentionItem {
  final String id;
  final String label;
  final String imagePath;
  final String audioPath;
  final String promptText;

  const AttentionItem({
    required this.id,
    required this.label,
    required this.imagePath,
    required this.audioPath,
    required this.promptText,
  });

  static const AttentionItem car = AttentionItem(
    id: 'car',
    label: 'سيارة',
    imagePath: 'assets/images/car.png',
    audioPath: 'assets/audio/car.mp3',
    promptText: 'أين السيارة',
  );

  static const AttentionItem cat = AttentionItem(
    id: 'cat',
    label: 'قطة',
    imagePath: 'assets/images/cat.png',
    audioPath: 'assets/audio/cat.mp3',
    promptText: 'أين القطة',
  );

  static const AttentionItem ball = AttentionItem(
    id: 'ball',
    label: 'كرة',
    imagePath: 'assets/images/Ball.png',
    audioPath: 'assets/audio/ball.mp3',
    promptText: 'أين الكرة',
  );

  static const AttentionItem star = AttentionItem(
    id: 'star',
    label: 'نجمة',
    imagePath: 'assets/images/star.png',
    audioPath: 'assets/audio/star.mp3',
    promptText: 'أين النجمة',
  );

  static const List<AttentionItem> allItems = [car, cat, ball, star];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttentionItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AttentionItem(id: $id, label: $label)';
}

/// Evaluation result for a single round of the Attention Exercise.
class AttentionRoundResult {
  final int roundIndex;
  final AttentionItem target;
  final String selectedId;
  final bool isCorrect;
  final int reactionTimeMs;
  final DateTime answeredAt;

  const AttentionRoundResult({
    required this.roundIndex,
    required this.target,
    required this.selectedId,
    required this.isCorrect,
    required this.reactionTimeMs,
    required this.answeredAt,
  });

  @override
  String toString() =>
      'AttentionRoundResult(round: ${roundIndex + 1}, target: ${target.id}, selected: $selectedId, isCorrect: $isCorrect, reactionTimeMs: ${reactionTimeMs}ms)';
}

/// State engine managing the 4-round dynamic Attention session.
class AttentionSessionEngine {
  static const int totalRounds = 4;

  final Random _random;
  final DateTime Function() _nowProvider;

  final List<AttentionItem> _targets = [];
  final List<List<AttentionItem>> _roundLayouts = [];
  final List<AttentionRoundResult> _results = [];

  int _currentRoundIndex = 0;
  DateTime? _roundStartTime;
  bool _hasAnsweredCurrentRound = false;
  bool _isSessionStarted = false;
  bool _isSessionCompleted = false;

  AttentionSessionEngine({
    Random? random,
    DateTime Function()? nowProvider,
  })  : _random = random ?? Random(),
        _nowProvider = nowProvider ?? DateTime.now {
    startSession();
  }

  /// Initializes a new 4-round session with randomized targets and shape positions.
  void startSession() {
    _targets.clear();
    _roundLayouts.clear();
    _results.clear();
    _currentRoundIndex = 0;
    _hasAnsweredCurrentRound = false;
    _isSessionCompleted = false;
    _isSessionStarted = true;

    // 1. Target sequence: Shuffle all 4 items once at session start.
    // Each target appears exactly once across the 4 rounds.
    final targetList = List<AttentionItem>.from(AttentionItem.allItems)..shuffle(_random);
    _targets.addAll(targetList);

    // 2. Shape positions: Randomized in each round, preventing consecutive identical layouts.
    List<AttentionItem>? previousLayout;
    for (int i = 0; i < totalRounds; i++) {
      final layout = List<AttentionItem>.from(AttentionItem.allItems)..shuffle(_random);
      int attempts = 0;
      while (previousLayout != null &&
          _areLayoutsIdentical(layout, previousLayout) &&
          attempts < 10) {
        layout.shuffle(_random);
        attempts++;
      }
      if (previousLayout != null && _areLayoutsIdentical(layout, previousLayout)) {
        // Deterministic swap fallback if random produces the exact same permutation
        final temp = layout[0];
        layout[0] = layout[1];
        layout[1] = temp;
      }
      _roundLayouts.add(layout);
      previousLayout = layout;
    }

    startRound();
  }

  /// Begins timing for the current round once shapes and audio instruction are ready.
  void startRound() {
    _roundStartTime = _nowProvider();
    _hasAnsweredCurrentRound = false;
  }

  /// Evaluates the user's tapped selection.
  /// Accepts first tap only; rejects subsequent taps in the same round.
  AttentionRoundResult? recordAnswer(String selectedId) {
    if (_isSessionCompleted || _hasAnsweredCurrentRound || _roundStartTime == null) {
      return null;
    }

    _hasAnsweredCurrentRound = true;
    final now = _nowProvider();
    final elapsedMs = now.difference(_roundStartTime!).inMilliseconds;
    final reactionTimeMs = elapsedMs < 0 ? 0 : elapsedMs;
    final isCorrect = selectedId == currentTarget.id;

    final result = AttentionRoundResult(
      roundIndex: _currentRoundIndex,
      target: currentTarget,
      selectedId: selectedId,
      isCorrect: isCorrect,
      reactionTimeMs: reactionTimeMs,
      answeredAt: now,
    );

    _results.add(result);

    if (_currentRoundIndex >= totalRounds - 1) {
      _isSessionCompleted = true;
    }

    return result;
  }

  /// Advances to the next round if available.
  /// Returns true if advanced, false if session is completed.
  bool nextRound() {
    if (_currentRoundIndex < totalRounds - 1) {
      _currentRoundIndex++;
      startRound();
      return true;
    } else {
      _isSessionCompleted = true;
      return false;
    }
  }

  /// Replays the audio instruction for the current round.
  /// Does NOT reset the timer, round state, or scoring.
  String get currentAudioPath => currentTarget.audioPath;

  // State Getters
  int get currentRoundIndex => _currentRoundIndex;
  int get currentRoundNumber => _currentRoundIndex + 1;
  bool get hasAnsweredCurrentRound => _hasAnsweredCurrentRound;
  bool get isSessionStarted => _isSessionStarted;
  bool get isSessionCompleted => _isSessionCompleted;
  DateTime? get roundStartTime => _roundStartTime;

  AttentionItem get currentTarget => _targets[_currentRoundIndex];
  List<AttentionItem> get currentOptions => _roundLayouts[_currentRoundIndex];
  List<AttentionItem> get targetsSequence => List.unmodifiable(_targets);
  List<List<AttentionItem>> get roundLayouts => List.unmodifiable(_roundLayouts);
  List<AttentionRoundResult> get results => List.unmodifiable(_results);

  // Scoring Metrics
  int get correctAnswers => _results.where((r) => r.isCorrect).length;
  int get wrongAnswers => _results.where((r) => !r.isCorrect).length;

  /// Accuracy percentage: (correctAnswers / 4) * 100
  double get score => (_results.isEmpty) ? 0.0 : (correctAnswers / totalRounds) * 100.0;
  double get accuracy => score;

  /// Average reaction time for successful (correct) rounds only.
  /// Wrong answers are strictly excluded. Returns 0.0 if no correct answers.
  double get averageReactionTimeMs {
    final successfulRounds = _results.where((r) => r.isCorrect).toList();
    if (successfulRounds.isEmpty) return 0.0;
    final totalMs = successfulRounds.fold<int>(0, (sum, r) => sum + r.reactionTimeMs);
    return totalMs / successfulRounds.length;
  }

  /// Formatted average reaction time in seconds for UI display.
  /// Converts milliseconds to seconds exactly once (dividing by 1000.0).
  /// Examples:
  /// - 6750.0 ms -> "6.75 ثانية"
  /// - 1000.0 ms -> "1.00 ثانية"
  /// - 1250.0 ms -> "1.25 ثانية"
  /// If there are 0 correct answers, returns "غير متوفر".
  String get formattedAverageReactionTimeSeconds {
    if (correctAnswers == 0) return 'غير متوفر';
    return formatMillisecondsToSeconds(averageReactionTimeMs);
  }

  /// Converts milliseconds to formatted seconds string (e.g. 6750 ms -> "6.75 ثانية").
  /// Ensures consistent, single conversion from ms to seconds with 2 decimal places.
  static String formatMillisecondsToSeconds(double milliseconds) {
    final seconds = milliseconds / 1000.0;
    return '${seconds.toStringAsFixed(2)} ثانية';
  }

  static bool _areLayoutsIdentical(List<AttentionItem> a, List<AttentionItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}

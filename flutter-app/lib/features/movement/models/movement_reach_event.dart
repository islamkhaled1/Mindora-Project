/// Event emitted when the child's tracked hand reaches an active target.
class MovementReachEvent {
  final int targetId;
  final double handX;
  final double handY;
  final double targetX;
  final double targetY;
  final double distance;
  final double confidence;
  final int reactionTimeMs;
  final int timestampMs;

  const MovementReachEvent({
    required this.targetId,
    required this.handX,
    required this.handY,
    required this.targetX,
    required this.targetY,
    required this.distance,
    required this.confidence,
    required this.reactionTimeMs,
    required this.timestampMs,
  });

  @override
  String toString() =>
      'MovementReachEvent(targetId: $targetId, reactionTimeMs: $reactionTimeMs, '
      'dist: ${distance.toStringAsFixed(3)}, conf: ${confidence.toStringAsFixed(2)})';
}

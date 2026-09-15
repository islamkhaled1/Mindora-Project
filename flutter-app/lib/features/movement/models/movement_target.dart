/// Represents an interactive dynamic target in normalized coordinates.
class MovementTarget {
  final int targetId;

  /// Target x coordinate in normalized range [0.15, 0.85].
  final double targetX;

  /// Target y coordinate in normalized range [0.15, 0.85].
  final double targetY;

  /// Target radius in normalized space (default ~0.08).
  final double targetRadius;

  /// Millisecond timestamp when the target first appeared.
  final int appearedAtMs;

  /// Target expiration timeout in milliseconds (default 5000ms).
  final int timeoutMs;

  const MovementTarget({
    required this.targetId,
    required this.targetX,
    required this.targetY,
    this.targetRadius = 0.08,
    required this.appearedAtMs,
    this.timeoutMs = 5000,
  });

  /// Check whether target has timed out relative to [currentMs].
  bool isExpired(int currentMs) => (currentMs - appearedAtMs) >= timeoutMs;

  @override
  String toString() =>
      'MovementTarget(id: $targetId, pos: (${targetX.toStringAsFixed(2)}, ${targetY.toStringAsFixed(2)}), '
      'radius: $targetRadius, appeared: $appearedAtMs, timeout: ${timeoutMs}ms)';
}

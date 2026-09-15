/// Normalized hand tracking result abstraction for Movement AI.
/// Completely decoupled from the underlying camera or platform inference mechanism.
class HandTrackingResult {
  /// Normalized x coordinate in range [0.0, 1.0].
  final double x;

  /// Normalized y coordinate in range [0.0, 1.0].
  final double y;

  /// Tracking confidence score in range [0.0, 1.0].
  final double confidence;

  /// True if a hand is actively tracked with reliable landmarks.
  final bool isTracked;

  /// The landmark index used (e.g. 8 for index fingertip, 9 for MCP base).
  final int landmarkUsed;

  /// Timestamp in milliseconds when this tracking result was captured.
  final int timestampMs;

  /// Optional exact normalized coordinates for Landmark 8 (Index Fingertip)
  final double? landmark8X;
  final double? landmark8Y;

  /// Optional exact normalized coordinates for Landmark 9 (Palm Center / Middle MCP)
  final double? landmark9X;
  final double? landmark9Y;

  const HandTrackingResult({
    required this.x,
    required this.y,
    required this.confidence,
    required this.isTracked,
    this.landmarkUsed = 8,
    required this.timestampMs,
    this.landmark8X,
    this.landmark8Y,
    this.landmark9X,
    this.landmark9Y,
  });

  /// Factory for when no hand is detected or tracking was lost.
  const HandTrackingResult.untracked({int? timestampMs})
      : x = 0.0,
        y = 0.0,
        confidence = 0.0,
        isTracked = false,
        landmarkUsed = 0,
        timestampMs = timestampMs ?? 0,
        landmark8X = null,
        landmark8Y = null,
        landmark9X = null,
        landmark9Y = null;

  @override
  String toString() =>
      'HandTrackingResult(x: ${x.toStringAsFixed(3)}, y: ${y.toStringAsFixed(3)}, '
      'conf: ${confidence.toStringAsFixed(2)}, tracked: $isTracked, landmark: $landmarkUsed, '
      'lm8: (${landmark8X?.toStringAsFixed(3)}, ${landmark8Y?.toStringAsFixed(3)}), '
      'lm9: (${landmark9X?.toStringAsFixed(3)}, ${landmark9Y?.toStringAsFixed(3)}))';
}

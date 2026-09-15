/// Exponential Moving Average (EMA) smoother for 2D hand landmark coordinates.
/// Smooths jitter while preserving low-latency hand response.
class ExponentialMovingAverage {
  /// Smoothing factor alpha in range (0.0, 1.0].
  /// Higher values give more weight to recent measurements (lower latency, less smooth).
  final double alpha;

  double? _smoothedX;
  double? _smoothedY;

  ExponentialMovingAverage({this.alpha = 0.7}) {
    assert(alpha > 0.0 && alpha <= 1.0, 'alpha must be in range (0.0, 1.0]');
  }

  /// Whether any values have been smoothed yet.
  bool get hasValues => _smoothedX != null && _smoothedY != null;

  /// Current smoothed x coordinate, or null if no points processed.
  double? get smoothedX => _smoothedX;

  /// Current smoothed y coordinate, or null if no points processed.
  double? get smoothedY => _smoothedY;

  /// Update the smoothed state with new raw coordinates (x, y).
  /// Returns a record of (smoothedX, smoothedY).
  ({double x, double y}) update(double x, double y) {
    if (_smoothedX == null || _smoothedY == null) {
      _smoothedX = x;
      _smoothedY = y;
    } else {
      _smoothedX = alpha * x + (1.0 - alpha) * _smoothedX!;
      _smoothedY = alpha * y + (1.0 - alpha) * _smoothedY!;
    }
    return (x: _smoothedX!, y: _smoothedY!);
  }

  /// Reset the filter state (e.g. when tracking is lost or a new target appears).
  void reset() {
    _smoothedX = null;
    _smoothedY = null;
  }
}

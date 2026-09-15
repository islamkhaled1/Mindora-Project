import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const CircularProgressDemo());
}

class CircularProgressDemo extends StatefulWidget {
  const CircularProgressDemo({super.key});

  @override
  State<CircularProgressDemo> createState() => _CircularProgressDemoState();
}

class _CircularProgressDemoState extends State<CircularProgressDemo> {
  double _percent = 72;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F4FA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // بس تغيّر قيمة _percent وهي هتتحرك وتتلون لوحدها
              AnimatedGradientCircularProgress(
                percent: _percent,
                size: 110,
                strokeWidth: 10,
                labelBuilder: (animatedPercent) => Text(
                  '${animatedPercent.round()}%',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B2E),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Slider(
                value: _percent,
                min: 0,
                max: 100,
                activeColor: const Color(0xFF7C3AC6),
                onChanged: (v) => setState(() => _percent = v),
              ),
              Wrap(
                spacing: 8,
                children: [10, 35, 60, 72, 90, 100].map((v) {
                  return ElevatedButton(
                    onPressed: () => setState(() => _percent = v.toDouble()),
                    child: Text('$v%'),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// درجات الجريدينت زي ما هي في التصميم (Figma stops)
const List<GradientStop> kProgressGradientStops = [
  GradientStop(0.00, Color(0xFF5102B8)),
  GradientStop(0.15, Color(0xFF7C3AC6)),
  GradientStop(0.33, Color(0xFF9A6BEE)),
  GradientStop(0.47, Color(0xFFCFBAF4)),
  GradientStop(1.00, Color(0xFFFFFFFF)),
];

class GradientStop {
  final double stop;
  final Color color;
  const GradientStop(this.stop, this.color);
}

/// ------------------------------------------------------------
/// الـ widget الأساسي: بيرسم القوس والجريدينت لنسبة ثابتة
/// (مفيش أنيميشن هنا؛ الأنيميشن بيحصل في الغلاف اللي تحت)
/// ------------------------------------------------------------
class GradientCircularProgress extends StatelessWidget {
  final double percent; // 0 - 100
  final double size;
  final double strokeWidth;
  final Widget? child;
  final Color trackColor;
  final List<GradientStop> gradientStops;

  const GradientCircularProgress({
    super.key,
    required this.percent,
    this.size = 80,
    this.strokeWidth = 8,
    this.child,
    this.trackColor = const Color(0xFFEDEAF7),
    this.gradientStops = kProgressGradientStops,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GradientArcPainter(
              percent: percent.clamp(0, 100),
              strokeWidth: strokeWidth,
              trackColor: trackColor,
              stops: gradientStops,
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// الغلاف المتحرك: كل ما تغيّر percent، بيعمل tween سلس من
/// القيمة القديمة للجديدة، والجريدينت بيتحدث فريم بفريم
/// تلقائيًا لأن اللون مبني على النسبة الحالية أثناء الحركة
/// ------------------------------------------------------------
class AnimatedGradientCircularProgress extends StatelessWidget {
  final double percent; // 0 - 100 (القيمة المستهدفة)
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final List<GradientStop> gradientStops;
  final Duration duration;
  final Curve curve;

  /// بيرجع الويدجت اللي هيتعرض في نص الدايرة (زي نص "72%")
  /// وبياخد قيمة النسبة الحالية أثناء الحركة عشان لو حبيت
  /// تعرض الرقم وهو بيتغير لحظة بلحظة
  final Widget Function(double animatedPercent)? labelBuilder;

  const AnimatedGradientCircularProgress({
    super.key,
    required this.percent,
    this.size = 80,
    this.strokeWidth = 8,
    this.trackColor = const Color(0xFFEDEAF7),
    this.gradientStops = kProgressGradientStops,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeOutCubic,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: percent.clamp(0, 100)),
      duration: duration,
      curve: curve,
      // من غير key هنا: TweenAnimationBuilder بيلاحظ لوحده كل ما
      // قيمة percent تتغير، وبيكمل الحركة من القيمة الحالية للجديدة
      builder: (context, animatedValue, _) {
        return GradientCircularProgress(
          percent: animatedValue,
          size: size,
          strokeWidth: strokeWidth,
          trackColor: trackColor,
          gradientStops: gradientStops,
          child: labelBuilder != null
              ? Center(child: labelBuilder!(animatedValue))
              : null,
        );
      },
    );
  }
}

class _GradientArcPainter extends CustomPainter {
  final double percent;
  final double strokeWidth;
  final Color trackColor;
  final List<GradientStop> stops;

  _GradientArcPainter({
    required this.percent,
    required this.strokeWidth,
    required this.trackColor,
    required this.stops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // المسار الخلفي (الرمادي الفاتح)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    // زاوية البداية: من أعلى الدائرة (-90 درجة)
    const startAngle = -math.pi / 2;
    final sweepAngle = (percent / 100) * 2 * math.pi;

    // الجريدينت بيتوزع بس على طول القوس الظاهر، فكل ما النسبة
    // تكبر أو تصغر، القوس بيمتد/يقصر واللون بيتحدث معاه تلقائي
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: sweepAngle <= 0 ? 0.0001 : sweepAngle,
      transform: GradientRotation(startAngle),
      colors: stops.map((s) => s.color).toList(),
      stops: stops.map((s) => s.stop).toList(),
      tileMode: TileMode.clamp,
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (sweepAngle > 0) {
      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientArcPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }
}

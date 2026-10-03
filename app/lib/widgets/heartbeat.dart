import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../perf_flags.dart';
import '../theme/app_theme.dart';
import 'throttled.dart';

/// Halo doré qui bat comme un cœur (deux battements rapprochés puis une
/// pause) derrière [child]. Seul le halo s'anime : [child] (souvent du verre
/// liquide, coûteux) n'est ni agrandi ni redessiné à chaque image.
class Heartbeat extends StatefulWidget {
  const Heartbeat({
    super.key,
    required this.child,
    this.radius = 999,
    this.color = Brand.gold,
  });

  final Widget child;
  final double radius;
  final Color color;

  @override
  State<Heartbeat> createState() => _HeartbeatState();
}

class _HeartbeatState extends State<Heartbeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  late final Throttled _slow = Throttled(_beat);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _beat.stop();
    } else if (!_beat.isAnimating && !PerfFlags.off('dock')) {
      _beat.repeat();
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  /// Intensité 0..1 : un pic fort ("lub") puis un pic plus faible ("dub").
  static double pulse(double t) {
    double peak(double at, double width) =>
        math.exp(-math.pow((t - at) / width, 2).toDouble());
    return math.max(peak(0.10, 0.05), 0.65 * peak(0.30, 0.05));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _GlowPainter(_slow, widget.color, widget.radius),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.beat, this.color, this.radius) : super(repaint: beat);

  final Animation<double> beat;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final k = _HeartbeatState.pulse(beat.value);
    final r = math.min(radius, size.height / 2);
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(r),
    );
    canvas.drawRRect(
      rrect.inflate(1 + 3 * k),
      Paint()
        ..color = color.withValues(alpha: 0.18 + 0.42 * k)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 13 * k),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.color != color || old.radius != radius;
}

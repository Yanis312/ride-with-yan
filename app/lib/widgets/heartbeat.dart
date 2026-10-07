import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'decor_clock.dart';

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

class _HeartbeatState extends State<Heartbeat> {
  // Battement calé sur l'horloge décorative commune.
  final Animation<double> _slow = DecorLoop(1.7);

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

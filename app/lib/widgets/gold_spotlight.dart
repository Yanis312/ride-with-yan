import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../perf_flags.dart';
import '../theme/app_theme.dart';
import 'heartbeat.dart';
import 'throttled.dart';

/// Met une carte en vedette : halo doré qui bat comme un cœur et filet de
/// lumière qui tourne sur le bord. Seuls le halo et le filet sont repeints,
/// jamais le contenu de la carte.
class GoldSpotlight extends StatefulWidget {
  const GoldSpotlight({super.key, required this.child, this.radius = 36});

  final Widget child;
  final double radius;

  @override
  State<GoldSpotlight> createState() => _GoldSpotlightState();
}

class _GoldSpotlightState extends State<GoldSpotlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  late final Throttled _slow = Throttled(_spin);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _spin.stop();
    } else if (!_spin.isAnimating && !PerfFlags.off('dock')) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Heartbeat(
      radius: widget.radius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _RingPainter(_slow, widget.radius)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.spin, this.radius) : super(repaint: spin);

  final Animation<double> spin;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)).deflate(1.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..shader = SweepGradient(
          transform: GradientRotation(spin.value * 2 * math.pi),
          colors: [
            Brand.gold.withValues(alpha: 0.25),
            const Color(0xFFFFF4C2),
            Brand.gold,
            Brand.gold.withValues(alpha: 0.25),
            const Color(0xFFFFF4C2),
            Brand.gold.withValues(alpha: 0.25),
          ],
          stops: const [0, 0.08, 0.18, 0.5, 0.58, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.radius != radius;
}

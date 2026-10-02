import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fond noir profond avec deux halos lumineux (or et bleu nuit) qui dérivent
/// très lentement. Immobile si l'utilisateur a réduit les animations.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.ink),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _drift,
            builder: (context, _) =>
                CustomPaint(painter: _OrbsPainter(_drift.value)),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _OrbsPainter extends CustomPainter {
  _OrbsPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final a = t * 2 * math.pi;
    final shortest = size.shortestSide;

    _orb(
      canvas,
      Offset(
        size.width * (0.18 + 0.06 * math.sin(a)),
        size.height * (0.12 + 0.05 * math.cos(a)),
      ),
      shortest * 0.75,
      AppColors.gold.withValues(alpha: 0.13),
    );
    _orb(
      canvas,
      Offset(
        size.width * (0.86 + 0.05 * math.cos(a)),
        size.height * (0.92 + 0.06 * math.sin(a)),
      ),
      shortest * 0.95,
      AppColors.night.withValues(alpha: 0.85),
    );
  }

  void _orb(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_OrbsPainter old) => old.t != t;
}

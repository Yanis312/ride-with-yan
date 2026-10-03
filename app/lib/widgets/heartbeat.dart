import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Halo doré qui bat comme un cœur (deux battements rapprochés puis une
/// pause) et grossit très légèrement [child]. Discret, mais attire l'œil.
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _beat.stop();
    } else if (!_beat.isAnimating) {
      _beat.repeat();
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  /// Intensité 0..1 : un pic fort ("lub") puis un pic plus faible ("dub").
  static double _pulse(double t) {
    double peak(double at, double width) =>
        math.exp(-math.pow((t - at) / width, 2).toDouble());
    return math.max(peak(0.10, 0.05), 0.65 * peak(0.30, 0.05));
  }

  @override
  Widget build(BuildContext context) {
    // Isolé : le battement ne force pas le reste de l'écran à se redessiner.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _beat,
        child: widget.child,
        builder: (context, child) {
          final k = _pulse(_beat.value);
          return Transform.scale(
            scale: 1 + 0.03 * k,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.18 + 0.42 * k),
                    blurRadius: 16 + 26 * k,
                    spreadRadius: 1 + 3 * k,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

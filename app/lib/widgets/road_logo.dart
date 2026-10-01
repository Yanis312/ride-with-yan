import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Logo "Y en forme de route" (branding/icon.svg), dessiné en code pour
/// pouvoir l'animer : [progress] va de 0 (vide) à 1 (logo complet).
class RoadLogo extends StatelessWidget {
  const RoadLogo({super.key, this.size = 160, this.progress = 1, this.glow = 0});

  final double size;
  final double progress;

  /// Intensité du halo ambre autour du Y, de 0 à 1.
  final double glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _RoadLogoPainter(progress, glow)),
    );
  }
}

class _RoadLogoPainter extends CustomPainter {
  _RoadLogoPainter(this.progress, this.glow);

  final double progress;
  final double glow;

  // Coordonnées du SVG d'origine (viewBox 1024 x 1024).
  static const _left = Offset(292, 250);
  static const _right = Offset(732, 250);
  static const _junction = Offset(512, 520);
  static const _bottom = Offset(512, 800);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 1024);

    final background = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 1024, 1024),
      const Radius.circular(224),
    );
    canvas.drawRRect(
      background,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.nightLight, AppColors.nightDark],
        ).createShader(const Rect.fromLTWH(0, 0, 1024, 1024)),
    );

    // Les deux bras se tracent d'abord, puis la tige descend.
    final arms = _interval(progress, 0, 0.55);
    final stem = _interval(progress, 0.45, 0.9);
    final dashes = _interval(progress, 0.85, 1);

    final road = Paint()
      ..color = AppColors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 150
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (glow > 0) {
      final halo = Paint()
        ..color = AppColors.amber.withValues(alpha: 0.35 * glow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 150
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 60 * glow);
      _drawY(canvas, halo, arms, stem);
    }
    _drawY(canvas, road, arms, stem);

    if (dashes > 0) {
      final marking = Paint()
        ..color = AppColors.nightLight.withValues(alpha: dashes)
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round;
      for (var y = 560.0; y < 790; y += 92) {
        canvas.drawLine(Offset(512, y), Offset(512, (y + 48).clamp(0, 790)), marking);
      }
    }
  }

  void _drawY(Canvas canvas, Paint paint, double arms, double stem) {
    if (arms > 0) {
      canvas.drawLine(_left, Offset.lerp(_left, _junction, arms)!, paint);
      canvas.drawLine(_right, Offset.lerp(_right, _junction, arms)!, paint);
    }
    if (stem > 0) {
      canvas.drawLine(_junction, Offset.lerp(_junction, _bottom, stem)!, paint);
    }
  }

  /// Ramène [t] à 0..1 sur l'intervalle [start, end].
  static double _interval(double t, double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0);

  @override
  bool shouldRepaint(_RoadLogoPainter old) =>
      old.progress != progress || old.glow != glow;
}

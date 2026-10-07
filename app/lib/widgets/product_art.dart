import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/store_catalog.dart';

/// Visuel d'un article : sa photo quand elle existe (détourée en .png, ou
/// photo de studio entière en .jpg), sinon une illustration dessinée.
class ProductVisual extends StatelessWidget {
  const ProductVisual({
    super.key,
    required this.product,
    this.photo = 0,
    this.shadow = true,
  });

  final Product product;
  final int photo;

  /// Ombre portée au sol, sous l'article.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final photos = product.photos;
    final Widget visual;
    if (photos.isNotEmpty) {
      visual = product.framed
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                photos[photo % photos.length],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                filterQuality: FilterQuality.medium,
              ),
            )
          : Image.asset(
              photos[photo % photos.length],
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            );
    } else if (product.art case final art?) {
      visual = CustomPaint(
        painter: ProductArtPainter(art, shadow: shadow),
        size: Size.infinite,
      );
    } else {
      visual = LayoutBuilder(
        builder: (context, c) => Center(
          child: Icon(
            product.icon,
            size: c.biggest.shortestSide * 0.42,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      );
    }
    return RepaintBoundary(child: visual);
  }
}

/// Article posé dans sa vitrine : une photo de studio remplit toute la zone ;
/// une illustration ou une photo détourée garde une marge et, pour les
/// chaussures dessinées, une légère inclinaison.
class ProductFigure extends StatelessWidget {
  const ProductFigure({
    super.key,
    required this.product,
    this.padding = EdgeInsets.zero,
    this.photo = 0,
    this.shadow = true,
  });

  final Product product;
  final EdgeInsets padding;
  final int photo;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final photos = product.photos;
    if (product.framed && photos.isNotEmpty) {
      return Image.asset(
        photos[photo % photos.length],
        fit: BoxFit.cover,
        // Cadre un peu vers le haut : les deux chaussures restent visibles.
        alignment: const Alignment(0, -0.3),
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.medium,
      );
    }
    return Padding(
      padding: padding,
      child: Transform.rotate(
        angle: product.art?.kind == ArtKind.sneaker ? productTilt : 0,
        child: ProductVisual(product: product, photo: photo, shadow: shadow),
      ),
    );
  }
}

/// Dessine une basket basse ou un maillot de foot, vus de face ou de profil.
class ProductArtPainter extends CustomPainter {
  const ProductArtPainter(this.art, {this.shadow = true});

  final ProductArt art;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    // L'illustration garde ses proportions et se centre dans la zone.
    final aspect = art.kind == ArtKind.sneaker ? 1.75 : 1.0;
    var w = size.width;
    var h = w / aspect;
    if (h > size.height) {
      h = size.height;
      w = h * aspect;
    }
    canvas.save();
    canvas.translate((size.width - w) / 2, (size.height - h) / 2);
    switch (art.kind) {
      case ArtKind.sneaker:
        _sneaker(canvas, w, h);
      case ArtKind.jersey:
        _jersey(canvas, w, h);
    }
    canvas.restore();
  }

  void _groundShadow(Canvas canvas, Rect oval) {
    if (!shadow) return;
    canvas.drawOval(
      oval,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, oval.height * 0.5),
    );
  }

  void _sneaker(Canvas canvas, double w, double h) {
    Offset u(double x, double y) => Offset(x * w, y * h);
    final upperColor = art.base;
    final line = Color.lerp(upperColor, Colors.black, 0.22)!;

    _groundShadow(
      canvas,
      Rect.fromLTRB(0.06 * w, 0.84 * h, 0.98 * w, 0.95 * h),
    );

    // Tige : talon à gauche, bout arrondi à droite, col échancré.
    final upper = Path()
      ..moveTo(u(0.07, 0.70).dx, u(0.07, 0.70).dy)
      ..cubicTo(0.03 * w, 0.55 * h, 0.05 * w, 0.38 * h, 0.10 * w, 0.30 * h)
      ..lineTo(0.16 * w, 0.27 * h)
      ..cubicTo(0.22 * w, 0.30 * h, 0.27 * w, 0.40 * h, 0.36 * w, 0.40 * h)
      ..cubicTo(0.40 * w, 0.40 * h, 0.41 * w, 0.24 * h, 0.45 * w, 0.19 * h)
      ..lineTo(0.51 * w, 0.20 * h)
      ..cubicTo(0.56 * w, 0.32 * h, 0.66 * w, 0.42 * h, 0.78 * w, 0.47 * h)
      ..cubicTo(0.90 * w, 0.51 * h, 0.97 * w, 0.58 * h, 0.975 * w, 0.68 * h)
      ..lineTo(0.975 * w, 0.71 * h)
      ..close();
    canvas.drawPath(upper, Paint()..color = upperColor);

    canvas.save();
    canvas.clipPath(upper);
    // Volume : reflet en haut, ombre douce en bas.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(
          u(0, 0.2),
          u(0, 0.72),
          [
            Colors.white.withValues(alpha: 0.28),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.22),
          ],
          [0, 0.45, 1],
        ),
    );
    // Garde-boue et contrefort, d'une teinte d'accent.
    final mudguard = Path()
      ..moveTo(0.58 * w, 0.72 * h)
      ..cubicTo(0.62 * w, 0.60 * h, 0.72 * w, 0.56 * h, 0.80 * w, 0.57 * h)
      ..cubicTo(0.90 * w, 0.58 * h, 0.95 * w, 0.62 * h, 0.99 * w, 0.66 * h)
      ..lineTo(0.99 * w, 0.75 * h)
      ..close();
    canvas.drawPath(mudguard, Paint()..color = art.accent);
    final heel = Path()
      ..moveTo(0.0, 0.72 * h)
      ..lineTo(0.0, 0.25 * h)
      ..lineTo(0.17 * w, 0.25 * h)
      ..cubicTo(0.14 * w, 0.40 * h, 0.13 * w, 0.55 * h, 0.17 * w, 0.72 * h)
      ..close();
    canvas.drawPath(heel, Paint()..color = art.accent);
    // Bande d'œillets le long du laçage, d'une teinte d'accent.
    canvas.drawPath(
      Path()
        ..moveTo(0.44 * w, 0.24 * h)
        ..cubicTo(0.54 * w, 0.34 * h, 0.66 * w, 0.45 * h, 0.82 * w, 0.52 * h),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.08
        ..color = Color.lerp(upperColor, art.accent, 0.7)!,
    );
    canvas.restore();

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = line
      ..strokeWidth = h * 0.008;
    canvas.drawPath(upper, stroke);
    canvas.drawPath(mudguard, stroke);
    // Couture du quartier, du col vers la semelle.
    canvas.drawPath(
      Path()
        ..moveTo(0.37 * w, 0.42 * h)
        ..quadraticBezierTo(0.36 * w, 0.56 * h, 0.43 * w, 0.69 * h),
      stroke,
    );

    // Perforations sur le bout.
    final holes = Paint()..color = line.withValues(alpha: 0.7);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 4; col++) {
        canvas.drawCircle(
          u(0.80 + col * 0.035 + row * 0.012, 0.515 + row * 0.03),
          h * 0.0065,
          holes,
        );
      }
    }

    // Œillets et lacets le long du cou-de-pied.
    final laceColor = Color.lerp(upperColor, Colors.white, 0.6)!;
    final lace = Paint()
      ..color = laceColor
      ..strokeWidth = h * 0.02
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final k = i / 5;
      final a = u(0.49 + 0.27 * k, 0.28 + 0.2 * k);
      canvas.drawLine(
        a.translate(-0.028 * w, 0.014 * h),
        a.translate(0.02 * w, -0.028 * h),
        lace,
      );
      canvas.drawCircle(a, h * 0.009, Paint()..color = line);
    }

    // Semelle épaisse, couture au milieu, bande d'usure en dessous.
    final sole = RRect.fromLTRBAndCorners(
      0.035 * w,
      0.68 * h,
      0.99 * w,
      0.86 * h,
      topLeft: Radius.circular(h * 0.04),
      bottomLeft: Radius.circular(h * 0.07),
      topRight: Radius.circular(h * 0.06),
      bottomRight: Radius.circular(h * 0.09),
    );
    canvas.drawRRect(sole, Paint()..color = art.sole);
    canvas.drawRRect(
      sole,
      Paint()
        ..shader = ui.Gradient.linear(u(0, 0.68), u(0, 0.86), [
          Colors.white.withValues(alpha: 0.18),
          Colors.black.withValues(alpha: 0.18),
        ]),
    );
    canvas.drawRect(
      Rect.fromLTRB(0.05 * w, 0.825 * h, 0.975 * w, 0.86 * h),
      Paint()..color = Color.lerp(art.sole, Colors.black, 0.25)!,
    );
    final stitch = Paint()..color = Color.lerp(art.sole, Colors.black, 0.3)!;
    for (var x = 0.07; x < 0.96; x += 0.018) {
      canvas.drawCircle(u(x, 0.745), h * 0.004, stitch);
    }
    canvas.drawRRect(
      sole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.006
        ..color = Color.lerp(art.sole, Colors.black, 0.3)!,
    );
  }

  void _jersey(Canvas canvas, double w, double h) {
    Offset u(double x, double y) => Offset(x * w, y * h);

    _groundShadow(canvas, Rect.fromLTRB(0.2 * w, 0.92 * h, 0.8 * w, 0.99 * h));

    final body = Path()
      ..moveTo(0.37 * w, 0.10 * h)
      ..quadraticBezierTo(0.5 * w, 0.21 * h, 0.63 * w, 0.10 * h)
      ..lineTo(0.80 * w, 0.15 * h)
      ..lineTo(0.97 * w, 0.37 * h)
      ..lineTo(0.85 * w, 0.47 * h)
      ..lineTo(0.76 * w, 0.39 * h)
      ..lineTo(0.765 * w, 0.92 * h)
      ..quadraticBezierTo(0.5 * w, 0.95 * h, 0.235 * w, 0.92 * h)
      ..lineTo(0.24 * w, 0.39 * h)
      ..lineTo(0.15 * w, 0.47 * h)
      ..lineTo(0.03 * w, 0.37 * h)
      ..lineTo(0.20 * w, 0.15 * h)
      ..close();
    canvas.drawPath(body, Paint()..color = art.base);

    canvas.save();
    canvas.clipPath(body);
    if (art.stripes) {
      final band = Paint()..color = art.accent;
      for (var x = 0.0; x < 1; x += 0.16) {
        canvas.drawRect(Rect.fromLTWH(x * w, 0, 0.07 * w, h), band);
      }
    }
    // Manches et col d'une autre couleur.
    final trim = Paint()..color = art.trim;
    canvas.drawPath(
      Path()
        ..moveTo(0.97 * w, 0.37 * h)
        ..lineTo(0.85 * w, 0.47 * h)
        ..lineTo(0.82 * w, 0.44 * h)
        ..lineTo(0.94 * w, 0.34 * h)
        ..close(),
      trim,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0.03 * w, 0.37 * h)
        ..lineTo(0.15 * w, 0.47 * h)
        ..lineTo(0.18 * w, 0.44 * h)
        ..lineTo(0.06 * w, 0.34 * h)
        ..close(),
      trim,
    );
    // Plis du tissu et volume.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.radial(
          u(0.42, 0.3),
          w * 0.7,
          [
            Colors.white.withValues(alpha: 0.22),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.3),
          ],
          [0, 0.5, 1],
        ),
    );
    final fold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.006
      ..color = Colors.black.withValues(alpha: 0.12);
    canvas.drawPath(
      Path()
        ..moveTo(0.3 * w, 0.55 * h)
        ..quadraticBezierTo(0.36 * w, 0.75 * h, 0.33 * w, 0.9 * h),
      fold,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0.69 * w, 0.5 * h)
        ..quadraticBezierTo(0.64 * w, 0.7 * h, 0.68 * w, 0.9 * h),
      fold,
    );
    canvas.restore();

    // Col en V.
    canvas.drawPath(
      Path()
        ..moveTo(0.37 * w, 0.10 * h)
        ..quadraticBezierTo(0.5 * w, 0.21 * h, 0.63 * w, 0.10 * h),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round
        ..color = art.trim,
    );

    // Écusson générique (bouclier) et numéro.
    final crest = Path()
      ..moveTo(0.64 * w, 0.27 * h)
      ..lineTo(0.70 * w, 0.27 * h)
      ..lineTo(0.70 * w, 0.32 * h)
      ..quadraticBezierTo(0.70 * w, 0.355 * h, 0.67 * w, 0.37 * h)
      ..quadraticBezierTo(0.64 * w, 0.355 * h, 0.64 * w, 0.32 * h)
      ..close();
    canvas.drawPath(crest, Paint()..color = art.trim);
    if (art.number case final number?) {
      final tp = TextPainter(
        text: TextSpan(
          text: number,
          style: TextStyle(
            fontSize: h * 0.3,
            fontWeight: FontWeight.w800,
            color: art.trim,
            letterSpacing: -h * 0.01,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, u(0.5, 0.58) - Offset(tp.width / 2, tp.height / 2));
    }

    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.005
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(ProductArtPainter old) =>
      old.art != art || old.shadow != shadow;
}

/// Petite rotation commune aux vitrines (inclinaison façon "produit en vol").
const productTilt = -8 * math.pi / 180;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'liquid_metal_logo.dart';
import 'mesh_background.dart';

/// Illustration animée propre à chaque phase de l'écran de veille.
/// [loop] tourne en boucle de 0 à 1 ; chaque scène en tire son propre mouvement.
class SceneVignette extends StatelessWidget {
  const SceneVignette({
    super.key,
    required this.scene,
    required this.loop,
    required this.size,
  });

  final Scene scene;
  final Animation<double> loop;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: AnimatedBuilder(
        animation: loop,
        builder: (context, _) {
          final t = loop.value;
          return switch (scene) {
            Scene.intro ||
            Scene.lounge ||
            Scene.store ||
            Scene.profile => _Intro(t: t, size: size),
            Scene.cinema => _Cinema(t: t),
            Scene.games => _Games(t: t, size: size),
            Scene.poll => _Poll(t: t, size: size),
            Scene.news => _News(t: t),
            Scene.collab => _Collab(t: t, size: size),
            Scene.finale => _Finale(t: t, size: size),
          };
        },
      ),
    );
  }
}

double _wave(double t, [double phase = 0]) =>
    math.sin((t + phase) * 2 * math.pi);

/// Cercle de verre central commun à plusieurs scènes.
class _GlassDisc extends StatelessWidget {
  const _GlassDisc({required this.icon, required this.diameter, this.color});

  final IconData icon;
  final double diameter;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.glass,
        border: Border.all(color: p.highlight),
        boxShadow: [
          BoxShadow(
            color: (color ?? Brand.gold).withValues(alpha: 0.35),
            blurRadius: 60,
          ),
        ],
      ),
      child: Icon(icon, size: diameter * 0.4, color: color ?? p.text),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.t, required this.size});

  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: Offset(0, _wave(t) * 8),
        child: LiquidMetalLogo(size: size * 0.78),
      ),
    );
  }
}

/// Écran de cinéma : bandes noires qui s'ouvrent, lent zoom, bouton lecture.
class _Cinema extends StatelessWidget {
  const _Cinema({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final bars = 0.12 + 0.05 * _wave(t);
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 11,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: 1.08 + 0.06 * _wave(t, 0.1),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.3, -0.4),
                      radius: 1.2,
                      colors: [
                        Color(0xFFFFB347),
                        Color(0xFFB3122A),
                        Color(0xFF2A0610),
                      ],
                      stops: [0, 0.5, 1],
                    ),
                  ),
                ),
              ),
              // Faisceau du projecteur qui balaie l'écran.
              Transform.rotate(
                angle: -0.5 + 0.25 * _wave(t, 0.3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  heightFactor: bars,
                  widthFactor: 1,
                  child: const ColoredBox(color: Color(0xFF050304)),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: bars,
                  widthFactor: 1,
                  child: const ColoredBox(color: Color(0xFF050304)),
                ),
              ),
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    AppIcons.play,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formes de jeu qui flottent en orbite autour d'une manette.
class _Games extends StatelessWidget {
  const _Games({required this.t, required this.size});

  final double t;
  final double size;

  static const _colors = [
    Color(0xFF8B5CFF),
    Color(0xFF22D3EE),
    Color(0xFFFF4FA3),
    Color(0xFFF5B700),
  ];

  @override
  Widget build(BuildContext context) {
    final r = size * 0.34;
    return Stack(
      alignment: Alignment.center,
      children: [
        for (var i = 0; i < 4; i++)
          Transform.translate(
            offset: Offset(
              math.cos((t + i / 4) * 2 * math.pi) * r,
              math.sin((t + i / 4) * 2 * math.pi) * r * 0.75 +
                  _wave(t * 2, i / 4) * 10,
            ),
            child: Transform.rotate(
              angle: (t * 2 + i) * math.pi,
              child: _Shape(kind: i, color: _colors[i], size: size * 0.16),
            ),
          ),
        _GlassDisc(
          icon: AppIcons.gameController,
          diameter: size * 0.36,
          color: const Color(0xFF22D3EE),
        ),
      ],
    );
  }
}

class _Shape extends StatelessWidget {
  const _Shape({required this.kind, required this.color, required this.size});

  final int kind;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glow = [
      BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 24),
    ];
    return switch (kind) {
      0 => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 5),
          boxShadow: glow,
        ),
      ),
      1 => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.22),
          border: Border.all(color: color, width: 5),
          boxShadow: glow,
        ),
      ),
      2 => CustomPaint(
        size: Size.square(size),
        painter: _TrianglePainter(color),
      ),
      _ => Icon(
        Icons.add_rounded,
        size: size * 1.2,
        color: color,
        shadows: [Shadow(color: color, blurRadius: 20)],
      ),
    };
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height * 0.9)
      ..lineTo(0, size.height * 0.9)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

/// Barres de résultats qui montent et descendent comme un vote en direct.
class _Poll extends StatelessWidget {
  const _Poll({required this.t, required this.size});

  final double t;
  final double size;

  static const _cities = ['Lille', 'Bruxelles', 'Amsterdam', 'Montréal'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Builder(
                      builder: (context) {
                        final h =
                            (0.45 +
                                    0.35 * _wave(t, i * 0.21).abs() +
                                    (i == 0 ? 0.15 : 0))
                                .clamp(0.1, 1.0);
                        return Container(
                          width: double.infinity,
                          height: size * 0.62 * h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: i == 0
                                  ? const [Color(0xFFFFE08A), Brand.gold]
                                  : [
                                      const Color(0xFFFF8A65)
                                          .withValues(alpha: 0.85),
                                      const Color(0xFFE5533D)
                                          .withValues(alpha: 0.55),
                                    ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _cities[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(13, color: p.textMuted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lignes de titres qui défilent comme un bandeau d'actualité.
class _News extends StatelessWidget {
  const _News({required this.t});

  final double t;

  static const _widths = [0.9, 0.62, 0.78, 0.5, 0.7];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.glass,
          border: Border.all(color: p.hairline),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                AppIcons.newspaper,
                size: 40,
                color: Color(0xFF3AA6FF),
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < _widths.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FractionalTranslation(
                    translation: Offset(
                      ((t * (i.isEven ? 1 : -1) + i * 0.17) % 1) * 0.3 - 0.15,
                      0,
                    ),
                    child: FractionallySizedBox(
                      widthFactor: _widths[i],
                      child: Container(
                        height: i == 0 ? 18 : 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: i == 0
                              ? const Color(0xFF3AA6FF)
                              : p.text.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Puces de services en orbite autour du code.
class _Collab extends StatelessWidget {
  const _Collab({required this.t, required this.size});

  final double t;
  final double size;

  static const _labels = ['Sites web', 'Apps mobiles', 'Automatisation', 'IA'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = size * 0.36;
    return Stack(
      alignment: Alignment.center,
      children: [
        _GlassDisc(
          icon: AppIcons.code,
          diameter: size * 0.34,
          color: const Color(0xFF18C2C9),
        ),
        for (var i = 0; i < _labels.length; i++)
          Transform.translate(
            offset: Offset(
              math.cos((t * 0.5 + i / _labels.length) * 2 * math.pi) * r,
              math.sin((t * 0.5 + i / _labels.length) * 2 * math.pi) * r * 0.62,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: p.coreTop,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF18C2C9).withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                _labels[i],
                style: AppText.body(14, weight: FontWeight.w600, color: p.text),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ondes qui partent d'une main : invitation à toucher l'écran.
class _Finale extends StatelessWidget {
  const _Finale({required this.t, required this.size});

  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Builder(
            builder: (context) {
              final k = (t * 1.5 + i / 3) % 1;
              return Container(
                width: size * (0.3 + 0.7 * k),
                height: size * (0.3 + 0.7 * k),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Brand.gold.withValues(alpha: (1 - k) * 0.7),
                    width: 2,
                  ),
                ),
              );
            },
          ),
        _GlassDisc(icon: AppIcons.handTap, diameter: size * 0.32),
      ],
    );
  }
}

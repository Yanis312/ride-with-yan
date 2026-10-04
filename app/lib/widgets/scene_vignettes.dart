import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'liquid_metal_logo.dart';
import 'mesh_background.dart';
import 'store_showcase.dart';

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
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: AnimatedBuilder(
          animation: loop,
          builder: (context, _) {
            final t = loop.value;
            return switch (scene) {
              Scene.intro ||
              Scene.lounge ||
              Scene.profile => _Intro(t: t, size: size),
              Scene.store => StoreShowcase(t: t, size: size),
              Scene.cinema => _Cinema(t: t),
              Scene.games => _Games(t: t, size: size),
              Scene.poll => _Poll(t: t, size: size),
              Scene.news => _News(t: t),
              Scene.collab => _Collab(t: t, size: size),
              Scene.finale => _Finale(t: t, size: size),
              Scene.ads => _Ads(t: t, size: size),
              Scene.music => _Vinyl(t: t, size: size),
            };
          },
        ),
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

/// Aperçu d'une app de streaming : grande affiche "Ce soir au salon",
/// puis une rangée de vignettes qui défile doucement.
class _Cinema extends StatelessWidget {
  const _Cinema({required this.t});

  final double t;

  static const _tiles = [
    ('assets/photos/popcorn.jpg', 'Soirée popcorn'),
    ('assets/photos/vintage-tv.jpg', 'Classiques'),
    ('assets/photos/projector.jpg', 'Cinéma d’auteur'),
    ('assets/photos/cinema-sign.jpg', 'À l’affiche'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: ColoredBox(
        color: const Color(0xFF0B0709),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 62,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform.scale(
                    scale: 1.08 + 0.05 * _wave(t, 0.1),
                    child: Image.asset(
                      'assets/photos/theatre.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xEE0B0709)],
                        stops: [0.35, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CE SOIR AU SALON',
                          style: AppText.eyebrow(const Color(0xFFFFB347)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Grand écran, sièges arrière',
                          style: AppText.display(28, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                AppIcons.play,
                                size: 16,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Regarder',
                                style: AppText.body(
                                  13,
                                  weight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 38,
              child: LayoutBuilder(
                builder: (context, c) {
                  final tileW = c.maxWidth * 0.42;
                  final loopW = (tileW + 10) * _tiles.length;
                  // La rangée glisse en continu, comme le carrousel d'une app de streaming.
                  final shift = (t * loopW) % loopW;
                  return ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      maxWidth: double.infinity,
                      child: Transform.translate(
                        offset: Offset(12 - shift, 0),
                        child: Row(
                          children: [
                            for (final (img, label) in [..._tiles, ..._tiles])
                              Container(
                                width: tileW,
                                margin: const EdgeInsets.only(
                                  right: 10,
                                  top: 12,
                                  bottom: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  image: DecorationImage(
                                    image: AssetImage(img),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  label,
                                  style:
                                      AppText.body(
                                        12,
                                        weight: FontWeight.w700,
                                        color: Colors.white,
                                      ).copyWith(
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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

/// Vote en direct sur des cartes-photos de villes : les pourcentages bougent
/// et la ville en tête porte une couronne.
class _Poll extends StatelessWidget {
  const _Poll({required this.t, required this.size});

  final double t;
  final double size;

  static const _cities = [
    ('assets/photos/city-montreal.jpg', 'Montréal'),
    ('assets/photos/city-paris.jpg', 'Paris'),
    ('assets/photos/city-tokyo.jpg', 'Tokyo'),
    ('assets/photos/city-barcelona.jpg', 'Barcelone'),
  ];

  @override
  Widget build(BuildContext context) {
    final raw = [
      for (var i = 0; i < 4; i++)
        30 + 18 * _wave(t, i * 0.23).abs() + (i == 0 ? 12 : 0),
    ];
    final total = raw.reduce((a, b) => a + b);
    final pct = [for (final v in raw) (v / total * 100).round()];
    final leader = pct.indexOf(pct.reduce(math.max));

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 4; i++)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(_cities[i].$1, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xDD000000)],
                      stops: [0.4, 1],
                    ),
                  ),
                ),
                if (i == leader)
                  const Positioned(
                    right: 10,
                    top: 10,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Brand.gold,
                      child: Icon(AppIcons.crown, size: 18, color: Brand.ink),
                    ),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _cities[i].$2,
                              style: AppText.body(
                                15,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            '${pct[i]} %',
                            style: AppText.body(
                              15,
                              weight: FontWeight.w700,
                              color: i == leader ? Brand.gold : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: pct[i] / 100,
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation(
                            i == leader ? Brand.gold : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Aperçu d'une app d'actualités : une grande nouvelle avec photo et deux
/// brèves, catégories en haut.
class _News extends StatelessWidget {
  const _News({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget line(double w, double alpha) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: w,
      child: Container(
        height: 9,
        decoration: BoxDecoration(
          color: p.text.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
    Widget brief(String img, String cat, double w) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(img, width: 74, height: 56, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat, style: AppText.eyebrow(const Color(0xFF3AA6FF))),
                const SizedBox(height: 6),
                line(w, 0.3),
                const SizedBox(height: 6),
                line(w * 0.7, 0.15),
              ],
            ),
          ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.coreTop,
          border: Border.all(color: p.hairline),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (final (i, c) in const [
                    'Monde',
                    'Sport',
                    'Finance',
                    'Tech',
                  ].indexed)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: i == 0 ? const Color(0xFF3AA6FF) : p.hairline,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        c,
                        style: AppText.body(
                          11,
                          weight: FontWeight.w700,
                          color: i == 0 ? Colors.white : p.text,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Transform.scale(
                        scale: 1.06 + 0.04 * _wave(t),
                        child: Image.asset(
                          'assets/photos/city-montreal.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xDD000000)],
                            stops: [0.35, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF4D4D),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'EN DIRECT',
                                  style: AppText.eyebrow(Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Votre fil d’actualité, en temps réel',
                              style: AppText.display(22, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              brief('assets/photos/city-tokyo.jpg', 'MONDE', 0.9),
              brief('assets/photos/news-business.jpg', 'FINANCE', 0.75),
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

/// Carte de commerce : la photo reste affichée, puis la carte se retourne
/// d'un coup sec pour montrer le plan, l'adresse et l'offre.
class _Ads extends StatelessWidget {
  const _Ads({required this.t, required this.size});

  final double t;
  final double size;

  /// Demi-tours : chaque face reste posée, le retournement est bref.
  static double _turns(double t) {
    double flip(double from) =>
        Curves.easeInOutCubic.transform(((t - from) / 0.12).clamp(0.0, 1.0));
    return flip(0.38) + flip(0.88);
  }

  @override
  Widget build(BuildContext context) {
    final angle = _turns(t) * math.pi;
    final showBack = math.cos(angle) < 0;
    final card = showBack ? _AdBack(size: size) : _AdFront(size: size);

    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(angle + (showBack ? math.pi : 0)),
        child: card,
      ),
    );
  }
}

class _AdFront extends StatelessWidget {
  const _AdFront({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.78,
      height: size * 0.95,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE1306C).withValues(alpha: 0.45),
            blurRadius: 60,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/photos/ad-sushi.jpg', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xE6000000)],
                stops: [0.3, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('EXEMPLE', style: AppText.eyebrow(Colors.white)),
                ),
                const Spacer(),
                Text(
                  'Sushi Kumo',
                  style: AppText.display(34, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Restaurant japonais',
                  style: AppText.body(14, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      AppIcons.mapPin,
                      size: 16,
                      color: Color(0xFFFF8FB1),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '123, rue Exemple, Montréal',
                        style: AppText.body(
                          13,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(AppIcons.instagram, color: Colors.white, size: 22),
                    SizedBox(width: 12),
                    Icon(AppIcons.tiktok, color: Colors.white, size: 22),
                    SizedBox(width: 12),
                    Icon(AppIcons.facebook, color: Colors.white, size: 22),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dos de la carte : plan du quartier, coordonnées, offre et code QR.
class _AdBack extends StatelessWidget {
  const _AdBack({required this.size});

  final double size;

  static const _pink = Color(0xFFFF5C8A);

  @override
  Widget build(BuildContext context) {
    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _pink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                13,
                weight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      width: size * 0.78,
      height: size * 0.95,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1220), Color(0xFF0D0A10)],
        ),
        border: Border.all(color: _pink.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: _pink.withValues(alpha: 0.4), blurRadius: 60),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Plan stylisé du quartier, avec l'épingle du commerce.
          Expanded(
            flex: 40,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _MiniMapPainter()),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _pink,
                      boxShadow: [
                        BoxShadow(
                          color: _pink.withValues(alpha: 0.7),
                          blurRadius: 22,
                        ),
                      ],
                    ),
                    child: const Icon(
                      AppIcons.mapPin,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'À 4 MIN  ·  4 MIN AWAY',
                      style: AppText.eyebrow(Colors.white)
                          .copyWith(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 60,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sushi Kumo',
                        style: AppText.display(26, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      line(AppIcons.mapPin, '123, rue Exemple, Montréal'),
                      line(AppIcons.clock, '11 h – 23 h  ·  11 am – 11 pm'),
                      line(AppIcons.phone, '514 000-0000'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFE08A), Brand.gold],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        AppIcons.gift,
                                        size: 16,
                                        color: Brand.ink,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'OFFRE  ·  OFFER',
                                        style: AppText.eyebrow(Brand.ink)
                                            .copyWith(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '−10 % avec Ride with Yan',
                                    style: AppText.body(
                                      14,
                                      weight: FontWeight.w700,
                                      color: Brand.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(
                              data: 'Sushi Kumo · exemple Ride with Yan',
                              size: 58,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plan de quartier dessiné : îlots, rues, une avenue et l'itinéraire.
class _MiniMapPainter extends CustomPainter {
  const _MiniMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF16222B),
    );

    // Îlots : grille légèrement penchée, comme les rues de Montréal.
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-0.28);
    final block = Paint()..color = const Color(0xFF223440);
    const step = 46.0;
    for (var x = -w; x < w; x += step) {
      for (var y = -h; y < h; y += step * 0.72) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 3, y + 3, step - 6, step * 0.72 - 6),
            const Radius.circular(4),
          ),
          block,
        );
      }
    }
    // Un parc et une grande avenue.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.42, -h * 0.2, step * 2 - 6, step * 1.44 - 6),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF1F4A3A),
    );
    canvas.drawRect(
      Rect.fromLTWH(-w, step * 0.72 - 5, w * 2, 10),
      Paint()..color = const Color(0xFF3A4E5C),
    );
    canvas.restore();

    // Itinéraire du taxi jusqu'au commerce.
    final route = Path()
      ..moveTo(w * 0.06, h * 0.92)
      ..quadraticBezierTo(w * 0.2, h * 0.55, w * 0.38, h * 0.62)
      ..quadraticBezierTo(w * 0.48, h * 0.66, w * 0.5, h * 0.5);
    canvas.drawPath(
      route,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = Brand.gold,
    );
    canvas.drawCircle(
      Offset(w * 0.06, h * 0.92),
      5,
      Paint()..color = Brand.gold,
    );

    // Fondu vers le bas de la carte.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00120C14), Color(0xFF160E18)],
          stops: [0.6, 1],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_MiniMapPainter oldDelegate) => false;
}

/// Vinyle qui tourne : la chanson préférée de Yanis, avec une photo de
/// concert du groupe sur l'étiquette (licence CC BY, créditée dessous).
class _Vinyl extends StatelessWidget {
  const _Vinyl({required this.t, required this.size});

  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final d = size * 0.78;

    final disc = Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            Color(0xFF0B0B0F),
            Color(0xFF2A2D36),
            Color(0xFF0B0B0F),
            Color(0xFF23262E),
            Color(0xFF0B0B0F),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A9BB8).withValues(alpha: 0.35),
            blurRadius: 60,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sillons du disque.
          for (var i = 1; i <= 5; i++)
            Container(
              width: d * (0.56 + i * 0.08),
              height: d * (0.56 + i * 0.08),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
          // Étiquette : photo de concert cerclée d'or.
          Container(
            width: d * 0.54,
            height: d * 0.54,
            padding: EdgeInsets.all(d * 0.012),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Brand.goldSoft, Brand.gold]),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/photos/metallica-live.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            width: d * 0.035,
            height: d * 0.035,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0B0B0F),
              border: Border.all(color: Brand.gold, width: 1.5),
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Un tour par boucle : assez lent pour reconnaître la photo.
            RepaintBoundary(
              child: Transform.rotate(angle: t * 2 * math.pi, child: disc),
            ),
            // Reflet fixe : c'est le disque qui tourne dessous, pas la lumière.
            IgnorePointer(
              child: Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.08),
                    ],
                    stops: const [0, 0.35, 0.7, 1],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: size * 0.035),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Brand.gold.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.music, size: 16, color: Brand.gold),
                const SizedBox(width: 8),
                Text(
                  'Nothing Else Matters  ·  Metallica',
                  style: AppText.body(
                    14,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Photo : Alberto Cabello · CC BY 2.0',
          style: AppText.body(9, color: p.textMuted),
        ),
      ],
    );
  }
}

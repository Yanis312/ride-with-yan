import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/portfolio.dart';
import '../theme/app_theme.dart';

/// Aperçu d'attente de la section Collaborations : une maquette qui se
/// construit toute seule, en boucle, tant qu'aucune démo n'est fournie.
class BlueprintMockup extends StatelessWidget {
  const BlueprintMockup({super.key, required this.frame});

  final ShowcaseFrame frame;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fr = Localizations.localeOf(context).languageCode != 'en';
    final glow = [
      BoxShadow(
        color: Brand.gold.withValues(alpha: 0.3),
        blurRadius: 70,
        offset: const Offset(0, 24),
      ),
    ];

    final Widget framed;
    if (frame == ShowcaseFrame.phone) {
      framed = Center(
        child: AspectRatio(
          aspectRatio: 390 / 844,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0C10),
              borderRadius: BorderRadius.circular(48),
              boxShadow: glow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: const _PhoneSkeleton(),
            ),
          ),
        ),
      );
    } else {
      framed = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: glow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BrowserBar(
                host: fr ? 'votre-entreprise.ca' : 'your-business.com',
              ),
              Expanded(
                child: _WebSkeleton(
                  dashboard: frame == ShowcaseFrame.dashboard,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: framed),
        const SizedBox(height: 18),
        Text(
          fr
              ? 'Votre projet pourrait être ici.'
              : 'Your project could be here.',
          style: AppText.display(32, color: p.text),
        ),
        const SizedBox(height: 4),
        Text(
          fr
              ? 'Dites-moi votre idée, je la construis.'
              : 'Tell me your idea, I will build it.',
          style: AppText.body(14, color: p.textMuted),
        ),
      ],
    );
  }
}

class _BrowserBar extends StatelessWidget {
  const _BrowserBar({required this.host});

  final String host;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: const Color(0xFF1B1D23),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          for (final c in const [
            Color(0xFFFF5F57),
            Color(0xFFFEBC2E),
            Color(0xFF28C840),
          ])
            Container(
              width: 11,
              height: 11,
              margin: const EdgeInsets.only(right: 7),
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                host,
                style: AppText.body(12, color: const Color(0xFFB4B8C2)),
              ),
            ),
          ),
          const SizedBox(width: 60),
        ],
      ),
    );
  }
}

/// Bloc de maquette qui apparaît à son tour, reste affiché puis s'efface,
/// sur un cycle commun de 4,2 s pour que l'ensemble boucle proprement.
Widget _bone(Widget child, int order) {
  final delay = 180 * order;
  return child
      .animate(onPlay: (c) => c.repeat())
      .fadeIn(delay: delay.ms, duration: 450.ms, curve: AppMotion.spring)
      .slideY(
        begin: 0.25,
        delay: delay.ms,
        duration: 450.ms,
        curve: AppMotion.spring,
      )
      .then(delay: (3400 - delay).ms)
      .fadeOut(duration: 350.ms);
}

Widget _bar(double width, double height, Color color, {double radius = 99}) =>
    Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

const _line = Color(0x2EFFFFFF);
const _ink = Color(0xFF0E1015);

class _WebSkeleton extends StatelessWidget {
  const _WebSkeleton({required this.dashboard});

  final bool dashboard;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _ink,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Padding(
            padding: EdgeInsets.all(w * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bone(
                  Row(
                    children: [
                      _bar(w * 0.12, 14, Brand.gold),
                      const Spacer(),
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: _bar(w * 0.07, 10, _line),
                        ),
                    ],
                  ),
                  0,
                ),
                SizedBox(height: w * 0.06),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _bone(
                              _bar(
                                w * 0.42,
                                w * 0.045,
                                Colors.white.withValues(alpha: 0.85),
                              ),
                              1,
                            ),
                            const SizedBox(height: 10),
                            _bone(_bar(w * 0.32, w * 0.045, Brand.gold), 2),
                            const SizedBox(height: 18),
                            for (var i = 0; i < 3; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _bone(
                                  _bar(w * (0.38 - i * 0.06), 9, _line),
                                  3 + i,
                                ),
                              ),
                            const SizedBox(height: 14),
                            _bone(_bar(w * 0.16, 34, Brand.gold), 6),
                          ],
                        ),
                      ),
                      SizedBox(width: w * 0.04),
                      Expanded(
                        child: _bone(
                          dashboard ? const _Chart() : const _Hero(),
                          4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const RadialGradient(
        center: Alignment(-0.3, -0.4),
        colors: [Color(0xFFFFD978), Color(0xFFB98500), Color(0xFF2A1A00)],
      ),
    ),
  );
}

class _Chart extends StatelessWidget {
  const _Chart();

  @override
  Widget build(BuildContext context) {
    const heights = [0.4, 0.6, 0.5, 0.85, 0.7, 0.95, 0.6];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0x14FFFFFF),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final h in heights)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FractionallySizedBox(
                  heightFactor: h,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: h > 0.9 ? Brand.gold : _line,
                      borderRadius: BorderRadius.circular(6),
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

class _PhoneSkeleton extends StatelessWidget {
  const _PhoneSkeleton();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _ink,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              w * 0.07,
              w * 0.16,
              w * 0.07,
              w * 0.07,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bone(_bar(w * 0.4, 10, _line), 0),
                const SizedBox(height: 12),
                _bone(
                  _bar(
                    w * 0.75,
                    w * 0.08,
                    Colors.white.withValues(alpha: 0.85),
                  ),
                  1,
                ),
                const SizedBox(height: 18),
                _bone(
                  Container(
                    height: w * 0.42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD978), Color(0xFFB98500)],
                      ),
                    ),
                  ),
                  2,
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _bone(
                      Row(
                        children: [
                          _bar(w * 0.16, w * 0.16, _line, radius: 12),
                          const SizedBox(width: 10),
                          _bar(w * 0.45, 10, _line),
                        ],
                      ),
                      3 + i,
                    ),
                  ),
                const Spacer(),
                _bone(_bar(w, w * 0.13, Brand.gold), 6),
              ],
            ),
          );
        },
      ),
    );
  }
}

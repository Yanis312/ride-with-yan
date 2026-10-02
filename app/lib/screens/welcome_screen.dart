import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../session/session_controller.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/appearance_controller.dart';
import '../widgets/glass.dart';
import '../widgets/liquid_metal_logo.dart';
import '../widgets/mesh_background.dart';
import '../widgets/quick_dock.dart';
import '../widgets/road_logo.dart';
import '../widgets/scene_vignettes.dart';

/// Une phase de l'écran de veille : une ambiance de couleurs, une
/// illustration animée et plusieurs phrases bilingues possibles.
class _Phase {
  const _Phase(this.scene, this.icon, this.lines);

  final Scene scene;
  final IconData icon;

  /// Variantes (français, anglais) : l'une d'elles est tirée au hasard.
  final List<(String, String)> lines;
}

const _phases = [
  _Phase(Scene.intro, AppIcons.sparkle, [
    ('Bienvenue à bord.', 'Welcome aboard.'),
    ('Ravi de vous accueillir.', 'Glad to have you on board.'),
  ]),
  _Phase(Scene.cinema, AppIcons.filmSlate, [
    ('Regardez un film.', 'Watch a movie.'),
    ('Le cinéma, en route.', 'Cinema on the go.'),
  ]),
  _Phase(Scene.games, AppIcons.gameController, [
    ('Jouez à un jeu.', 'Play a game.'),
    ('Un petit défi ?', 'Up for a challenge?'),
  ]),
  _Phase(Scene.poll, AppIcons.chartBar, [
    ('Donnez votre avis.', 'Have your say.'),
    ('Votre ville préférée ?', "What's your favourite city?"),
  ]),
  _Phase(Scene.news, AppIcons.newspaper, [
    ("Suivez l'actualité.", 'Catch up on the news.'),
    ("Le monde, d'un coup d'œil.", 'The world at a glance.'),
  ]),
  _Phase(Scene.collab, AppIcons.code, [
    ('Découvrez ce que je crée.', 'See what I build.'),
    ('Sites, apps, automatisations.', 'Websites, apps, automation.'),
  ]),
  _Phase(Scene.finale, AppIcons.handTap, [
    ('Feel free to discover!', 'Explorez librement, tout est à vous.'),
    ('Feel free to discover!', "Touchez l'écran, la suite est à vous."),
  ]),
];

/// Ordre d'un cycle : l'accueil d'abord, "Feel free to discover" à la fin,
/// et les autres phases mélangées au hasard (sans répéter la dernière vue).
List<int> _shuffledCycle(math.Random random, {int? avoidFirst}) {
  final middle = [for (var i = 1; i < _phases.length - 1; i++) i];
  do {
    middle.shuffle(random);
  } while (middle.length > 1 && middle.first == avoidFirst);
  return [0, ...middle, _phases.length - 1];
}

/// Écran de veille haut de gamme : les phases défilent toutes seules,
/// chacune avec son fond et son mouvement. Un toucher propose la langue.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  static const phaseDuration = Duration(milliseconds: 5200);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _phaseClock = AnimationController(
    vsync: this,
    duration: WelcomeScreen.phaseDuration,
  )..addStatusListener(_onPhaseEnd);

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  final _random = math.Random();
  late List<int> _order = _shuffledCycle(_random);
  int _step = 0;
  int _cycle = 0;
  int _variant =
      0; // le tout premier écran est toujours la phrase d'accueil classique
  bool _choosingLanguage = false;

  _Phase get _phase => _phases[_order[_step]];

  @override
  void initState() {
    super.initState();
    _phaseClock.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  void _onPhaseEnd(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() {
      _step++;
      if (_step == _order.length) {
        _step = 0;
        _cycle++;
        _order = _shuffledCycle(_random, avoidFirst: _order[_order.length - 2]);
      }
      _variant = _random.nextInt(_phase.lines.length);
    });
    _phaseClock.forward(from: 0);
  }

  @override
  void dispose() {
    _phaseClock.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _openLanguages() => setState(() => _choosingLanguage = true);

  @override
  Widget build(BuildContext context) {
    final phase = _phase;
    final line = phase.lines[_variant];
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 760;

    return Scaffold(
      body: MeshBackground(
        scene: phase.scene,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _choosingLanguage ? null : _openLanguages,
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 20 : 48,
                    20,
                    compact ? 20 : 48,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Header(),
                      Expanded(
                        child: compact
                            ? _CompactStage(
                                phase: phase,
                                line: line,
                                index: _step,
                                textKey: ValueKey('$_cycle-$_step'),
                                loop: _loop,
                              )
                            : _WideStage(
                                phase: phase,
                                line: line,
                                index: _step,
                                textKey: ValueKey('$_cycle-$_step'),
                                loop: _loop,
                              ),
                      ),
                      _Footer(
                        index: _step,
                        clock: _phaseClock,
                        onStart: _openLanguages,
                        compact: compact,
                      ),
                    ],
                  ),
                ),
                if (_choosingLanguage)
                  _LanguageSheet(
                    onSelected: (locale) =>
                        SessionScope.of(context).start(locale),
                    onDismiss: () => setState(() => _choosingLanguage = false),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final appearance = AppearanceScope.of(context);
    return Row(
      children: [
        const RoadLogo(size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Ride with Yan',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.display(26, color: p.text),
          ),
        ),
        QuickDock(compact: MediaQuery.sizeOf(context).width < 760),
        const SizedBox(width: 12),
        LiquidIconButton(
          icon: context.isDark ? AppIcons.sun : AppIcons.moon,
          onTap: appearance.toggle,
        ),
      ],
    );
  }
}

/// Tablette paysage : la phrase à gauche, l'illustration à droite.
class _WideStage extends StatelessWidget {
  const _WideStage({
    required this.phase,
    required this.line,
    required this.index,
    required this.textKey,
    required this.loop,
  });

  final _Phase phase;
  final (String, String) line;
  final int index;
  final Key textKey;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final vignette = (c.maxHeight * 0.86).clamp(200.0, 440.0);
        return Row(
          children: [
            Expanded(
              flex: 11,
              child: _PhaseText(
                key: textKey,
                phase: phase,
                line: line,
                index: index,
                size: c.maxWidth > 1100 ? 96 : 80,
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 9,
              child: Center(
                child: _AnimatedVignette(
                  phase: phase,
                  loop: loop,
                  size: vignette,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Téléphone : illustration au-dessus, phrase en dessous.
class _CompactStage extends StatelessWidget {
  const _CompactStage({
    required this.phase,
    required this.line,
    required this.index,
    required this.textKey,
    required this.loop,
  });

  final _Phase phase;
  final (String, String) line;
  final int index;
  final Key textKey;
  final Animation<double> loop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final vignette = (c.maxWidth * 0.8).clamp(160.0, 320.0);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AnimatedVignette(phase: phase, loop: loop, size: vignette),
            const SizedBox(height: 28),
            _PhaseText(
              key: textKey,
              phase: phase,
              line: line,
              index: index,
              size: 50,
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedVignette extends StatelessWidget {
  const _AnimatedVignette({
    required this.phase,
    required this.loop,
    required this.size,
  });

  final _Phase phase;
  final Animation<double> loop;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 900),
      switchInCurve: AppMotion.spring,
      switchOutCurve: AppMotion.spring,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.86, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: SceneVignette(
        key: ValueKey(phase.scene),
        scene: phase.scene,
        loop: loop,
        size: size,
      ),
    );
  }
}

/// Phrase de la phase : compteur, ligne principale en serif, ligne secondaire
/// en italique. Chaque nouvelle phase rejoue l'entrée (la clé change).
class _PhaseText extends StatelessWidget {
  const _PhaseText({
    super.key,
    required this.phase,
    required this.line,
    required this.index,
    required this.size,
  });

  final _Phase phase;
  final (String, String) line;
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    String two(int n) => n.toString().padLeft(2, '0');
    final counter = '${two(index + 1)} / ${two(_phases.length)}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(phase.icon, size: 22, color: p.accentText),
                const SizedBox(width: 12),
                Text(counter, style: AppText.eyebrow(p.textMuted)),
              ],
            )
            .animate()
            .fadeIn(duration: 500.ms, curve: AppMotion.spring)
            .slideX(begin: -0.2, curve: AppMotion.spring),
        const SizedBox(height: 22),
        Text(line.$1, style: AppText.display(size, color: p.text))
            .animate()
            .fadeIn(delay: 120.ms, duration: 800.ms, curve: AppMotion.spring)
            .slideY(begin: 0.25, delay: 120.ms, curve: AppMotion.spring)
            .blurXY(begin: 10, end: 0, delay: 120.ms, duration: 800.ms),
        const SizedBox(height: 16),
        Text(
              line.$2,
              style: AppText.display(
                size * 0.42,
                style: FontStyle.italic,
                color: p.accentText,
              ),
            )
            .animate()
            .fadeIn(delay: 320.ms, duration: 800.ms, curve: AppMotion.spring)
            .slideY(begin: 0.4, delay: 320.ms, curve: AppMotion.spring),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.index,
    required this.clock,
    required this.onStart,
    required this.compact,
  });

  final int index;
  final Animation<double> clock;
  final VoidCallback onStart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = _Progress(index: index, clock: clock);
    final cta = GlowButton(
      label: 'Touchez pour commencer  ·  Tap to start',
      icon: AppIcons.arrowRight,
      onTap: onStart,
    );

    if (compact) {
      return Column(children: [cta, const SizedBox(height: 20), progress]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: progress),
        const SizedBox(width: 40),
        cta,
      ],
    );
  }
}

/// Barre segmentée façon "stories" : un segment par phase.
class _Progress extends StatelessWidget {
  const _Progress({required this.index, required this.clock});

  final int index;
  final Animation<double> clock;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) => Row(
        children: [
          for (var i = 0; i < _phases.length; i++)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: p.hairline,
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: i < index ? 1 : (i == index ? clock.value : 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: p.accentText,
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

/// Panneau de choix de langue posé sur l'écran de veille assombri.
class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.onSelected, required this.onDismiss});

  final ValueChanged<Locale> onSelected;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Positioned.fill(
      child: _sheet(
        context,
        p,
      ).animate().fadeIn(duration: 350.ms, curve: AppMotion.spring),
    );
  }

  Widget _sheet(BuildContext context, AppPalette p) {
    return GestureDetector(
      onTap: onDismiss,
      child: ColoredBox(
        color: (context.isDark ? Colors.black : Colors.white).withValues(
          alpha: 0.45,
        ),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: LiquidPill(
                  radius: 40,
                  padding: const EdgeInsets.fromLTRB(36, 40, 36, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LiquidMetalLogo(size: 96),
                      const SizedBox(height: 24),
                      Text(
                        'Choisissez votre langue',
                        textAlign: TextAlign.center,
                        style: AppText.display(40, color: p.text),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your language',
                        textAlign: TextAlign.center,
                        style: AppText.display(
                          26,
                          style: FontStyle.italic,
                          color: p.accentText,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 14,
                        children: [
                          PillButton(
                            label: 'Français',
                            large: true,
                            onTap: () => onSelected(const Locale('fr')),
                            trailing: const Text('FR'),
                          ),
                          PillButton(
                            label: 'English',
                            large: true,
                            filled: false,
                            onTap: () => onSelected(const Locale('en')),
                            trailing: const Text('EN'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Ou allez directement à  ·  Or jump straight to',
                        textAlign: TextAlign.center,
                        style: AppText.body(14, color: p.textMuted),
                      ),
                      const SizedBox(height: 12),
                      const QuickDock(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

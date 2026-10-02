import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_icons.dart';

import '../session/session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass.dart';
import '../widgets/road_logo.dart';

/// Premier écran vu par le passager : le Y se trace comme une route,
/// puis un toucher n'importe où propose le choix de langue.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  bool _choosingLanguage = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _draw.value = 1;
      _glow.value = 0.5;
    } else {
      _draw.forward().whenComplete(() {
        if (mounted) _glow.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _start(Locale locale) => SessionScope.of(context).start(locale);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 720;
    final logoSize = (size.shortestSide * 0.2).clamp(96.0, 168.0);
    final titleSize = compact ? 64.0 : 112.0;

    return Scaffold(
      body: AmbientBackground(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _choosingLanguage
              ? null
              : () => setState(() => _choosingLanguage = true),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: Listenable.merge([_draw, _glow]),
                      builder: (context, _) => RoadLogo(
                        size: logoSize,
                        showTile: false,
                        progress: AppMotion.emphasized.transform(_draw.value),
                        glow:
                            0.25 +
                            0.75 * Curves.easeInOutSine.transform(_glow.value),
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Eyebrow('Bienvenue  ·  Welcome')
                        .animate(delay: 900.ms)
                        .fadeIn(duration: 600.ms, curve: AppMotion.spring)
                        .slideY(begin: 0.6, curve: AppMotion.spring),
                    const SizedBox(height: 28),
                    Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Ride with '),
                              TextSpan(
                                text: 'Yan',
                                style: AppText.display(
                                  titleSize,
                                  style: FontStyle.italic,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: AppText.display(titleSize),
                        )
                        .animate(delay: 1050.ms)
                        .fadeIn(duration: 900.ms, curve: AppMotion.spring)
                        .slideY(begin: 0.25, curve: AppMotion.spring)
                        .blurXY(begin: 8, end: 0, duration: 900.ms),
                    const SizedBox(height: 18),
                    Text(
                      'Votre lounge pendant le trajet  ·  Your lounge on the road',
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        compact ? 15 : 18,
                        weight: FontWeight.w300,
                      ),
                    ).animate(delay: 1300.ms).fadeIn(duration: 700.ms),
                    const SizedBox(height: 56),
                    AnimatedSwitcher(
                      duration: AppMotion.medium,
                      switchInCurve: AppMotion.spring,
                      switchOutCurve: AppMotion.spring,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(
                            begin: 0.94,
                            end: 1.0,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _choosingLanguage
                          ? _LanguageChoice(
                              key: const ValueKey('lang'),
                              onSelected: _start,
                            )
                          : _TapToStart(
                              key: const ValueKey('tap'),
                              onTap: () =>
                                  setState(() => _choosingLanguage = true),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TapToStart extends StatelessWidget {
  const _TapToStart({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PillButton(
          label: 'Touchez pour commencer  ·  Tap to start',
          filled: false,
          large: true,
          onTap: onTap,
          trailing: const Icon(AppIcons.arrowRight),
        )
        .animate(delay: 1600.ms)
        .fadeIn(duration: 700.ms)
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(end: 1.03, duration: 1800.ms, curve: Curves.easeInOutSine);
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({super.key, required this.onSelected});

  final ValueChanged<Locale> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 16,
      children:
          [
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
              ]
              .animate(interval: 90.ms)
              .fadeIn(duration: 450.ms, curve: AppMotion.spring)
              .slideY(begin: 0.4, curve: AppMotion.spring),
    );
  }
}

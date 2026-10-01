import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../session/session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/road_logo.dart';

/// Premier écran vu par le passager : le logo se dessine, puis un toucher
/// n'importe où affiche le choix de langue.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  bool _choosingLanguage = false;

  @override
  void initState() {
    super.initState();
    _draw.addStatusListener((status) {
      if (status == AnimationStatus.completed) _glow.repeat(reverse: true);
    });
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
    final logoSize = (MediaQuery.sizeOf(context).shortestSide * 0.32).clamp(140.0, 280.0);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _choosingLanguage ? null : () => setState(() => _choosingLanguage = true),
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.2,
              colors: [AppColors.night, AppColors.nightDark],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: Listenable.merge([_draw, _glow]),
                      builder: (context, _) => RoadLogo(
                        size: logoSize,
                        progress: Curves.easeInOutCubic.transform(_draw.value),
                        glow: 0.3 + 0.7 * Curves.easeInOut.transform(_glow.value),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Ride with Yan',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                          ),
                    ).animate(delay: 1400.ms).fadeIn(duration: 700.ms).slideY(begin: 0.3),
                    const SizedBox(height: 12),
                    Text(
                      'Bienvenue  ·  Welcome',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.amber,
                            letterSpacing: 2,
                          ),
                    ).animate(delay: 1700.ms).fadeIn(duration: 700.ms),
                    const SizedBox(height: 56),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 96),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _choosingLanguage
                            ? _LanguageButtons(onSelected: _start)
                            : const _TapHint(),
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

class _TapHint extends StatelessWidget {
  const _TapHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Touchez l\'écran pour commencer  ·  Tap to start',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textMuted),
      )
          .animate(delay: 2200.ms, onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 900.ms)
          .then()
          .fade(begin: 1, end: 0.35, duration: 1200.ms),
    );
  }
}

class _LanguageButtons extends StatelessWidget {
  const _LanguageButtons({required this.onSelected});

  final ValueChanged<Locale> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 16,
      children: [
        _LanguageButton(
          label: 'Français',
          onPressed: () => onSelected(const Locale('fr')),
        ),
        _LanguageButton(
          label: 'English',
          onPressed: () => onSelected(const Locale('en')),
        ),
      ]
          .animate(interval: 120.ms)
          .fadeIn(duration: 350.ms)
          .scaleXY(begin: 0.85, curve: Curves.easeOutBack),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(220, 72),
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label),
    );
  }
}

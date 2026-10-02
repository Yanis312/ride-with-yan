import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../theme/app_icons.dart';

import '../l10n/app_localizations.dart';
import '../session/session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass.dart';
import '../widgets/road_logo.dart';

/// Lounge principal : grille "bento" asymétrique, la section la plus
/// utilisée (divertissement) occupe la plus grande place.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 40,
              20,
              compact ? 16 : 40,
              compact ? 16 : 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _TopBar(),
                SizedBox(height: compact ? 24 : 36),
                Expanded(
                  child: compact
                      ? const _CompactLayout()
                      : const _BentoLayout(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _comingSoon(BuildContext context, String title) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$title  ·  ${l10n.comingSoon}')));
}

// ---------------------------------------------------------------------------
// Barre supérieure : îlot flottant (logo, horloge, langue).

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.of(context);
    final compact = MediaQuery.sizeOf(context).width < 720;

    return Row(
      children: [
        // Appui long sur le logo : geste discret du conducteur pour revenir
        // à l'accueil entre deux courses.
        Tooltip(
          message: l10n.backToWelcome,
          child: Pressable(
            onTap: null,
            onLongPress: session.reset,
            child: const RoadLogo(size: 44),
          ),
        ),
        const SizedBox(width: 14),
        // Zone élastique : le titre et l'étiquette cèdent la place en premier.
        Expanded(
          child: compact
              ? const SizedBox.shrink()
              : Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Ride with Yan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(26),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(child: Eyebrow(l10n.loungeEyebrow)),
                  ],
                ),
        ),
        if (!compact) ...[const _Clock(), const SizedBox(width: 12)],
        PillButton(
          label: l10n.switchLanguage,
          filled: false,
          onTap: session.switchLanguage,
          trailing: const Icon(AppIcons.translate),
        ),
      ],
    ).animate().fadeIn(duration: AppMotion.medium, curve: AppMotion.spring);
  }
}

class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: DateFormat.Hm(locale).format(_now),
              style: AppText.body(
                16,
                weight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            TextSpan(text: '   ${DateFormat.MMMMEEEEd(locale).format(_now)}'),
          ],
        ),
        style: AppText.body(15),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mise en page tablette : bento 12 colonnes x 2 rangées.

class _BentoLayout extends StatelessWidget {
  const _BentoLayout();

  @override
  Widget build(BuildContext context) {
    const gap = 18.0;
    final tiles = _Tiles.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Greeting(),
        const SizedBox(height: 28),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:
                [
                      Expanded(flex: 5, child: tiles.entertainment),
                      const SizedBox(width: gap),
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 4, child: tiles.poll),
                                  const SizedBox(width: gap),
                                  Expanded(flex: 3, child: tiles.weather),
                                ],
                              ),
                            ),
                            const SizedBox(height: gap),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 2, child: tiles.news),
                                  const SizedBox(width: gap),
                                  Expanded(flex: 2, child: tiles.store),
                                  const SizedBox(width: gap),
                                  Expanded(flex: 3, child: tiles.about),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                    .animate(interval: 80.ms)
                    .fadeIn(duration: AppMotion.slow, curve: AppMotion.spring)
                    .slideY(begin: 0.08, curve: AppMotion.spring),
          ),
        ),
      ],
    );
  }
}

/// Mise en page téléphone : une seule colonne qui défile.
class _CompactLayout extends StatelessWidget {
  const _CompactLayout();

  @override
  Widget build(BuildContext context) {
    final tiles = _Tiles.of(context);
    final items = [
      (360.0, tiles.entertainment),
      (220.0, tiles.poll),
      (220.0, tiles.about),
      (180.0, tiles.weather),
      (180.0, tiles.news),
      (180.0, tiles.store),
    ];

    return ListView(
      children: [
        const _Greeting(),
        const SizedBox(height: 24),
        for (final (height, tile) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SizedBox(height: height, child: tile),
          ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context).width < 720 ? 44.0 : 64.0;

    return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${l10n.greetingLead} '),
              TextSpan(
                text: l10n.greetingTail,
                style: AppText.display(
                  size,
                  style: FontStyle.italic,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          style: AppText.display(size),
        )
        .animate()
        .fadeIn(duration: AppMotion.slow, curve: AppMotion.spring)
        .slideX(begin: -0.03);
  }
}

// ---------------------------------------------------------------------------
// Tuiles.

class _Tiles {
  _Tiles._(
    this.entertainment,
    this.poll,
    this.weather,
    this.news,
    this.store,
    this.about,
  );

  factory _Tiles.of(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Tiles._(
      const _EntertainmentTile(),
      const _PollTile(),
      _SmallTile(
        icon: AppIcons.cloudSun,
        title: l10n.sectionWeather,
        hint: l10n.sectionWeatherHint,
      ),
      _SmallTile(
        icon: AppIcons.newspaper,
        title: l10n.sectionNews,
        hint: l10n.sectionNewsHint,
      ),
      _SmallTile(
        icon: AppIcons.handbag,
        title: l10n.sectionStore,
        hint: l10n.sectionStoreHint,
      ),
      const _AboutTile(),
    );
  }

  final Widget entertainment;
  final Widget poll;
  final Widget weather;
  final Widget news;
  final Widget store;
  final Widget about;
}

class _EntertainmentTile extends StatelessWidget {
  const _EntertainmentTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Pressable(
      onTap: () => _comingSoon(context, l10n.sectionEntertainment),
      child: BezelCard(
        radius: 36,
        padding: const EdgeInsets.all(32),
        coreGradient: const RadialGradient(
          center: Alignment(0.7, -0.6),
          radius: 1.3,
          colors: [Color(0xFF3A2A06), Color(0xFF121216), Color(0xFF0B0C10)],
          stops: [0, 0.55, 1],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Eyebrow(l10n.featuredEyebrow),
                const Spacer(),
                const _PlayOrb(),
              ],
            ),
            const Spacer(),
            Text(l10n.sectionEntertainment, style: AppText.display(56)),
            const SizedBox(height: 10),
            Text(
              l10n.sectionEntertainmentHint,
              style: AppText.body(17, weight: FontWeight.w300),
            ),
            const SizedBox(height: 28),
            PillButton(
              label: l10n.entertainmentCta,
              onTap: () => _comingSoon(context, l10n.sectionEntertainment),
              trailing: const Icon(AppIcons.play),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cercle doré qui "respire" lentement autour de l'icône lecture.
class _PlayOrb extends StatelessWidget {
  const _PlayOrb();

  @override
  Widget build(BuildContext context) {
    final orb = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        gradient: RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.28),
            AppColors.gold.withValues(alpha: 0),
          ],
        ),
      ),
      child: const Icon(AppIcons.play, color: AppColors.gold, size: 28),
    );

    if (MediaQuery.disableAnimationsOf(context)) return orb;
    return orb
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(end: 1.08, duration: 2400.ms, curve: Curves.easeInOutSine);
  }
}

class _PollTile extends StatelessWidget {
  const _PollTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Pressable(
      onTap: () => _comingSoon(context, l10n.sectionPoll),
      child: BezelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Eyebrow(l10n.sectionPoll),
                const Spacer(),
                const Icon(
                  AppIcons.chartBar,
                  color: AppColors.goldSoft,
                  size: 26,
                ),
              ],
            ),
            const Spacer(),
            Text(
              l10n.pollQuestion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.display(34, style: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            const _MiniBars(),
          ],
        ),
      ),
    );
  }
}

/// Aperçu décoratif des résultats du sondage.
class _MiniBars extends StatelessWidget {
  const _MiniBars();

  @override
  Widget build(BuildContext context) {
    const values = [0.82, 0.56, 0.38, 0.24];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < values.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: values[i],
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: i == 0 ? AppColors.gold : AppColors.hairline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Pressable(
      onTap: () => _comingSoon(context, l10n.sectionAbout),
      child: BezelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                  ),
                  child: Text(
                    'Y',
                    style: AppText.display(30, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.driverEyebrow.toUpperCase(),
                        style: AppText.eyebrow,
                      ),
                      const SizedBox(height: 4),
                      Text('Yanis Garoui', style: AppText.display(28)),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.aboutCta,
                    style: AppText.body(
                      16,
                      weight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const Icon(
                  AppIcons.arrowUpRight,
                  color: AppColors.gold,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallTile extends StatelessWidget {
  const _SmallTile({
    required this.icon,
    required this.title,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => _comingSoon(context, title),
      child: BezelCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.goldSoft, size: 30),
            const Spacer(),
            Text(title, style: AppText.display(30)),
            const SizedBox(height: 6),
            Text(
              hint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(14, weight: FontWeight.w300),
            ),
          ],
        ),
      ),
    );
  }
}

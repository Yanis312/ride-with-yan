import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../data/bilingual.dart';
import '../data/poll.dart';
import '../data/store_catalog.dart';
import '../data/weather.dart';
import '../l10n/app_localizations.dart';
import '../navigation/sections.dart';
import '../session/session_controller.dart';
import 'entertainment_screen.dart';
import 'news_screen.dart';
import 'poll_screen.dart';
import 'weather_screen.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/appearance_controller.dart';
import '../widgets/glass.dart';
import '../widgets/gold_spotlight.dart';
import '../widgets/mesh_background.dart';
import '../widgets/product_art.dart';
import '../widgets/quick_dock.dart';
import '../widgets/road_logo.dart';

/// Lounge principal : grille "bento" asymétrique. Les deux cartes qui
/// rapportent (ma boutique, services et collaborations) sont les plus
/// grandes et les seules à briller.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Scaffold(
      body: MeshBackground(
        scene: Scene.lounge,
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
                SizedBox(height: compact ? 24 : 32),
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

// ---------------------------------------------------------------------------
// Barre supérieure : logo, horloge, mode clair/sombre, langue.

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.of(context);
    final appearance = AppearanceScope.of(context);
    final p = context.palette;
    final compact = MediaQuery.sizeOf(context).width < 760;

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
        // Zone élastique : le titre cède la place en premier.
        Expanded(
          child: compact
              ? const SizedBox.shrink()
              : Text(
                  'Ride with Yan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display(26, color: p.text),
                ),
        ),
        QuickDock(compact: compact),
        const SizedBox(width: 12),
        LiquidIconButton(
          icon: context.isDark ? AppIcons.sun : AppIcons.moon,
          onTap: appearance.toggle,
          size: 48,
        ),
        const SizedBox(width: 12),
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
    final p = context.palette;
    final locale = Localizations.localeOf(context).languageCode;
    return LiquidPill(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: DateFormat.Hm(locale).format(_now),
              style: AppText.body(16, weight: FontWeight.w600, color: p.text),
            ),
            TextSpan(text: '   ${DateFormat.MMMMEEEEd(locale).format(_now)}'),
          ],
        ),
        style: AppText.body(15, color: p.textMuted),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mise en page tablette : la boutique en grand à gauche, le chauffeur en
// vedette en haut à droite, le reste en cartes-photos.

class _BentoLayout extends StatelessWidget {
  const _BentoLayout();

  @override
  Widget build(BuildContext context) {
    const gap = 18.0;
    final tiles = _Tiles.of(context);

    Widget enter(Widget child, int order) => child
        .animate()
        .fadeIn(
          delay: (80 * order).ms,
          duration: AppMotion.slow,
          curve: AppMotion.spring,
        )
        .slideY(begin: 0.08, delay: (80 * order).ms, curve: AppMotion.spring);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _Greeting()),
            SizedBox(width: 16),
            _Clock(),
          ],
        ),
        const SizedBox(height: 28),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: enter(tiles.store, 0)),
              const SizedBox(width: gap),
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 5, child: enter(tiles.about, 1)),
                          const SizedBox(width: gap),
                          Expanded(
                            flex: 3,
                            child: enter(tiles.entertainment, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: gap),
                    Expanded(
                      flex: 5,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: enter(tiles.poll, 3)),
                          const SizedBox(width: gap),
                          Expanded(flex: 2, child: enter(tiles.news, 4)),
                          const SizedBox(width: gap),
                          Expanded(flex: 2, child: enter(tiles.weather, 5)),
                        ],
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

/// Mise en page téléphone : une seule colonne qui défile.
class _CompactLayout extends StatelessWidget {
  const _CompactLayout();

  @override
  Widget build(BuildContext context) {
    final tiles = _Tiles.of(context);
    final items = [
      (460.0, tiles.store),
      (270.0, tiles.about),
      (220.0, tiles.entertainment),
      (200.0, tiles.poll),
      (170.0, tiles.news),
      (170.0, tiles.weather),
    ];

    return ListView(
      // Laisse la place au halo des cartes vedettes.
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        const _Greeting(),
        const SizedBox(height: 24),
        for (final (height, tile) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
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
    final p = context.palette;
    final size = MediaQuery.sizeOf(context).width < 760 ? 44.0 : 64.0;
    final (lead, tail) = switch (SessionScope.of(context).greeting) {
      1 => (l10n.greetingLead1, l10n.greetingTail1),
      2 => (l10n.greetingLead2, l10n.greetingTail2),
      3 => (l10n.greetingLead3, l10n.greetingTail3),
      _ => (l10n.greetingLead, l10n.greetingTail),
    };

    return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$lead '),
              TextSpan(
                text: tail,
                style: AppText.display(
                  size,
                  style: FontStyle.italic,
                  color: p.accentText,
                ),
              ),
            ],
          ),
          style: AppText.display(size, color: p.text),
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
      const _WeatherTile(),
      _PhotoTile(
        photo: 'assets/photos/news-paper.jpg',
        icon: AppIcons.newspaper,
        title: l10n.sectionNews,
        hint: l10n.sectionNewsHint,
        onTap: () => openPage(context, const NewsScreen(), name: 'news'),
      ),
      const _StoreTile(),
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

const _ink = Color(0xFFFFF6EC);

/// Photo plein cadre assombrie vers le bas, pour que le texte reste lisible.
class _PhotoBackdrop extends StatelessWidget {
  const _PhotoBackdrop({required this.photo, this.tint = Colors.black});

  final String photo;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(photo, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tint.withValues(alpha: 0.35),
                Color.lerp(tint, Colors.black, 0.6)!.withValues(alpha: 0.9),
              ],
              stops: const [0.15, 1],
            ),
          ),
        ),
      ],
    );
  }
}

/// La plus grande carte : "Ma boutique", avec les articles qui défilent.
class _StoreTile extends StatefulWidget {
  const _StoreTile();

  @override
  State<_StoreTile> createState() => _StoreTileState();
}

class _StoreTileState extends State<_StoreTile> {
  final _products = featuredProducts;
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_products.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 3400), (_) {
        if (mounted) setState(() => _index = (_index + 1) % _products.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _open() => openSection(context, Section.store);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final product = _products.isEmpty ? null : _products[_index];

    return GoldSpotlight(
      child: Pressable(
        onTap: _open,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF23201A), Color(0xFF0A0A0C)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (product != null)
                    Expanded(child: _StoreStage(product: product)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.sectionStore,
                            style: AppText.display(48, color: _ink),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.sectionStoreHint,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            15,
                            weight: FontWeight.w300,
                            color: _ink.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            // Les miniatures rétrécissent si la carte est étroite.
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    for (final (i, p) in productWindow(
                                      _products,
                                      _index,
                                      4,
                                    ))
                                      AnimatedContainer(
                                        duration: AppMotion.medium,
                                        curve: AppMotion.spring,
                                        width: 50,
                                        height: 50,
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          gradient: LinearGradient(
                                            colors: p.colors,
                                          ),
                                          border: Border.all(
                                            color: i == _index
                                                ? Brand.gold
                                                : Colors.white24,
                                            width: i == _index ? 2 : 1,
                                          ),
                                        ),
                                        child: ProductVisual(
                                          product: p,
                                          shadow: false,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PillButton(
                              label: const Bi('Voir', 'Shop').of(context),
                              onTap: _open,
                              trailing: const Icon(AppIcons.arrowRight),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scène de la carte boutique : l'article du moment, son nom et son prix.
class _StoreStage extends StatelessWidget {
  const _StoreStage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    final price = NumberFormat.currency(
      locale: en ? 'en_CA' : 'fr_CA',
      symbol: r'$',
      decimalDigits: 0,
    ).format(product.price);
    final light = product.colors.first.computeLuminance() > 0.45;
    final onStage = light ? Brand.ink : Colors.white;

    Widget swap(Widget child, {bool slide = false}) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 750),
      reverseDuration: const Duration(milliseconds: 300),
      switchInCurve: AppMotion.emphasized,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: slide
            ? SlideTransition(
                position: Tween(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              )
            : child,
      ),
      child: KeyedSubtree(key: ValueKey(product.id), child: child),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: AppMotion.spring,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.4),
          radius: 1.2,
          colors: product.colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: swap(
              ProductFigure(
                product: product,
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 62),
              ),
              slide: !product.framed,
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.sealCheck, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    const Bi('Neuf', 'New').of(context),
                    style: AppText.eyebrow(Colors.white).copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 12,
            bottom: 12,
            child: swap(
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (product.brand ?? product.category.label.of(context))
                              .toUpperCase(),
                          style: AppText.eyebrow(
                            light ? Brand.goldDeep : Brand.goldSoft,
                          ),
                        ),
                        Text(
                          product.name.of(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.display(24, color: onStage),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE08A), Brand.gold],
                      ),
                    ),
                    child: Text(
                      price,
                      style: AppText.body(
                        17,
                        weight: FontWeight.w800,
                        color: Brand.ink,
                      ),
                    ),
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

/// Carte vedette du chauffeur : elle brille, et mène aux collaborations.
class _AboutTile extends StatelessWidget {
  const _AboutTile();

  static const _previews = [
    'assets/showcase/noir-tailor.jpg',
    'assets/showcase/mokka.jpg',
    'assets/showcase/vlt-active.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void open() => openSection(context, Section.collaboration);

    return GoldSpotlight(
      child: Pressable(
        onTap: open,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.9, -1),
                    radius: 1.6,
                    colors: [
                      Color(0xFF6B4A00),
                      Color(0xFF2A1D03),
                      Color(0xFF0B0904),
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
              // Aperçu de ses réalisations, en éventail sur la droite.
              Positioned(
                right: -44,
                top: 0,
                bottom: 0,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = (c.maxHeight * 0.62).clamp(110.0, 200.0);
                    return SizedBox(
                      width: w * 1.25,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          for (final (i, shot) in _previews.indexed)
                            Transform.translate(
                              offset: Offset(
                                (i - 1) * w * 0.12,
                                (i - 1) * c.maxHeight * 0.24,
                              ),
                              child: Transform.rotate(
                                angle: -0.14 + i * 0.06,
                                child: Container(
                                  width: w,
                                  height: w * 0.62,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 18,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    shot,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Voile sombre à gauche : le texte passe devant les aperçus.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xF20E0B04), Color(0x000E0B04)],
                    stops: [0.5, 0.92],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // L'en-tête s'arrête avant l'éventail d'aperçus.
                    FractionallySizedBox(
                      widthFactor: 0.68,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFFE08A), Brand.gold],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Brand.gold.withValues(alpha: 0.6),
                                  blurRadius: 22,
                                ),
                              ],
                            ),
                            child: Text(
                              'Y',
                              style: AppText.display(32, color: Brand.ink),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.driverEyebrow.toUpperCase(),
                                  style: AppText.eyebrow(Brand.goldSoft),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Yanis Garoui',
                                    style: AppText.display(34, color: _ink),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Une seule ligne, qui rétrécit plutôt que d'être coupée.
                    FractionallySizedBox(
                      widthFactor: 0.64,
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          const Bi(
                            'Sites web · Applications · Automatisation',
                            'Websites · Apps · Automation',
                          ).of(context),
                          maxLines: 1,
                          style: AppText.body(
                            15,
                            weight: FontWeight.w400,
                            color: _ink.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: GlowButton(
                        label: l10n.aboutCta,
                        icon: AppIcons.arrowUpRight,
                        onTap: open,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntertainmentTile extends StatelessWidget {
  const _EntertainmentTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Pressable(
      onTap: () =>
          openPage(context, const EntertainmentScreen(), name: 'entertainment'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _PhotoBackdrop(
              photo: 'assets/photos/theatre.jpg',
              tint: Color(0xFF5A0A16),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Eyebrow(
                            l10n.featuredEyebrow,
                            color: Brand.goldSoft,
                          ),
                        ),
                      ),
                      const _PlayOrb(),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.sectionEntertainment,
                      style: AppText.display(34, color: _ink),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.sectionEntertainmentHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      14,
                      weight: FontWeight.w300,
                      color: _ink.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cercle qui "respire" lentement autour de l'icône lecture.
class _PlayOrb extends StatelessWidget {
  const _PlayOrb();

  @override
  Widget build(BuildContext context) {
    final orb = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        color: Colors.white.withValues(alpha: 0.16),
      ),
      child: const Icon(AppIcons.play, color: Colors.white, size: 22),
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
      onTap: () => openPage(context, const PollScreen(), name: 'poll'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _PhotoBackdrop(
              photo: 'assets/photos/city-paris.jpg',
              tint: Color(0xFF2A1D03),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Eyebrow(
                            l10n.sectionPoll,
                            color: Brand.goldSoft,
                          ),
                        ),
                      ),
                      const Icon(
                        AppIcons.chartBar,
                        color: Brand.goldSoft,
                        size: 24,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    questionOfTheDay().question.of(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(
                      28,
                      style: FontStyle.italic,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _MiniBars(),
                ],
              ),
            ),
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
    const values = [0.82, 0.56, 0.38];
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
                  color: i == 0 ? Brand.gold : Colors.white30,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Carte météo : la température de Montréal en direct, dès qu'elle arrive.
class _WeatherTile extends StatefulWidget {
  const _WeatherTile();

  @override
  State<_WeatherTile> createState() => _WeatherTileState();
}

class _WeatherTileState extends State<_WeatherTile> {
  Weather? _weather = WeatherService.cached(places.first);

  @override
  void initState() {
    super.initState();
    if (_weather == null) {
      WeatherService.fetch(places.first).then(
        (w) {
          if (mounted) setState(() => _weather = w);
        },
        // Sans réseau, la carte reste simplement sans température.
        onError: (_) {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weather = _weather;
    return _PhotoTile(
      photo: 'assets/photos/city-london.jpg',
      icon: weather == null
          ? AppIcons.cloudSun
          : describeWeather(weather.code, isDay: weather.isDay).$2,
      title: l10n.sectionWeather,
      hint: weather == null
          ? l10n.sectionWeatherHint
          : '${places.first.name.of(context)} · '
                '${describeWeather(weather.code, isDay: weather.isDay).$1.of(context)}',
      badge: weather == null ? null : '${weather.temperature.round()}°',
      tint: const Color(0xFF0B2A5B),
      onTap: () => openPage(context, const WeatherScreen(), name: 'weather'),
    );
  }
}

/// Petite carte-photo : icône en haut, titre et sous-titre en bas.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    this.tint = Colors.black,
    this.badge,
  });

  final String photo;
  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;
  final Color tint;

  /// Information en direct affichée en haut à droite (ex. la température).
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _PhotoBackdrop(photo: photo, tint: tint),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.35),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  if (badge != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        badge!,
                        style: AppText.display(
                          44,
                          color: _ink,
                        ).copyWith(height: 1),
                      ),
                    ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(title, style: AppText.display(28, color: _ink)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      13,
                      weight: FontWeight.w300,
                      color: _ink.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

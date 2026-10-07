import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';

import '../config.dart';
import '../data/portfolio.dart';
import '../l10n/app_localizations.dart';
import '../navigation/sections.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/blueprint_mockup.dart';
import '../widgets/decor_clock.dart';
import '../widgets/glass.dart';
import '../widgets/heartbeat.dart';
import '../widgets/mesh_background.dart';
import '../widgets/qr_card.dart';
import '../widgets/section_scaffold.dart';
import '../widgets/touch_tilt.dart';

/// Section Collaborations : un onglet par service, une vitrine animée de
/// démos (photos et vidéos) et un appel à l'action vers Yanis.
class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({super.key});

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 900;
    final tab = serviceTabs[_tab];

    final body = AnimatedSwitcher(
      duration: AppMotion.slow,
      switchInCurve: AppMotion.spring,
      switchOutCurve: AppMotion.spring,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: compact
          ? ListView(
              key: ValueKey(_tab),
              children: [
                SizedBox(height: 420, child: _Showroom(tab: tab)),
                const SizedBox(height: 24),
                _Pitch(tab: tab),
              ],
            )
          : Row(
              key: ValueKey(_tab),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: _Showroom(tab: tab)),
                const SizedBox(width: 36),
                Expanded(flex: 5, child: _Pitch(tab: tab)),
              ],
            ),
    );

    return SectionScaffold(
      scene: Scene.collab,
      section: Section.collaboration,
      title: l10n.collabTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Tabs(selected: _tab, onSelected: (i) => setState(() => _tab = i)),
          const SizedBox(height: 22),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Onglets en verre liquide avec pastille dorée sur l'onglet actif.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: LiquidPill(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < serviceTabs.length; i++)
              Pressable(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.spring,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: i == selected
                        ? const LinearGradient(
                            colors: [Brand.goldSoft, Brand.gold],
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        serviceTabs[i].icon,
                        size: 22,
                        color: i == selected ? Brand.ink : p.text,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        serviceTabs[i].label.of(context),
                        style: AppText.body(
                          17,
                          weight: FontWeight.w600,
                          color: i == selected ? Brand.ink : p.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vitrine : la démo en grand (vidéo si disponible), et les miniatures.

class _Showroom extends StatefulWidget {
  const _Showroom({required this.tab});

  final ServiceTab tab;

  @override
  State<_Showroom> createState() => _ShowroomState();
}

class _ShowroomState extends State<_Showroom> {
  /// Les reels durent 13 s : on leur laisse le temps de se terminer.
  Duration get _autoAdvance => widget.tab.showcases.any((s) => s.reel != null)
      ? const Duration(milliseconds: 13200)
      : const Duration(seconds: 9);

  // Point de départ au hasard : chaque passager découvre une autre démo d'abord.
  late int _index = widget.tab.showcases.isEmpty
      ? 0
      : math.Random().nextInt(widget.tab.showcases.length);
  late final PageController _pages = PageController(
    initialPage: _index,
    viewportFraction: 0.9,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (widget.tab.showcases.length < 2) return;
    _timer = Timer.periodic(_autoAdvance, (_) {
      if (!_pages.hasClients) return;
      _go((_index + 1) % widget.tab.showcases.length);
    });
  }

  void _go(int i) => _pages.animateToPage(
    i,
    duration: const Duration(milliseconds: 900),
    curve: AppMotion.emphasized,
  );

  void _select(int i) {
    _go(i);
    _schedule(); // un choix manuel relance le minuteur
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showcases = widget.tab.showcases;
    if (showcases.isEmpty) return BlueprintMockup(frame: widget.tab.frame);
    final current = showcases[_index];
    final p = context.palette;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          // Carrousel 3D : la démo qui part tourne et rétrécit, la suivante
          // arrive en biais, et l'image intérieure glisse plus lentement
          // que le cadre (parallaxe).
          child: NotificationListener<ScrollStartNotification>(
            onNotification: (n) {
              // Le passager reprend la main : on relance le minuteur.
              if (n.dragDetails != null) _schedule();
              return false;
            },
            child: PageView.builder(
              controller: _pages,
              itemCount: showcases.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: _pages,
                builder: (context, child) {
                  final page =
                      _pages.hasClients && _pages.position.haveDimensions
                      ? _pages.page!
                      : _index.toDouble();
                  final d = (page - i).clamp(-1.0, 1.0);
                  return Opacity(
                    opacity: 1 - d.abs() * 0.55,
                    child: Transform(
                      alignment: d > 0
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0011)
                        ..rotateY(d * 0.45)
                        ..scaleByDouble(
                          1 - d.abs() * 0.12,
                          1 - d.abs() * 0.12,
                          1,
                          1,
                        ),
                      // Marge : l'inclinaison au toucher ne se fait pas rogner.
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 8,
                        ),
                        child: _DeviceFrame(
                          showcase: showcases[i],
                          active: i == _index,
                          parallax: d,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, c) {
            final title = AnimatedSwitcher(
              duration: AppMotion.medium,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey(current.title),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current.title,
                    style: AppText.display(32, color: p.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${current.kind.of(context)}  ·  ${l10n.collabDemoBadge}',
                    style: AppText.body(14, color: p.textMuted),
                  ),
                ],
              ),
            );
            final thumbs = [
              for (var i = 0; i < showcases.length; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: _Thumb(
                    showcase: showcases[i],
                    selected: i == _index,
                    onTap: () => _select(i),
                  ),
                ),
            ];
            if (showcases.length < 2) return title;
            // Écran étroit : les miniatures passent sous le titre et
            // défilent, au lieu d'écraser le titre.
            if (c.maxWidth < 640) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: thumbs),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: title),
                ...thumbs,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.showcase,
    required this.selected,
    required this.onTap,
  });

  final Showcase showcase;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.spring,
        width: selected ? 108 : 86,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Brand.gold : context.palette.hairline,
            width: selected ? 2.5 : 1,
          ),
          image: DecorationImage(
            image: AssetImage(showcase.image),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            opacity: selected ? 1 : 0.6,
          ),
        ),
      ),
    );
  }
}

/// Cadre de présentation selon le type de démo : navigateur, téléphone ou
/// tableau de bord. Les sites avec vidéo défilent tout seuls (vidéo muette).
class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({
    required this.showcase,
    this.active = true,
    this.parallax = 0,
  });

  final Showcase showcase;

  /// Seule la démo au centre lit sa vidéo (les voisines restent en image).
  final bool active;

  /// Décalage de -1 à 1 pendant le glissement : l'écran intérieur bouge
  /// moins vite que le cadre.
  final double parallax;

  @override
  Widget build(BuildContext context) {
    final reel = showcase.reel;
    if (reel != null) {
      // Reel monté : plein cadre, sans barre de navigateur, avec un halo
      // de la couleur du site qui bat doucement.
      final poster = showcase.reelPoster ?? showcase.image;
      return Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: TouchTilt(
            child: Heartbeat(
              radius: 24,
              color: showcase.accent,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: showcase.accent.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                ),
                child: Transform.translate(
                  offset: Offset(parallax * 60, 0),
                  child: active
                      ? _LoopingVideo(asset: reel, poster: poster)
                      : Image.asset(poster, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final Widget content = showcase.video != null && active
        ? _LoopingVideo(asset: showcase.video!, poster: showcase.image)
        : _KenBurns(
            image: showcase.image,
            phone: showcase.frame == ShowcaseFrame.phone,
          );
    final screen = ClipRect(
      child: Transform.translate(
        offset: Offset(parallax * 90, 0),
        child: Transform.scale(
          scale: 1 + parallax.abs() * 0.08,
          child: content,
        ),
      ),
    );

    final glow = [
      BoxShadow(
        color: showcase.accent.withValues(alpha: 0.35),
        blurRadius: 70,
        offset: const Offset(0, 24),
      ),
    ];

    if (showcase.frame == ShowcaseFrame.phone) {
      return Center(
        child: AspectRatio(
          aspectRatio: 390 / 844,
          child: TouchTilt(
            radius: 48,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0C10),
                borderRadius: BorderRadius.circular(48),
                boxShadow: glow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(38),
                child: screen,
              ),
            ),
          ),
        ),
      );
    }

    final host = '${showcase.title.toLowerCase().replaceAll(' ', '')}.demo';
    // Ratio de la vidéo (16:9) plus la barre du navigateur : pas de bande noire.
    return Center(
      child: AspectRatio(
        aspectRatio: 1.6,
        child: TouchTilt(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: glow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barre de navigateur stylisée.
                  Container(
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
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                            ),
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
                              style: AppText.body(
                                12,
                                color: const Color(0xFFB4B8C2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 60),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(color: Colors.black, child: screen),
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

/// Vidéo de démo muette, en boucle. L'image fixe s'affiche pendant le chargement.
class _LoopingVideo extends StatefulWidget {
  const _LoopingVideo({required this.asset, required this.poster});

  final String asset;
  final String poster;

  @override
  State<_LoopingVideo> createState() => _LoopingVideoState();
}

class _LoopingVideoState extends State<_LoopingVideo> {
  late final VideoPlayerController _controller = VideoPlayerController.asset(
    widget.asset,
  );
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller
      ..setLooping(true)
      ..setVolume(0);
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _ready = true);
          _controller.play();
        })
        .catchError((Object e) {
          debugPrint('Vidéo indisponible (${widget.asset}) : $e');
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          widget.poster,
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
        ),
        if (_ready)
          FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ).animate().fadeIn(duration: 500.ms),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Argumentaire et appel à l'action.

class _Pitch extends StatelessWidget {
  const _Pitch({required this.tab});

  final ServiceTab tab;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tab.headline.of(context),
            style: AppText.display(50, color: p.text),
          ),
          const SizedBox(height: 16),
          Text(
            tab.pitch.of(context),
            style: AppText.body(17, color: p.textMuted),
          ),
          const SizedBox(height: 26),
          for (final (i, point) in tab.points.indexed)
            Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Brand.gold,
                        ),
                        child: const Icon(
                          AppIcons.check,
                          size: 16,
                          color: Brand.ink,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          point.of(context),
                          style: AppText.body(
                            17,
                            weight: FontWeight.w500,
                            color: p.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: (100 * i).ms, duration: 500.ms)
                .slideX(begin: 0.06, delay: (100 * i).ms),
          const SizedBox(height: 14),
          const _Steps(),
          const SizedBox(height: 26),
          GlowButton(
            label: l10n.collabCta,
            icon: AppIcons.arrowRight,
            onTap: () => showContactSheet(context),
          ),
        ],
      ),
    );
  }
}

/// Les trois étapes d'une collaboration, reliées par un fil doré qui se
/// dessine de gauche à droite.
class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.hairline),
      ),
      child: Stack(
        children: [
          // Fil entre les pastilles numérotées.
          Positioned(
            left: 40,
            right: 40,
            top: 16,
            child:
                Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Brand.goldSoft, Brand.gold],
                    ),
                  ),
                ).animate().scaleX(
                  begin: 0,
                  alignment: Alignment.centerLeft,
                  delay: 500.ms,
                  duration: 1100.ms,
                  curve: AppMotion.emphasized,
                ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, step) in collabSteps.indexed)
                Expanded(
                  child:
                      Column(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Brand.gold,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Brand.gold.withValues(alpha: 0.5),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: AppText.body(
                                    15,
                                    weight: FontWeight.w800,
                                    color: Brand.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  step.of(context),
                                  textAlign: TextAlign.center,
                                  style: AppText.body(
                                    13,
                                    weight: FontWeight.w600,
                                    color: p.text,
                                  ),
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(delay: (500 + 350 * i).ms, duration: 450.ms)
                          .scaleXY(
                            begin: 0.7,
                            delay: (500 + 350 * i).ms,
                            curve: AppMotion.spring,
                          ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Panneau "Parlons de votre projet" : QR LinkedIn et WhatsApp.
Future<void> showContactSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: l10n.back,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: AppMotion.medium,
    transitionBuilder: (context, a, _, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
        scale: Tween(
          begin: 0.94,
          end: 1.0,
        ).animate(CurvedAnimation(parent: a, curve: AppMotion.spring)),
        child: child,
      ),
    ),
    pageBuilder: (context, _, _) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LiquidPill(
            radius: 40,
            solid: true,
            padding: const EdgeInsets.fromLTRB(40, 36, 40, 36),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.contactTitle,
                    textAlign: TextAlign.center,
                    style: AppText.display(40, color: context.palette.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.contactScan,
                    style: AppText.body(16, color: context.palette.textMuted),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 36,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: [
                      QrCard(
                        data: AppConfig.linkedInUrl,
                        icon: AppIcons.linkedin,
                        label: 'LinkedIn',
                        color: const Color(0xFF0A66C2),
                      ),
                      QrCard(
                        data: AppConfig.whatsAppLink,
                        icon: AppIcons.whatsapp,
                        label: 'WhatsApp',
                        color: const Color(0xFF128C4A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PillButton(
                    label: l10n.back,
                    filled: false,
                    onTap: () => Navigator.of(context).pop(),
                    trailing: const Icon(AppIcons.close),
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

/// Image fixe qui vit : zoom et déplacement très lents, en boucle
/// (effet « Ken Burns »), pour que les démos sans vidéo ne soient jamais figées.
class _KenBurns extends StatelessWidget {
  const _KenBurns({required this.image, required this.phone});

  final String image;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      image,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );
    if (MediaQuery.disableAnimationsOf(context)) return img;
    // Zoom et glissement très lents, sur l'horloge décorative commune.
    final wave = DecorValue((s) => 0.5 - 0.5 * math.cos(s / 24 * 2 * math.pi));
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: wave,
        child: img,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -(phone ? 20.0 : 40.0) * wave.value),
          child: Transform.scale(
            scale: 1 + (phone ? 0.06 : 0.1) * wave.value,
            child: child,
          ),
        ),
      ),
    );
  }
}

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
import '../widgets/glass.dart';
import '../widgets/mesh_background.dart';
import '../widgets/qr_card.dart';
import '../widgets/section_scaffold.dart';

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
  static const _autoAdvance = Duration(seconds: 9);

  // Point de départ au hasard : chaque passager découvre une autre démo d'abord.
  late int _index = math.Random().nextInt(widget.tab.showcases.length);
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
      setState(() => _index = (_index + 1) % widget.tab.showcases.length);
    });
  }

  void _select(int i) {
    setState(() => _index = i);
    _schedule(); // un choix manuel relance le minuteur
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showcases = widget.tab.showcases;
    final current = showcases[_index];
    final p = context.palette;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            switchInCurve: AppMotion.spring,
            switchOutCurve: AppMotion.spring,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(
                scale: Tween(begin: 0.97, end: 1.0).animate(a),
                child: child,
              ),
            ),
            child: _DeviceFrame(
              key: ValueKey(current.title),
              showcase: current,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
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
            ),
            if (showcases.length > 1)
              for (var i = 0; i < showcases.length; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: _Thumb(
                    showcase: showcases[i],
                    selected: i == _index,
                    onTap: () => _select(i),
                  ),
                ),
          ],
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
  const _DeviceFrame({super.key, required this.showcase});

  final Showcase showcase;

  @override
  Widget build(BuildContext context) {
    final screen = showcase.video != null
        ? _LoopingVideo(asset: showcase.video!, poster: showcase.image)
        : Image.asset(
            showcase.image,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
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
      );
    }

    final host = '${showcase.title.toLowerCase().replaceAll(' ', '')}.demo';
    return Container(
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
                        style: AppText.body(12, color: const Color(0xFFB4B8C2)),
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
          const SizedBox(height: 28),
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
            padding: const EdgeInsets.fromLTRB(40, 36, 40, 36),
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
  );
}

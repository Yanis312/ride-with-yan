import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/advertisers.dart';
import '../l10n/app_localizations.dart';
import '../navigation/sections.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/decor_clock.dart';
import '../widgets/glass.dart';
import '../widgets/mesh_background.dart';
import '../widgets/qr_card.dart';
import '../widgets/section_scaffold.dart';
import 'collaboration_screen.dart' show showContactSheet;

/// Publicité à bord : les commerces partenaires défilent en cartes qui se
/// retournent (adresse, carte, réseaux), et l'offre pour en devenir un.
class AdsScreen extends StatelessWidget {
  const AdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 900;

    return SectionScaffold(
      scene: Scene.ads,
      section: Section.ads,
      title: l10n.adsTitle,
      child: compact
          ? ListView(
              children: const [
                SizedBox(height: 560, child: _Carousel()),
                SizedBox(height: 24),
                _Offer(),
              ],
            )
          : const Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: _Carousel()),
                SizedBox(width: 36),
                Expanded(flex: 5, child: _Offer()),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carrousel des partenaires.

class _Carousel extends StatefulWidget {
  const _Carousel();

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  // Les partenaires puis la place libre ; départ au hasard parmi les partenaires.
  late final int _count = advertisers.length + 1;
  late final PageController _pages = PageController(
    viewportFraction: 0.88,
    initialPage: math.Random().nextInt(advertisers.length),
  );
  Timer? _timer;
  bool _flipped = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _page = _pages.initialPage;
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      // On ne fait pas défiler une carte que le passager est en train de lire.
      if (_flipped || !_pages.hasClients) return;
      _pages.animateToPage(
        (_page + 1) % _count,
        duration: AppMotion.slow,
        curve: AppMotion.spring,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: _count,
            onPageChanged: (i) => setState(() {
              _page = i;
              _flipped = false;
            }),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: i < advertisers.length
                  ? _FlipCard(
                      key: ValueKey(i),
                      advertiser: advertisers[i],
                      onFlip: (flipped) => setState(() => _flipped = flipped),
                    )
                  : const _FreeSpotCard(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _count; i++)
              AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.spring,
                width: i == _page ? 28 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: i == _page ? Brand.gold : p.hairline,
                ),
              ),
            const SizedBox(width: 16),
            Icon(AppIcons.flip, size: 18, color: p.textMuted),
            const SizedBox(width: 6),
            Text(l10n.adsTapHint, style: AppText.body(14, color: p.textMuted)),
          ],
        ),
      ],
    );
  }
}

/// Carte qui pivote en 3D : recto (visuel et nom), verso (détails et carte).
class _FlipCard extends StatefulWidget {
  const _FlipCard({super.key, required this.advertiser, required this.onFlip});

  final Advertiser advertiser;
  final ValueChanged<bool> onFlip;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  void _toggle() {
    final toBack = _flip.value < 0.5;
    if (toBack) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
    widget.onFlip(toBack);
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          final t = AppMotion.emphasized.transform(_flip.value);
          final angle = t * math.pi;
          final back = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..rotateY(angle),
            child: back
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: _AdBack(
                      advertiser: widget.advertiser,
                      onClose: _toggle,
                    ),
                  )
                : _AdFront(advertiser: widget.advertiser),
          );
        },
      ),
    );
  }
}

class _ExampleBadge extends StatelessWidget {
  const _ExampleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        AppLocalizations.of(context).adsExample.toUpperCase(),
        style: AppText.eyebrow(Colors.white),
      ),
    );
  }
}

class _AdFront extends StatelessWidget {
  const _AdFront({required this.advertiser});

  final Advertiser advertiser;

  @override
  Widget build(BuildContext context) {
    final a = advertiser;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        image: a.photo == null
            ? null
            : DecorationImage(image: AssetImage(a.photo!), fit: BoxFit.cover),
        gradient: a.photo == null
            ? RadialGradient(
                center: const Alignment(-0.4, -0.6),
                radius: 1.3,
                colors: a.colors,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: a.colors.first.withValues(alpha: 0.45),
            blurRadius: 60,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          // Voile sombre en bas pour garder le texte lisible sur une photo.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (a.example) const _ExampleBadge(),
                const Spacer(),
                Icon(
                  AppIcons.flip,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 26,
                ),
              ],
            ),
            const Spacer(),
            if (a.photo == null)
              Icon(
                a.icon,
                size: 72,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            const SizedBox(height: 18),
            Text(a.name, style: AppText.display(64, color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              a.category.of(context),
              style: AppText.body(
                18,
                weight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(AppIcons.mapPin, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    a.address,
                    style: AppText.body(
                      15,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final icon in [
                  if (a.instagram != null) AppIcons.instagram,
                  if (a.tiktok != null) AppIcons.tiktok,
                  if (a.facebook != null) AppIcons.facebook,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdBack extends StatelessWidget {
  const _AdBack({required this.advertiser, required this.onClose});

  final Advertiser advertiser;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final a = advertiser;
    final p = context.palette;
    final accent = a.colors.first;

    Widget info(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppText.body(15, weight: FontWeight.w500, color: p.text),
            ),
          ),
        ],
      ),
    );

    final socials = [
      if (a.instagram != null) (AppIcons.instagram, 'Instagram', a.instagram!),
      if (a.tiktok != null) (AppIcons.tiktok, 'TikTok', a.tiktok!),
      if (a.facebook != null) (AppIcons.facebook, 'Facebook', a.facebook!),
    ];

    return BezelCard(
      radius: 34,
      tint: accent,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(a.name, style: AppText.display(36, color: p.text)),
              ),
              if (a.example) const _ExampleBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            a.description.of(context),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(15, color: p.textMuted),
          ),
          const SizedBox(height: 16),
          info(AppIcons.mapPin, a.address),
          info(AppIcons.phone, a.phone),
          info(AppIcons.clock, a.hours.of(context)),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final (icon, label, url) in socials)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: PillButton(
                    label: label,
                    filled: false,
                    onTap: () => _showSocialQr(context, icon, label, url),
                    trailing: Icon(icon),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _MiniMap(location: a.location, accent: accent),
          ),
        ],
      ),
    );
  }
}

/// Petite carte OpenStreetMap figée, centrée sur le commerce.
class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.location, required this.accent});

  final LatLng location;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: location,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yanis312.ride_with_yan',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: location,
                    width: 52,
                    height: 52,
                    alignment: Alignment.topCenter,
                    child: Icon(
                      AppIcons.mapPin,
                      size: 52,
                      color: accent,
                      shadows: const [Shadow(blurRadius: 12)],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 8,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.white.withValues(alpha: 0.8),
              child: Text(
                '© OpenStreetMap',
                style: AppText.body(10, color: Brand.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showSocialQr(
  BuildContext context,
  IconData icon,
  String label,
  String url,
) {
  final l10n = AppLocalizations.of(context);
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: l10n.back,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: AppMotion.medium,
    transitionBuilder: (context, a, _, child) =>
        FadeTransition(opacity: a, child: child),
    pageBuilder: (context, _, _) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: LiquidPill(
          radius: 40,
          solid: true,
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.adsScanSocial(label),
                style: AppText.display(34, color: context.palette.text),
              ),
              const SizedBox(height: 24),
              QrCard(
                data: url,
                icon: icon,
                label: label,
                color: const Color(0xFFC13584),
                size: 220,
              ),
              const SizedBox(height: 22),
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
  );
}

/// Dernière carte : la place libre, pour donner envie aux commerçants.
class _FreeSpotCard extends StatelessWidget {
  const _FreeSpotCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Pressable(
      onTap: () => showContactSheet(context),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Brand.gold, width: 2),
          color: Brand.gold.withValues(alpha: 0.08),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const DecorPulse(
              period: 2.8,
              scale: 1.1,
              child: Icon(AppIcons.crown, size: 72, color: Brand.gold),
            ),
            const SizedBox(height: 22),
            Text(
              l10n.adsYourSpot,
              textAlign: TextAlign.center,
              style: AppText.display(48, color: p.text),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.adsYourSpotHint,
              textAlign: TextAlign.center,
              style: AppText.body(18, color: p.textMuted),
            ),
            const SizedBox(height: 26),
            GlowButton(
              label: l10n.adsCta,
              icon: AppIcons.arrowRight,
              onTap: () => showContactSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// L'offre.

class _Offer extends StatelessWidget {
  const _Offer();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final points = [
      (AppIcons.storefront, l10n.adsPoint1),
      (AppIcons.instagram, l10n.adsPoint2),
      (AppIcons.mapPin, l10n.adsPoint3),
      (AppIcons.megaphone, l10n.adsPoint4),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.adsHeadline, style: AppText.display(54, color: p.text)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.adsPrice,
                style: AppText.display(44, color: p.text).copyWith(
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Brand.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [Brand.goldSoft, Brand.gold],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.gift, size: 20, color: Brand.ink),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.adsFreeBadge,
                    style: AppText.body(
                      15,
                      weight: FontWeight.w600,
                      color: Brand.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          for (final (i, (icon, text)) in points.indexed)
            Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.glass,
                          border: Border.all(color: p.hairline),
                        ),
                        child: Icon(icon, size: 20, color: Brand.gold),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          text,
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
                .fadeIn(delay: (90 * i).ms, duration: 500.ms)
                .slideX(begin: 0.06, delay: (90 * i).ms),
          const SizedBox(height: 24),
          GlowButton(
            label: l10n.adsCta,
            icon: AppIcons.arrowRight,
            onTap: () => showContactSheet(context),
          ),
        ],
      ),
    );
  }
}

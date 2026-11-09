import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config.dart';
import '../data/bilingual.dart';
import '../data/profile.dart';
import '../l10n/app_localizations.dart';
import '../navigation/sections.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/mesh_background.dart';
import '../widgets/qr_card.dart';
import '../widgets/section_scaffold.dart';

const _linkedInBlue = Color(0xFF0A66C2);

/// Aperçu du profil LinkedIn de Yanis, consultable comme un invité (aucune
/// action possible), avec un QR code pour l'ouvrir sur son propre téléphone.
class LinkedInScreen extends StatelessWidget {
  const LinkedInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;

    const preview = _ProfilePreview();
    final qr = _ScanPanel(compact: compact);

    return SectionScaffold(
      scene: Scene.profile,
      section: Section.linkedin,
      title: 'LinkedIn',
      child: compact
          ? ListView(
              children: [
                qr,
                const SizedBox(height: 24),
                const SizedBox(height: 900, child: preview),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(flex: 7, child: preview),
                const SizedBox(width: 36),
                Expanded(flex: 5, child: Center(child: qr)),
              ],
            ),
    );
  }
}

class _ScanPanel extends StatelessWidget {
  const _ScanPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QrCard(
              data: AppConfig.linkedInUrl,
              icon: AppIcons.linkedin,
              label: 'LinkedIn',
              color: _linkedInBlue,
              size: compact ? 200 : 260,
            )
            .animate()
            .fadeIn(duration: 700.ms)
            .scale(begin: const Offset(0.9, 0.9), curve: AppMotion.spring),
        const SizedBox(height: 26),
        Text(
          l10n.scanLinkedIn,
          textAlign: TextAlign.center,
          style: AppText.display(40, color: p.text),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Text(
            l10n.scanHint,
            textAlign: TextAlign.center,
            style: AppText.body(15, color: p.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Reproduction de la page de profil LinkedIn en mode invité, défilable.
class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview();

  @override
  Widget build(BuildContext context) {
    final c = _LiColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _linkedInBlue.withValues(alpha: 0.35),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(
          color: c.page,
          child: Column(
            children: [
              _TopBar(c: c, label: l10n.profilePreview),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                  children: [
                    _Header(c: c),
                    _Card(
                      c: c,
                      title: const Bi('Infos', 'About'),
                      child: Text(
                        Profile.about.of(context),
                        style: AppText.body(15, color: c.text),
                      ),
                    ),
                    _EntriesCard(
                      c: c,
                      title: const Bi('Expérience', 'Experience'),
                      entries: Profile.experience,
                    ),
                    _EntriesCard(
                      c: c,
                      title: const Bi('Formation', 'Education'),
                      entries: Profile.education,
                    ),
                    _EntriesCard(
                      c: c,
                      title: const Bi(
                        'Licences et certifications',
                        'Licenses & certifications',
                      ),
                      entries: Profile.certifications,
                    ),
                    _EntriesCard(
                      c: c,
                      title: const Bi('Projets', 'Projects'),
                      entries: Profile.projects,
                    ),
                    _Card(
                      c: c,
                      title: const Bi('Compétences', 'Skills'),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in Profile.skills)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: c.border),
                              ),
                              child: Text(
                                s,
                                style: AppText.body(
                                  14,
                                  weight: FontWeight.w600,
                                  color: c.text,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _Card(
                      c: c,
                      title: const Bi('Langues', 'Languages'),
                      child: Text(
                        Profile.languages
                            .map((l) => l.of(context))
                            .join('  ·  '),
                        style: AppText.body(15, color: c.text),
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

/// Couleurs de LinkedIn, en clair et en sombre.
class _LiColors {
  const _LiColors({
    required this.page,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.link,
    required this.openBg,
  });

  factory _LiColors.of(BuildContext context) => context.isDark
      ? const _LiColors(
          page: Color(0xFF000000),
          card: Color(0xFF1B1F23),
          text: Color(0xFFE9E9E9),
          muted: Color(0xFFA6A6A6),
          border: Color(0xFF5E6265),
          link: Color(0xFF71B7FB),
          openBg: Color(0xFF263A4F),
        )
      : const _LiColors(
          page: Color(0xFFF4F2EE),
          card: Colors.white,
          text: Color(0xE6000000),
          muted: Color(0x99000000),
          border: Color(0x66000000),
          link: _linkedInBlue,
          openBg: Color(0xFFDDE7F1),
        );

  final Color page;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final Color link;
  final Color openBg;
}

/// Barre du haut : logo, champ de recherche, mention "aperçu".
class _TopBar extends StatelessWidget {
  const _TopBar({required this.c, required this.label});

  final _LiColors c;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: c.card,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _linkedInBlue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'in',
              style: AppText.body(
                20,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              height: 36,
              constraints: const BoxConstraints(maxWidth: 260),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.globe, size: 16, color: c.muted),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      Profile.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(14, color: c.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: AppText.body(13, weight: FontWeight.w600, color: c.muted),
          ),
        ],
      ),
    );
  }
}

/// En-tête : photo de couverture, photo de profil #OPENTOWORK, nom, titre,
/// école, abonnés et encart "à l'écoute d'opportunités".
class _Header extends StatelessWidget {
  const _Header({required this.c});

  final _LiColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth > 620;
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    Profile.name,
                    style: AppText.body(
                      26,
                      weight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  Icon(AppIcons.sealCheck, size: 22, color: c.muted),
                  Text(
                    Profile.pronoun,
                    style: AppText.body(14, color: c.muted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                Profile.headline.of(context),
                style: AppText.body(16, color: c.text),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${Profile.location.of(context)}  ·  '),
                    TextSpan(
                      text: const Bi('Coordonnées', 'Contact info').of(context),
                      style: AppText.body(
                        14,
                        weight: FontWeight.w600,
                        color: c.link,
                      ),
                    ),
                  ],
                ),
                style: AppText.body(14, color: c.muted),
              ),
              const SizedBox(height: 6),
              Text(
                '${Profile.followers.of(context)}  ·  '
                '${Profile.connections.of(context)}',
                style: AppText.body(14, weight: FontWeight.w600, color: c.link),
              ),
            ],
          );
          final school = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF3FAE49),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LC',
                  style: AppText.body(
                    12,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                Profile.school,
                style: AppText.body(15, weight: FontWeight.w600, color: c.text),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: wide ? 250 : 210,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: wide ? 170 : 130,
                      width: double.infinity,
                      child: Image.asset(
                        Profile.cover,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0.2, -0.55),
                        excludeFromSemantics: true,
                      ),
                    ),
                    Positioned(
                      left: 22,
                      bottom: 0,
                      child: _OpenToWorkAvatar(
                        size: wide ? 150 : 132,
                        border: c.card,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: identity),
                          const SizedBox(width: 18),
                          school,
                        ],
                      )
                    else ...[
                      identity,
                      const SizedBox(height: 12),
                      school,
                    ],
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.openBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Profile.openToWork.of(context),
                            style: AppText.body(
                              14,
                              weight: FontWeight.w600,
                              color: c.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Profile.openToWorkDetail.of(context),
                            style: AppText.body(14, color: c.text),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            const Bi(
                              'Afficher les détails',
                              'Show details',
                            ).of(context),
                            style: AppText.body(
                              14,
                              weight: FontWeight.w600,
                              color: c.link,
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
        },
      ),
    );
  }
}

/// Photo de profil entourée de l'anneau vert #OPENTOWORK.
class _OpenToWorkAvatar extends StatelessWidget {
  const _OpenToWorkAvatar({required this.size, required this.border});

  final double size;
  final Color border;

  static const _green = Color(0xFF3F8B3F);

  @override
  Widget build(BuildContext context) {
    final ring = size * 0.09;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(shape: BoxShape.circle, color: border),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [_green, _green, Color(0x003F8B3F), _green],
                stops: [0, 0.55, 0.75, 1],
              ),
            ),
            child: SizedBox.expand(),
          ),
          Padding(
            padding: EdgeInsets.all(ring),
            child: ClipOval(
              child: Image.asset(
                Profile.avatar,
                fit: BoxFit.cover,
                semanticLabel: Profile.name,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ArcLabel(
                '#OPENTOWORK',
                AppText.body(
                  size * 0.062,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
                inset: ring / 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Écrit un texte le long du bas-gauche d'un cercle, lisible de l'extérieur.
class _ArcLabel extends CustomPainter {
  _ArcLabel(this.text, this.style, {required this.inset});

  final String text;
  final TextStyle style;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - inset;
    final glyphs = [
      for (final ch in text.split(''))
        TextPainter(
          text: TextSpan(text: ch, style: style),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    final total = glyphs.fold<double>(0, (s, g) => s + g.width);
    // Centré vers 135° (bas-gauche), lu de gauche à droite.
    var angle = 2.36 + total / radius / 2;
    for (final g in glyphs) {
      final half = g.width / 2 / radius;
      angle -= half;
      canvas
        ..save()
        ..translate(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        )
        ..rotate(angle - math.pi / 2);
      g.paint(canvas, Offset(-g.width / 2, -g.height / 2));
      canvas.restore();
      angle -= half;
    }
  }

  @override
  bool shouldRepaint(_ArcLabel old) => old.text != text || old.style != style;
}

/// Carte de section avec titre, façon LinkedIn.
class _Card extends StatelessWidget {
  const _Card({required this.c, required this.title, required this.child});

  final _LiColors c;
  final Bi title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.of(context),
            style: AppText.body(20, weight: FontWeight.w600, color: c.text),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Section faite de lignes (expérience, formation, certifications, projets).
class _EntriesCard extends StatelessWidget {
  const _EntriesCard({
    required this.c,
    required this.title,
    required this.entries,
  });

  final _LiColors c;
  final Bi title;
  final List<ProfileEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _Card(
      c: c,
      title: title,
      child: Column(
        children: [
          for (final (i, e) in entries.indexed) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(62, 12, 0, 12),
                child: Divider(
                  height: 1,
                  color: c.border.withValues(alpha: 0.15),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _linkedInBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    e.logo ?? '',
                    style: AppText.body(
                      15,
                      weight: FontWeight.w700,
                      color: c.link,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title.of(context),
                        style: AppText.body(
                          16,
                          weight: FontWeight.w600,
                          color: c.text,
                        ),
                      ),
                      Text(
                        e.org.of(context),
                        style: AppText.body(14, color: c.text),
                      ),
                      Text(
                        e.dates.of(context),
                        style: AppText.body(14, color: c.muted),
                      ),
                      if (e.place case final place?)
                        Text(
                          place.of(context),
                          style: AppText.body(14, color: c.muted),
                        ),
                      if (e.detail case final detail?) ...[
                        const SizedBox(height: 6),
                        Text(
                          detail.of(context),
                          style: AppText.body(14, color: c.text),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

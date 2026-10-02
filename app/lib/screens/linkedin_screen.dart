import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config.dart';
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

/// Reproduction de la page de profil en mode invité, défilable.
class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview();

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final page = dark ? const Color(0xFF000000) : const Color(0xFFF4F2EE);
    final card = dark ? const Color(0xFF1B1F23) : Colors.white;
    final text = dark ? const Color(0xFFE9E9E9) : const Color(0xE6000000);
    final muted = dark ? const Color(0xFFA6A6A6) : const Color(0x99000000);
    final l10n = AppLocalizations.of(context);

    Widget section(String title, Widget body) => Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.body(20, weight: FontWeight.w600, color: text),
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );

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
          color: page,
          child: Column(
            children: [
              // Barre façon LinkedIn, avec la mention "aperçu".
              Container(
                height: 52,
                color: card,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _linkedInBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'in',
                        style: AppText.body(
                          17,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.profilePreview,
                      style: AppText.body(
                        14,
                        weight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                    const Spacer(),
                    Icon(AppIcons.globe, size: 18, color: muted),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                  children: [
                    _Header(card: card, text: text, muted: muted),
                    section(
                      l10n.aboutTitle,
                      Text(
                        Profile.about.of(context),
                        style: AppText.body(15, color: text),
                      ),
                    ),
                    section(
                      l10n.experienceTitle,
                      Column(
                        children: [
                          for (final (icon, title, detail)
                              in Profile.experience)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _linkedInBlue.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: _linkedInBlue,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title.of(context),
                                          style: AppText.body(
                                            16,
                                            weight: FontWeight.w600,
                                            color: text,
                                          ),
                                        ),
                                        Text(
                                          detail.of(context),
                                          style: AppText.body(14, color: muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    section(
                      l10n.skillsTitle,
                      Wrap(
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
                                border: Border.all(
                                  color: muted.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                s,
                                style: AppText.body(
                                  14,
                                  weight: FontWeight.w500,
                                  color: text,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    section(
                      l10n.languagesTitle,
                      Text(
                        Profile.languages
                            .map((l) => l.of(context))
                            .join('  ·  '),
                        style: AppText.body(15, color: text),
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

class _Header extends StatelessWidget {
  const _Header({required this.card, required this.text, required this.muted});

  final Color card;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bannière et photo de profil.
          SizedBox(
            height: 170,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0A66C2),
                        Color(0xFF16305C),
                        Color(0xFF8A6200),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  top: 56,
                  child: Container(
                    width: 112,
                    height: 112,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Brand.goldSoft, Brand.gold],
                      ),
                      border: Border.all(color: card, width: 5),
                    ),
                    child: Text(
                      'YG',
                      style: AppText.display(44, color: Brand.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Profile.name,
                  style: AppText.body(26, weight: FontWeight.w600, color: text),
                ),
                const SizedBox(height: 4),
                Text(
                  Profile.headline.of(context),
                  style: AppText.body(16, color: text),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(AppIcons.mapPin, size: 16, color: muted),
                    const SizedBox(width: 4),
                    Text(
                      Profile.location.of(context),
                      style: AppText.body(14, color: muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../backend/usage.dart';
import '../data/bilingual.dart';
import '../data/privacy.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

/// Lien discret « Confidentialité » qui ouvre la politique.
class PrivacyLink extends StatelessWidget {
  const PrivacyLink({super.key, this.size = 12});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showPrivacySheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.lockKey, size: size + 2, color: p.textMuted),
              const SizedBox(width: 6),
              Text(
                const Bi(
                  'Confidentialité et vos renseignements',
                  'Privacy and your information',
                ).of(context),
                style: AppText.body(
                  size,
                  color: p.textMuted,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Politique de confidentialité complète, dans la langue du passager.
Future<void> showPrivacySheet(BuildContext context) {
  Usage.instance.tap('privacy.open');
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final p = context.palette;
      return FractionallySizedBox(
        heightFactor: 0.9,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LiquidPill(
            radius: 28,
            solid: true,
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  const Bi('Confidentialité', 'Privacy').of(context),
                  style: AppText.display(34, color: p.text),
                ),
                Text(
                  privacyUpdated.of(context),
                  style: AppText.body(12, color: p.textMuted),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      Text(
                        privacyIntro.of(context),
                        style: AppText.body(15, color: p.text),
                      ),
                      for (final (title, body) in privacySections) ...[
                        const SizedBox(height: 16),
                        Text(
                          title.of(context),
                          style: AppText.body(
                            16,
                            weight: FontWeight.w600,
                            color: p.accentText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body.of(context),
                          style: AppText.body(14, color: p.text),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: PillButton(
                    label: const Bi('Fermer', 'Close').of(context),
                    filled: false,
                    onTap: () => Navigator.of(context).pop(),
                    trailing: const Icon(AppIcons.close),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../navigation/sections.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

/// Dock en verre liquide : LinkedIn, Collaborations et Boutique, présent sur
/// tous les écrans. [current] met en avant la section ouverte.
class QuickDock extends StatelessWidget {
  const QuickDock({super.key, this.current, this.compact = false});

  final Section? current;

  /// Icônes seules (petits écrans).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (Section.linkedin, AppIcons.linkedin, l10n.dockLinkedIn),
      (Section.collaboration, AppIcons.handshake, l10n.dockCollab),
      (Section.store, AppIcons.storefront, l10n.dockStore),
    ];

    return LiquidPill(
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (section, icon, label) in items)
            _DockItem(
              icon: icon,
              label: compact ? null : label,
              selected: section == current,
              onTap: () => openSection(context, section),
            ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? Brand.ink : p.text;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.spring,
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? 12 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected
              ? const LinearGradient(colors: [Brand.goldSoft, Brand.gold])
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: fg),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label!,
                style: AppText.body(15, weight: FontWeight.w600, color: fg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

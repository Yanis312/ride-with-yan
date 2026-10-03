import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../navigation/sections.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'heartbeat.dart';

/// Dock en verre liquide présent sur tous les écrans. Les sections qui
/// rapportent (Collaborations, Boutique, Pub) sont mises en avant par une
/// bordure de lumière qui tourne. [current] signale la section ouverte.
class QuickDock extends StatefulWidget {
  const QuickDock({super.key, this.current, this.compact = false});

  final Section? current;

  /// Icônes seules (petits écrans).
  final bool compact;

  /// Sections mises en avant.
  static const featured = {Section.collaboration, Section.store, Section.ads};

  @override
  State<QuickDock> createState() => _QuickDockState();
}

class _QuickDockState extends State<QuickDock>
    with SingleTickerProviderStateMixin {
  // Une seule horloge pour toutes les bordures lumineuses du dock.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (Section.music, AppIcons.music, l10n.dockMusic),
      (Section.linkedin, AppIcons.linkedin, l10n.dockLinkedIn),
      (Section.collaboration, AppIcons.handshake, l10n.dockCollab),
      (Section.store, AppIcons.storefront, l10n.dockStore),
      (Section.ads, AppIcons.megaphone, l10n.dockAds),
    ];

    // Taille naturelle, mais jamais plus de 60 % de l'écran : si la place
    // manque, le dock rétrécit un peu plutôt que de faire déborder la barre.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.6,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Heartbeat(
          child: LiquidPill(
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, (section, icon, label)) in items.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _DockItem(
                      icon: icon,
                      label: widget.compact ? null : label,
                      selected: section == widget.current,
                      featured: QuickDock.featured.contains(section),
                      spin: _spin,
                      // Les bordures ne tournent pas en même temps : effet de vague.
                      phase: i * 0.27,
                      onTap: () => openSection(context, section),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.featured,
    required this.spin,
    required this.phase,
    required this.onTap,
  });

  final IconData icon;
  final String? label;
  final bool selected;
  final bool featured;
  final Animation<double> spin;
  final double phase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected
        ? Brand.ink
        : (featured ? const Color(0xFFFFE08A) : p.text);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: selected ? Brand.ink : Brand.gold,
          shadows: selected
              ? null
              : [
                  Shadow(
                    color: Brand.gold.withValues(alpha: 0.9),
                    blurRadius: featured ? 16 : 10,
                  ),
                ],
        ),
        if (label != null) ...[
          const SizedBox(width: 8),
          Text(
            label!,
            style: AppText.body(15, weight: FontWeight.w600, color: fg)
                .copyWith(
                  shadows: featured && !selected
                      ? [
                          Shadow(
                            color: Brand.gold.withValues(alpha: 0.7),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
          ),
        ],
      ],
    );

    final padding = EdgeInsets.symmetric(
      horizontal: label == null ? 12 : 16,
      vertical: 10,
    );

    Widget item;
    if (selected) {
      item = AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.spring,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(colors: [Brand.goldSoft, Brand.gold]),
        ),
        child: content,
      );
    } else if (featured) {
      // Bordure de lumière dorée qui tourne autour du bouton.
      item = AnimatedBuilder(
        animation: spin,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: RadialGradient(
              radius: 2.2,
              colors: [
                Brand.gold.withValues(alpha: 0.28),
                const Color(0xF0120E06),
              ],
            ),
          ),
          child: content,
        ),
        builder: (context, child) => Container(
          padding: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: SweepGradient(
              transform: GradientRotation((spin.value + phase) * 2 * math.pi),
              colors: [
                Brand.gold.withValues(alpha: 0.15),
                const Color(0xFFFFF4C2),
                Brand.gold,
                Brand.gold.withValues(alpha: 0.15),
                Brand.gold.withValues(alpha: 0.15),
              ],
              stops: const [0, 0.12, 0.25, 0.4, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: Brand.gold.withValues(alpha: 0.35),
                blurRadius: 14,
              ),
            ],
          ),
          child: child,
        ),
      );
    } else {
      item = Padding(padding: padding, child: content);
    }

    return Pressable(onTap: onTap, child: item);
  }
}

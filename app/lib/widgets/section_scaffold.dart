import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../navigation/sections.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/appearance_controller.dart';
import 'glass.dart';
import 'mesh_background.dart';
import 'quick_dock.dart';

/// Cadre commun des sections : fond animé, retour, titre, mode clair/sombre
/// et dock de navigation.
class SectionScaffold extends StatelessWidget {
  const SectionScaffold({
    super.key,
    required this.scene,
    this.section,
    required this.title,
    required this.child,
    this.trailing,
  });

  final Scene scene;

  /// Section du dock à surligner ; aucune pour les écrans du lounge.
  final Section? section;
  final String title;
  final Widget child;

  /// Élément affiché avant le dock (ex. panier).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final compact = MediaQuery.sizeOf(context).width < 760;
    final appearance = AppearanceScope.of(context);

    return Scaffold(
      body: MeshBackground(
        scene: scene,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 40,
              18,
              compact ? 16 : 40,
              compact ? 16 : 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    LiquidIconButton(
                      icon: AppIcons.arrowLeft,
                      size: 48,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(
                          compact ? 30 : 40,
                          color: p.text,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      trailing!,
                      const SizedBox(width: 12),
                    ],
                    LiquidIconButton(
                      icon: context.isDark ? AppIcons.sun : AppIcons.moon,
                      size: 48,
                      onTap: appearance.toggle,
                    ),
                    const SizedBox(width: 12),
                    QuickDock(
                      current: section,
                      // Icônes seules sous 1100 px : le titre garde sa place.
                      compact: MediaQuery.sizeOf(context).width < 1100,
                    ),
                  ],
                ).animate().fadeIn(
                  duration: AppMotion.medium,
                  curve: AppMotion.spring,
                ),
                SizedBox(height: compact ? 16 : 24),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

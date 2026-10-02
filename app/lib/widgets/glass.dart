import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Carte "double bordure" : une coque translucide qui tient un noyau,
/// comme une plaque de verre posée dans un cadre en aluminium.
class BezelCard extends StatelessWidget {
  const BezelCard({
    super.key,
    required this.child,
    this.radius = 32,
    this.padding = const EdgeInsets.all(28),
    this.coreGradient,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Gradient? coreGradient;

  static const _shell = 6.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_shell),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius - _shell),
            gradient:
                coreGradient ??
                const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF15171D), Color(0xFF0C0D11)],
                ),
            // Reflet d'un pixel sur l'arête haute du noyau.
            border: const Border(top: BorderSide(color: AppColors.highlight)),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Rend [child] pressable avec un léger enfoncement physique.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? 0.975 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.spring,
        child: widget.child,
      ),
    );
  }
}

/// Petite étiquette en capitales espacées placée au-dessus d'un titre.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.eyebrow,
      ),
    );
  }
}

/// Bouton pilule avec son icône nichée dans un cercle à droite.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.trailing,
    this.filled = true,
    this.large = false,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool filled;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.ink : AppColors.text;
    final circle = large ? 44.0 : 36.0;

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(large ? 30 : 22, 6, 6, 6),
        decoration: BoxDecoration(
          color: filled ? AppColors.gold : AppColors.glass,
          borderRadius: BorderRadius.circular(999),
          border: filled ? null : Border.all(color: AppColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppText.body(
                large ? 20 : 16,
                weight: FontWeight.w600,
                color: fg,
              ),
            ),
            SizedBox(width: large ? 18 : 14),
            Container(
              width: circle,
              height: circle,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? AppColors.ink.withValues(alpha: 0.12)
                    : AppColors.hairline,
              ),
              child: IconTheme(
                data: IconThemeData(color: fg, size: large ? 20 : 17),
                child: DefaultTextStyle(
                  style: AppText.body(13, weight: FontWeight.w600, color: fg),
                  child: trailing ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

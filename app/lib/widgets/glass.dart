import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_theme.dart';

/// Carte "double bordure" : une coque translucide qui tient un noyau,
/// comme une plaque de verre posée dans un cadre en aluminium.
class BezelCard extends StatelessWidget {
  const BezelCard({
    super.key,
    required this.child,
    this.radius = 32,
    this.padding = const EdgeInsets.all(28),
    this.tint,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;

  /// Couleur d'ambiance qui teinte le noyau (carte mise en avant).
  final Color? tint;

  static const _shell = 6.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = tint == null
        ? p.coreTop
        : Color.alphaBlend(tint!.withValues(alpha: 0.28), p.coreTop);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.hairline),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(_shell),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius - _shell),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [top, p.coreBottom],
            ),
            // Reflet d'un pixel sur l'arête haute du noyau.
            border: Border(top: BorderSide(color: p.highlight)),
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
  const Eyebrow(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.hairline),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.eyebrow(color ?? p.accentText),
      ),
    );
  }
}

/// Bouton pilule avec son icône nichée dans un cercle à droite.
/// [filled] : or plein (action principale). Sinon verre translucide.
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
    final p = context.palette;
    final fg = filled ? Brand.ink : p.text;
    final circle = large ? 44.0 : 36.0;

    final content = Padding(
      padding: EdgeInsets.fromLTRB(large ? 30 : 22, 6, 6, 6),
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
              color: filled ? Brand.ink.withValues(alpha: 0.12) : p.hairline,
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
    );

    return Pressable(
      onTap: onTap,
      child: filled
          ? DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Brand.goldSoft, Brand.gold, Color(0xFFE59A00)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: content,
            )
          : LiquidPill(child: content),
    );
  }
}

/// Surface "Liquid Glass" façon iOS 26 en forme de pilule : elle réfracte
/// le fond animé placé derrière (voir MeshBackground).
class LiquidPill extends StatelessWidget {
  const LiquidPill({
    super.key,
    required this.child,
    this.radius = 999,
    this.padding,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      shape: LiquidRoundedSuperellipse(borderRadius: radius),
      padding: padding,
      settings: LiquidGlassSettings(
        glassColor: context.isDark
            ? const Color(0x14FFFFFF)
            : const Color(0x59FFFFFF),
        thickness: 22,
        blur: 8,
        lightIntensity: 0.6,
      ),
      child: child,
    );
  }
}

/// Bouton rond en verre liquide (icône seule).
class LiquidIconButton extends StatelessWidget {
  const LiquidIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 52,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      width: size,
      height: size,
      onTap: onTap,
      icon: Icon(icon, color: context.palette.text, size: size * 0.42),
      settings: LiquidGlassSettings(
        glassColor: context.isDark
            ? const Color(0x14FFFFFF)
            : const Color(0x59FFFFFF),
        thickness: 24,
        blur: 8,
      ),
    );
  }
}

/// Grand bouton d'appel à l'action : or dégradé, halo lumineux et reflet
/// qui balaie la surface.
class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);

    Widget pill = Container(
      padding: const EdgeInsets.fromLTRB(34, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE08A), Brand.gold, Color(0xFFE08A00)],
        ),
        boxShadow: [
          BoxShadow(
            color: Brand.gold.withValues(alpha: 0.45),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                20,
                weight: FontWeight.w600,
                color: Brand.ink,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Brand.ink,
            ),
            child: Icon(icon, color: Brand.gold, size: 22),
          ),
        ],
      ),
    );

    if (!reduce) {
      pill = pill
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            delay: 1800.ms,
            duration: 1400.ms,
            color: Colors.white.withValues(alpha: 0.3),
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.035, duration: 2200.ms, curve: Curves.easeInOutSine);
    }

    // Animation continue isolée : seul le bouton est redessiné, pas l'écran.
    return RepaintBoundary(
      child: Pressable(onTap: onTap, child: pill),
    );
  }
}

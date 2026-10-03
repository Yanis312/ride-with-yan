import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Incline doucement [child] en 3D vers le doigt, avec un reflet de lumière
/// qui suit le toucher. Utilise un Listener (pas de geste) : le glissement
/// horizontal du carrousel reste disponible.
class TouchTilt extends StatefulWidget {
  const TouchTilt({
    super.key,
    required this.child,
    this.maxAngle = 0.12,
    this.radius = 22,
  });

  final Widget child;

  /// Inclinaison maximale en radians (~7°).
  final double maxAngle;
  final double radius;

  @override
  State<TouchTilt> createState() => _TouchTiltState();
}

class _TouchTiltState extends State<TouchTilt> {
  Offset _target = Offset.zero; // -1..1 sur chaque axe
  Offset? _light; // position du reflet, en fraction de la taille
  Size _size = Size.zero;

  void _update(Offset local) {
    if (_size.isEmpty) return;
    final nx = (local.dx / _size.width).clamp(0.0, 1.0);
    final ny = (local.dy / _size.height).clamp(0.0, 1.0);
    setState(() {
      _target = Offset(nx * 2 - 1, ny * 2 - 1);
      _light = Offset(nx, ny);
    });
  }

  void _release() => setState(() {
    _target = Offset.zero;
    _light = null;
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return LayoutBuilder(
      builder: (context, c) {
        _size = c.biggest;
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) => _update(e.localPosition),
          onPointerMove: (e) => _update(e.localPosition),
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(end: _target),
            duration: const Duration(milliseconds: 260),
            curve: AppMotion.spring,
            builder: (context, t, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(-t.dy * widget.maxAngle)
                ..rotateY(t.dx * widget.maxAngle),
              child: child,
            ),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                widget.child,
                // Reflet qui suit le doigt.
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _light == null ? 0 : 1,
                      duration: AppMotion.medium,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(widget.radius),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(
                                ((_light?.dx ?? 0.5) * 2 - 1),
                                ((_light?.dy ?? 0.5) * 2 - 1),
                              ),
                              radius: 0.9,
                              colors: [
                                Colors.white.withValues(alpha: 0.22),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

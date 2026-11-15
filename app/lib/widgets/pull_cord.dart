import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'decor_clock.dart';

/// Interrupteur « veilleuse » : un fil qui descend du haut de l'écran,
/// terminé par une petite poignée. On le tire vers le bas pour passer du
/// mode jour au mode nuit ; il remonte avec un ressort, se balance, et une
/// vague de lumière (ou d'ombre) traverse l'écran.
///
/// Un simple toucher sur la poignée fait la même chose (lecteurs d'écran,
/// tests).
class PullCord extends StatefulWidget {
  const PullCord({
    super.key,
    required this.dark,
    required this.onToggle,
    required this.label,
    this.reach = 90,
  });

  /// Mode actuel : la poignée brille en mode jour, s'éteint la nuit.
  final bool dark;
  final VoidCallback onToggle;

  /// Nom lu par les lecteurs d'écran.
  final String label;

  /// Longueur du fil au-dessus du widget (jusqu'au bord de l'écran).
  final double reach;

  static const width = 44.0;
  static const height = 52.0;

  @override
  State<PullCord> createState() => _PullCordState();
}

class _PullCordState extends State<PullCord> with TickerProviderStateMixin {
  /// Longueur tirée, en pixels.
  late final AnimationController _pull = AnimationController.unbounded(
    vsync: this,
  );

  /// Balancement après le relâchement (0 → 1, amorti).
  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  double _swingAmplitude = 0;

  /// Petit balancement au repos, pour inviter à tirer.
  final Animation<double> _idle = DecorLoop(5);

  static const _threshold = 34.0;
  static const _maxPull = 90.0;
  static const _knob = 15.0;
  bool _armed = false;

  /// Vagues en cours, retirées si le fil disparaît avant la fin.
  final _bursts = <(AnimationController, OverlayEntry)>[];

  @override
  void dispose() {
    for (final (controller, entry) in _bursts) {
      entry.remove();
      controller.dispose();
    }
    _pull.dispose();
    _swing.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _pull.stop();
    // Plus on tire, plus le fil résiste.
    final next = (_pull.value + d.delta.dy * (1 - _pull.value / 140)).clamp(
      0.0,
      _maxPull,
    );
    _pull.value = next;
    final armed = next > _threshold;
    if (armed != _armed) {
      _armed = armed;
      if (armed) HapticFeedback.selectionClick();
      setState(() {});
    }
  }

  void _onDragEnd(DragEndDetails d) {
    final pulled = _pull.value;
    if (pulled > _threshold) _fire();
    _release(pulled);
  }

  void _tap() {
    _fire();
    _release(_threshold + 10);
  }

  void _release(double from) {
    _armed = false;
    _pull.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 420, damping: 11),
        from,
        0,
        0,
      ),
    );
    _swingAmplitude = (from / _maxPull) * 0.35;
    _swing.forward(from: 0);
    setState(() {});
  }

  void _fire() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    _burst();
    widget.onToggle();
  }

  /// Vague de lumière (passage au jour) ou d'ombre (passage à la nuit) qui
  /// part de la poignée et couvre tout l'écran.
  void _burst() {
    final overlay = Overlay.maybeOf(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null || !box.hasSize) return;
    final origin = box.localToGlobal(
      Offset(PullCord.width / 2, _restKnobY + _pull.value),
    );
    final toDay = widget.dark;
    late final OverlayEntry entry;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    entry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _BurstPainter(
              origin: origin,
              t: Curves.easeOutCubic.transform(controller.value),
              color: toDay ? const Color(0xFFFFE9A8) : const Color(0xFF0B0E1A),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    final burst = (controller, entry);
    _bursts.add(burst);
    controller.forward().whenComplete(() {
      if (!_bursts.remove(burst)) return;
      entry.remove();
      controller.dispose();
    });
  }

  static const _restKnobY = PullCord.height - _knob - 3;

  @override
  Widget build(BuildContext context) {
    final glow = !widget.dark;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      onTap: _tap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: SizedBox(
          width: PullCord.width,
          height: PullCord.height,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pull, _swing, _idle]),
            builder: (context, _) {
              final t = _swing.value;
              final sway = _swing.isAnimating
                  ? _swingAmplitude * math.exp(-3.2 * t) * math.sin(t * 22)
                  : 0.0;
              final idle = 0.035 * math.sin(_idle.value * 2 * math.pi);
              final angle = sway + idle;
              final length = widget.reach + _restKnobY + _pull.value;
              final anchor = Offset(PullCord.width / 2, -widget.reach);
              final knob =
                  anchor +
                  Offset(math.sin(angle) * length, math.cos(angle) * length);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CordPainter(
                        anchor: anchor,
                        knob: knob,
                        color: context.palette.textMuted,
                      ),
                    ),
                  ),
                  Positioned(
                    left: knob.dx - _knob,
                    top: knob.dy - _knob,
                    child: AnimatedContainer(
                      duration: AppMotion.medium,
                      curve: AppMotion.spring,
                      width: _knob * 2,
                      height: _knob * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: glow
                              ? const [Brand.goldSoft, Brand.gold]
                              : const [Color(0xFF3A3F55), Color(0xFF1A1D2B)],
                        ),
                        border: Border.all(
                          color: glow
                              ? const Color(0xFFFFF4C2)
                              : const Color(0x33FFFFFF),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: glow
                                ? Brand.gold.withValues(
                                    alpha: _armed ? 0.95 : 0.6,
                                  )
                                : const Color(0x557A8CFF),
                            blurRadius: _armed ? 26 : 16,
                            spreadRadius: _armed ? 3 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.dark ? AppIcons.moon : AppIcons.sun,
                        size: 16,
                        color: glow ? Brand.ink : const Color(0xFFC9D2FF),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CordPainter extends CustomPainter {
  _CordPainter({required this.anchor, required this.knob, required this.color});

  final Offset anchor;
  final Offset knob;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Fil légèrement courbé : il suit le balancement avec un peu de retard.
    final mid = Offset((anchor.dx + knob.dx) / 2, (anchor.dy + knob.dy) / 2);
    final control = Offset(mid.dx + (knob.dx - anchor.dx) * -0.35, mid.dy);
    final path = Path()
      ..moveTo(anchor.dx, anchor.dy)
      ..quadraticBezierTo(control.dx, control.dy, knob.dx, knob.dy - 14);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.9),
    );
    // Petite bague dorée au bout du fil.
    canvas.drawCircle(
      Offset(knob.dx, knob.dy - 15),
      2.4,
      Paint()..color = Brand.gold,
    );
  }

  @override
  bool shouldRepaint(_CordPainter old) =>
      old.anchor != anchor || old.knob != knob || old.color != color;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.origin, required this.t, required this.color});

  final Offset origin;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final far = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((c) => (c - origin).distance).reduce(math.max);
    final radius = far * t;
    final opacity = (1 - t) * 0.55;
    canvas.drawCircle(
      origin,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.6),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.7, 1],
        ).createShader(Rect.fromCircle(center: origin, radius: radius + 1)),
    );
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

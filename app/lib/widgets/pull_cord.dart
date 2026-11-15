import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'decor_clock.dart';

/// Interrupteur « veilleuse » : la veilleuse reste dans la barre du haut
/// (allumée en mode jour, croissant de lune en mode nuit) et un fil pend en
/// dessous. On tire le fil : clic, la veilleuse s'éteint ou se rallume, une
/// vague de lumière ou d'ombre traverse l'écran, puis le fil remonte et se
/// balance.
///
/// Un toucher sur la veilleuse fait la même chose (lecteurs d'écran, tests).
class PullCord extends StatefulWidget {
  const PullCord({
    super.key,
    required this.dark,
    required this.onToggle,
    required this.label,
    this.length = 46,
  });

  /// Mode actuel : veilleuse allumée le jour, croissant de lune la nuit.
  final bool dark;
  final VoidCallback onToggle;

  /// Nom lu par les lecteurs d'écran.
  final String label;

  /// Longueur du fil au repos, sous la veilleuse.
  final double length;

  static const size = 48.0;

  /// Zone du fil qu'on attrape (pour les tests).
  static const handleKey = ValueKey('pull-cord-handle');

  @override
  State<PullCord> createState() => _PullCordState();
}

class _PullCordState extends State<PullCord> with TickerProviderStateMixin {
  final _link = LayerLink();
  final _portal = OverlayPortalController();

  /// Longueur tirée, en pixels.
  late final AnimationController _pull = AnimationController.unbounded(
    vsync: this,
  );

  /// Balancement après le relâchement (0 → 1, amorti).
  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  double _swingAmplitude = 0;

  /// 1 = veilleuse allumée (jour), 0 = croissant (nuit).
  late final AnimationController _lit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
    value: widget.dark ? 0 : 1,
  );

  final Animation<double> _idle = DecorLoop(6);

  static const _threshold = 38.0;
  static const _maxPull = 70.0;
  static const _bead = 9.0;
  bool _clicked = false;

  final _bursts = <(AnimationController, OverlayEntry)>[];

  @override
  void initState() {
    super.initState();
    _portal.show();
  }

  @override
  void didUpdateWidget(PullCord old) {
    super.didUpdateWidget(old);
    if (old.dark != widget.dark) {
      _lit.animateTo(widget.dark ? 0 : 1, curve: Curves.easeInOutCubic);
    }
  }

  @override
  void dispose() {
    for (final (controller, entry) in _bursts) {
      entry.remove();
      controller.dispose();
    }
    _pull.dispose();
    _swing.dispose();
    _lit.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails d) {
    _clicked = false;
    _pull.stop();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    // Plus on tire, plus le fil résiste, comme un vrai ressort.
    final next = (_pull.value + d.delta.dy * (1 - _pull.value / 110)).clamp(
      0.0,
      _maxPull,
    );
    _pull.value = next;
    // Le clic arrive au bout de la course, pas au relâchement.
    if (!_clicked && next > _threshold) {
      _clicked = true;
      _fire();
      setState(() {});
    }
  }

  void _onDragEnd(DragEndDetails d) {
    _clicked = false;
    _release(_pull.value);
  }

  Future<void> _tug() async {
    await _pull.animateTo(
      _threshold + 6,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
    );
    if (!mounted) return;
    _fire();
    _release(_pull.value);
  }

  void _release(double from) {
    _pull.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 520, damping: 9),
        from,
        0,
        0,
      ),
    );
    _swingAmplitude = (from / _maxPull) * 0.32;
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
  /// part de la veilleuse et couvre tout l'écran.
  void _burst() {
    final overlay = Overlay.maybeOf(context);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null || !box.hasSize) return;
    final origin = box.localToGlobal(_lampCenter);
    final toDay = widget.dark;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    final entry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _BurstPainter(
              origin: origin,
              t: Curves.easeOutCubic.transform(controller.value),
              color: toDay ? const Color(0xFFFFE6A0) : const Color(0xFF070A18),
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

  static const _lampCenter = Offset(PullCord.size / 2, 21);

  /// Point où le fil sort de la veilleuse, sous la petite douille.
  static const _socketBottom = 42.0;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _cord,
        child: Semantics(
          button: true,
          label: widget.label,
          excludeSemantics: true,
          onTap: _tug,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tug,
            child: SizedBox.square(
              dimension: PullCord.size,
              child: CustomPaint(
                painter: _LampPainter(lit: _lit, center: _lampCenter),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Le fil est dessiné dans la couche du dessus : il dépasse de la barre
  /// et reste attrapable même en dehors d'elle.
  Widget _cord(BuildContext context) {
    final dark = context.isDark;
    final height = widget.length + _maxPull + _bead * 3;
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        offset: const Offset(0, _socketBottom),
        child: SizedBox(
          width: PullCord.size,
          height: height,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pull, _swing, _idle]),
            builder: (context, _) {
              final t = _swing.value;
              final sway = _swing.isAnimating
                  ? _swingAmplitude * math.exp(-3 * t) * math.sin(t * 20)
                  : 0.0;
              final idle = 0.04 * math.sin(_idle.value * 2 * math.pi);
              final angle = sway + idle;
              final length = widget.length + _pull.value;
              const anchor = Offset(PullCord.size / 2, 0);
              final bead =
                  anchor +
                  Offset(math.sin(angle) * length, math.cos(angle) * length);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _CordPainter(
                          anchor: anchor,
                          bead: bead,
                          dark: dark,
                          tense: _pull.value / _maxPull,
                        ),
                      ),
                    ),
                  ),
                  // Zone attrapable : le fil et sa perle, pas plus large.
                  Positioned(
                    left: bead.dx - 18,
                    top: 6,
                    width: 36,
                    height: bead.dy + _bead * 2,
                    child: GestureDetector(
                      key: PullCord.handleKey,
                      behavior: HitTestBehavior.opaque,
                      onTap: _tug,
                      onVerticalDragStart: _onDragStart,
                      onVerticalDragUpdate: _onDragUpdate,
                      onVerticalDragEnd: _onDragEnd,
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

/// La veilleuse : un disque qui brille le jour et devient un croissant de
/// lune la nuit (une ombre glisse dessus, comme une éclipse).
class _LampPainter extends CustomPainter {
  _LampPainter({required this.lit, required this.center}) : super(repaint: lit);

  final Animation<double> lit;
  final Offset center;

  static const _r = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final on = lit.value;
    final off = 1 - on;
    final c = center;

    // Halo : chaud quand elle est allumée, bleu nuit quand elle dort.
    canvas.drawCircle(
      c,
      _r + 12,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(const Color(0x557A8CFF), const Color(0xCCFFC94D), on)!,
            const Color(0x00FFC94D),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: _r + 12)),
    );

    // Rayons de lumière quand elle est allumée.
    if (on > 0.01) {
      final ray = Paint()
        ..color = Brand.gold.withValues(alpha: 0.85 * on)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + math.pi / 8;
        final dir = Offset(math.cos(a), math.sin(a));
        if (dir.dy > 0.8) continue; // laisse la place à la douille
        canvas.drawLine(
          c + dir * (_r + 3.5),
          c + dir * (_r + 3.5 + 3.5 * on),
          ray,
        );
      }
    }

    // Petites étoiles la nuit.
    if (off > 0.01) {
      final star = Paint()..color = Colors.white.withValues(alpha: 0.9 * off);
      for (final (p, s) in [
        (c + const Offset(-17, -12), 1.6),
        (c + const Offset(16, -15), 1.2),
        (c + const Offset(19, 6), 1.0),
      ]) {
        canvas.drawCircle(p, s * off, star);
      }
    }

    // Douille dorée d'où sort le fil.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c + const Offset(0, _r + 3.5),
          width: 9,
          height: 6,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = Color.lerp(const Color(0xFF6B7398), Brand.gold, on)!,
    );

    // Le disque, puis l'ombre qui le grignote en croissant.
    final disc = Rect.fromCircle(center: c, radius: _r);
    canvas.saveLayer(disc.inflate(2), Paint());
    canvas.drawCircle(
      c,
      _r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: [
            Color.lerp(const Color(0xFFF4F6FF), const Color(0xFFFFFBEA), on)!,
            Color.lerp(const Color(0xFFAEB8E8), const Color(0xFFF5B83D), on)!,
          ],
        ).createShader(disc),
    );
    final shadow =
        c +
        Offset(
          lerpDouble(_r * 2.3, _r * 0.55, off)!,
          lerpDouble(0, -_r * 0.38, off)!,
        );
    canvas.drawCircle(shadow, _r * 0.9, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LampPainter old) => old.center != center;
}

class _CordPainter extends CustomPainter {
  _CordPainter({
    required this.anchor,
    required this.bead,
    required this.dark,
    required this.tense,
  });

  final Offset anchor;
  final Offset bead;
  final bool dark;

  /// 0 au repos, 1 tiré à fond : la chaîne se tend et la goutte brille.
  final double tense;

  static const _beadR = _PullCordState._bead;

  @override
  void paint(Canvas canvas, Size size) {
    // Chaîne un peu courbée : elle suit le balancement avec du retard.
    final mid = Offset((anchor.dx + bead.dx) / 2, (anchor.dy + bead.dy) / 2);
    final bend = (bead.dx - anchor.dx) * -0.35 * (1 - tense);
    final end = bead - const Offset(0, _beadR + 3);
    final path = Path()
      ..moveTo(anchor.dx, anchor.dy)
      ..quadraticBezierTo(mid.dx + bend, mid.dy, end.dx, end.dy);

    // Fine chaîne à billes en laiton, comme sur les belles lampes.
    // Le jour, un liseré sombre la détache du fond clair.
    final rim = dark ? const Color(0x99000000) : const Color(0xFF5A3A08);
    const light = Color(0xFFFFE9A8);
    final deep = dark ? const Color(0xFFE0A526) : const Color(0xFFB07A12);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = rim.withValues(alpha: 0.6),
    );
    for (final metric in path.computeMetrics()) {
      for (var d = 3.0; d < metric.length; d += 4.6) {
        final p = metric.getTangentForOffset(d)?.position;
        if (p == null) continue;
        canvas.drawCircle(p, 2.1, Paint()..color = rim);
        canvas.drawCircle(
          p,
          1.6,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.4, -0.5),
              colors: [light, deep],
            ).createShader(Rect.fromCircle(center: p, radius: 1.6)),
        );
      }
    }

    // Petite goutte en laiton au bout : une bague, puis la goutte.
    if (tense > 0.3) {
      canvas.drawCircle(
        bead,
        12,
        Paint()
          ..color = Brand.gold.withValues(alpha: 0.45 * tense)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    final collar = Rect.fromCenter(
      center: end + const Offset(0, 2),
      width: 4.5,
      height: 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(collar.inflate(0.8), const Radius.circular(1.5)),
      Paint()..color = rim,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(collar, const Radius.circular(1.2)),
      Paint()..color = deep,
    );
    final top = end + const Offset(0, 4);
    final round = top + const Offset(0, 9);
    const w = 4.2;
    final drop = Path()
      ..moveTo(top.dx, top.dy)
      ..cubicTo(
        top.dx + 1,
        top.dy + 3,
        round.dx + w,
        round.dy - 4,
        round.dx + w,
        round.dy,
      )
      ..arcToPoint(
        Offset(round.dx - w, round.dy),
        radius: const Radius.circular(w),
      )
      ..cubicTo(
        round.dx - w,
        round.dy - 4,
        top.dx - 1,
        top.dy + 3,
        top.dx,
        top.dy,
      )
      ..close();
    canvas.drawPath(
      drop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = rim,
    );
    canvas.drawPath(
      drop,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, Brand.gold, deep],
          stops: const [0, 0.45, 1],
        ).createShader(drop.getBounds()),
    );
    // Reflet.
    canvas.drawLine(
      round + const Offset(-1.8, -4),
      round + const Offset(-1.8, -0.5),
      Paint()
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(_CordPainter old) =>
      old.anchor != anchor ||
      old.bead != bead ||
      old.dark != dark ||
      old.tense != tense;
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
    final opacity = (1 - t) * 0.6;
    canvas.drawCircle(
      origin,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.7),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.75, 1],
        ).createShader(Rect.fromCircle(center: origin, radius: radius + 1)),
    );
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

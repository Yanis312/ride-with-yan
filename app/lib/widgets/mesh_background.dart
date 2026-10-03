import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_theme.dart';

/// Ambiances de fond. Chaque phase de l'écran de veille a la sienne.
enum Scene {
  lounge,
  intro,
  cinema,
  games,
  poll,
  news,
  collab,
  finale,
  store,
  profile,
  ads,
}

@immutable
class MeshPalette {
  const MeshPalette(
    this.base,
    this.c1,
    this.c2,
    this.c3,
    this.c4, {
    this.intensity = 0.85,
  });

  final Color base;
  final Color c1;
  final Color c2;
  final Color c3;
  final Color c4;
  final double intensity;

  @override
  bool operator ==(Object other) =>
      other is MeshPalette &&
      other.base == base &&
      other.c1 == c1 &&
      other.c2 == c2 &&
      other.c3 == c3 &&
      other.c4 == c4 &&
      other.intensity == intensity;

  @override
  int get hashCode => Object.hash(base, c1, c2, c3, c4, intensity);

  static MeshPalette lerp(MeshPalette a, MeshPalette b, double t) =>
      MeshPalette(
        Color.lerp(a.base, b.base, t)!,
        Color.lerp(a.c1, b.c1, t)!,
        Color.lerp(a.c2, b.c2, t)!,
        Color.lerp(a.c3, b.c3, t)!,
        Color.lerp(a.c4, b.c4, t)!,
        intensity: ui.lerpDouble(a.intensity, b.intensity, t)!,
      );

  static MeshPalette of(Scene scene, Brightness brightness) =>
      (brightness == Brightness.dark ? _dark : _light)[scene]!;

  static const _dark = {
    Scene.lounge: MeshPalette(
      Color(0xFF07080B),
      Color(0xFF8A6200),
      Color(0xFF13274A),
      Color(0xFF2B1A00),
      Color(0xFF0E1B36),
      intensity: 0.7,
    ),
    Scene.intro: MeshPalette(
      Color(0xFF07080B),
      Color(0xFFB98500),
      Color(0xFF16305C),
      Color(0xFF4A2A00),
      Color(0xFF0F1D3D),
    ),
    Scene.cinema: MeshPalette(
      Color(0xFF0A0405),
      Color(0xFFA3122A),
      Color(0xFFD06A0C),
      Color(0xFF4A0819),
      Color(0xFF221040),
    ),
    Scene.games: MeshPalette(
      Color(0xFF06061A),
      Color(0xFF6C2BD9),
      Color(0xFF00B3D6),
      Color(0xFFD62E8B),
      Color(0xFF1B1F6B),
    ),
    Scene.poll: MeshPalette(
      Color(0xFF0B0804),
      Color(0xFFF5B700),
      Color(0xFFE5533D),
      Color(0xFF8A4300),
      Color(0xFF2E1C05),
    ),
    Scene.news: MeshPalette(
      Color(0xFF040914),
      Color(0xFF1E5BFF),
      Color(0xFF3AA6FF),
      Color(0xFF0B2A6E),
      Color(0xFF6A4CFF),
    ),
    Scene.collab: MeshPalette(
      Color(0xFF031010),
      Color(0xFF0FA37F),
      Color(0xFF18C2C9),
      Color(0xFF0E5E4F),
      Color(0xFFB98500),
    ),
    Scene.finale: MeshPalette(
      Color(0xFF080705),
      Color(0xFFF5B700),
      Color(0xFFE07A1F),
      Color(0xFF16305C),
      Color(0xFF5A3A00),
      intensity: 0.95,
    ),
    Scene.store: MeshPalette(
      Color(0xFF0B0607),
      Color(0xFFE5533D),
      Color(0xFFF5B700),
      Color(0xFF7A1F3D),
      Color(0xFF2A1240),
    ),
    Scene.profile: MeshPalette(
      Color(0xFF050B14),
      Color(0xFF0A66C2),
      Color(0xFF3A8DFF),
      Color(0xFF0E2A52),
      Color(0xFF8A6200),
    ),
    Scene.ads: MeshPalette(
      Color(0xFF0B0510),
      Color(0xFFE1306C),
      Color(0xFFF77737),
      Color(0xFF833AB4),
      Color(0xFFFCAF45),
    ),
  };

  /// Palettes claires dédiées : pastels lumineux sur blanc froid (éclaircir
  /// les palettes sombres donnait des gris boueux).
  static const _light = {
    Scene.lounge: MeshPalette(
      Color(0xFFF3F5F8),
      Color(0xFFFFE3A0),
      Color(0xFFC9DBFF),
      Color(0xFFFFD6C2),
      Color(0xFFE3D9FF),
      intensity: 0.8,
    ),
    Scene.intro: MeshPalette(
      Color(0xFFF4F5F8),
      Color(0xFFFFD978),
      Color(0xFFBFD3FF),
      Color(0xFFFFE9B8),
      Color(0xFFD5E2FF),
    ),
    Scene.cinema: MeshPalette(
      Color(0xFFFBF3F3),
      Color(0xFFFFB3A8),
      Color(0xFFFFCB8A),
      Color(0xFFF58FA6),
      Color(0xFFD9C2FF),
    ),
    Scene.games: MeshPalette(
      Color(0xFFF5F3FF),
      Color(0xFFC8B2FF),
      Color(0xFF9EEBFA),
      Color(0xFFFFB3DA),
      Color(0xFFB9C3FF),
    ),
    Scene.poll: MeshPalette(
      Color(0xFFFFF8EC),
      Color(0xFFFFD45E),
      Color(0xFFFFB09E),
      Color(0xFFFFE2A8),
      Color(0xFFFFD0B5),
    ),
    Scene.news: MeshPalette(
      Color(0xFFF2F6FF),
      Color(0xFFA9C4FF),
      Color(0xFFA8DAFF),
      Color(0xFFC7D6FF),
      Color(0xFFC9BEFF),
    ),
    Scene.collab: MeshPalette(
      Color(0xFFF0FAF7),
      Color(0xFF98E6CF),
      Color(0xFF9FE7EA),
      Color(0xFFC8F0D9),
      Color(0xFFFFE29A),
    ),
    Scene.finale: MeshPalette(
      Color(0xFFFFF9EE),
      Color(0xFFFFD45E),
      Color(0xFFFFC18A),
      Color(0xFFC9D8FF),
      Color(0xFFFFE6A8),
      intensity: 0.95,
    ),
    Scene.store: MeshPalette(
      Color(0xFFFFF5F2),
      Color(0xFFFFB3A3),
      Color(0xFFFFD978),
      Color(0xFFF7B8CF),
      Color(0xFFD9C8FF),
    ),
    Scene.profile: MeshPalette(
      Color(0xFFF2F6FC),
      Color(0xFFA6C8F0),
      Color(0xFFBFD8FF),
      Color(0xFFD6E4F7),
      Color(0xFFFFE29A),
    ),
    Scene.ads: MeshPalette(
      Color(0xFFFFF4F8),
      Color(0xFFFFB3CC),
      Color(0xFFFFCFA8),
      Color(0xFFD9B8F2),
      Color(0xFFFFE2A0),
    ),
  };
}

/// Fond "lampe à lave" animé par un shader (shaders/mesh.frag).
/// Les couleurs glissent en douceur quand [scene] change. Si le shader ne
/// peut pas être chargé, un dégradé équivalent est dessiné à la place.
class MeshBackground extends StatefulWidget {
  const MeshBackground({super.key, required this.scene, required this.child});

  final Scene scene;
  final Widget child;

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground>
    with TickerProviderStateMixin {
  static Future<ui.FragmentProgram?>? _program;

  late final Ticker _ticker = createTicker(_onTick);
  final _time = ValueNotifier<double>(0);
  ui.FragmentShader? _shader;

  late final AnimationController _blend = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
    value: 1,
  );
  MeshPalette? _from;
  MeshPalette? _to;

  @override
  void initState() {
    super.initState();
    _program ??= ui.FragmentProgram.fromAsset('shaders/mesh.frag')
        .then<ui.FragmentProgram?>(
          (p) => p,
          onError: (Object e) {
            debugPrint('Shader indisponible, dégradé de secours : $e');
            return null;
          },
        );
    _program!.then((program) {
      if (mounted && program != null) {
        setState(() => _shader = program.fragmentShader());
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final target = MeshPalette.of(widget.scene, Theme.of(context).brightness);
    _retarget(target);
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce && _ticker.isActive) _ticker.stop();
    if (!reduce && !_ticker.isActive) _ticker.start();
  }

  @override
  void didUpdateWidget(MeshBackground old) {
    super.didUpdateWidget(old);
    if (old.scene != widget.scene) {
      _retarget(MeshPalette.of(widget.scene, Theme.of(context).brightness));
    }
  }

  void _retarget(MeshPalette target) {
    if (_to == target) return;
    _from = _to == null ? target : _current;
    _to = target;
    _blend.forward(from: 0);
  }

  MeshPalette get _current =>
      MeshPalette.lerp(_from!, _to!, AppMotion.spring.transform(_blend.value));

  /// Point de départ aléatoire : chaque passager voit d'autres vagues.
  final double _seed = math.Random().nextDouble() * 400;

  // Toucher : ondes de lumière (position, instant de naissance) et doigt posé.
  static const _maxRipples = 4;
  static const _rippleLife = 2.4;
  final _touch = _TouchState();
  double _now = 0;

  void _onTick(Duration elapsed) {
    _now = elapsed.inMicroseconds / 1e6;
    _touch.update(_now, _rippleLife);
    _time.value = _seed + _now;
  }

  void _onDown(PointerDownEvent e) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _touch.ripples.add((e.localPosition, _now));
    if (_touch.ripples.length > _maxRipples) _touch.ripples.removeAt(0);
    _touch.finger = e.localPosition;
    _touch.pressed = true;
  }

  void _onMove(PointerMoveEvent e) => _touch.finger = e.localPosition;

  void _onUp(PointerEvent e) => _touch.pressed = false;

  @override
  void dispose() {
    _ticker.dispose();
    _blend.dispose();
    _time.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le fond sert de source de réfraction aux éléments Liquid Glass.
    // Listener ne participe pas à l'arène des gestes : les boutons restent
    // pleinement utilisables pendant que le fond réagit au doigt.
    final glow = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFD66B)
        : const Color(0xFFFFB000);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: LiquidGlassScope(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GlassBackgroundSource(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _MeshPainter(
                    shader: _shader,
                    time: _time,
                    blend: _blend,
                    palette: () => _current,
                    touch: _touch,
                    now: () => _now,
                    glow: glow,
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({
    required this.shader,
    required this.time,
    required this.blend,
    required this.palette,
    required this.touch,
    required this.now,
    required this.glow,
  }) : super(repaint: Listenable.merge([time, blend]));

  final ui.FragmentShader? shader;
  final ValueListenable<double> time;
  final Animation<double> blend;
  final MeshPalette Function() palette;
  final _TouchState touch;
  final double Function() now;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette();
    final s = shader;
    if (s == null) {
      _fallback(canvas, size, p);
      return;
    }
    var i = 0;
    void setColor(Color c) {
      s
        ..setFloat(i++, c.r)
        ..setFloat(i++, c.g)
        ..setFloat(i++, c.b);
    }

    s
      ..setFloat(i++, size.width)
      ..setFloat(i++, size.height)
      ..setFloat(i++, time.value * 0.55);
    setColor(p.base);
    setColor(p.c1);
    setColor(p.c2);
    setColor(p.c3);
    setColor(p.c4);
    s
      ..setFloat(i++, p.intensity)
      ..setFloat(i++, 0.025);
    final t = now();
    for (var r = 0; r < 4; r++) {
      final ripple = r < touch.ripples.length ? touch.ripples[r] : null;
      s
        ..setFloat(i++, ripple?.$1.dx ?? 0)
        ..setFloat(i++, ripple?.$1.dy ?? 0)
        ..setFloat(i++, ripple == null ? 0 : t - ripple.$2)
        ..setFloat(i++, ripple == null ? 0 : 1);
    }
    s
      ..setFloat(i++, touch.finger.dx)
      ..setFloat(i++, touch.finger.dy)
      ..setFloat(i++, touch.level);
    setColor(glow);
    canvas.drawRect(Offset.zero & size, Paint()..shader = s);
  }

  void _fallback(Canvas canvas, Size size, MeshPalette p) {
    canvas.drawRect(Offset.zero & size, Paint()..color = p.base);
    final t0 = now();
    for (final (pos, born) in touch.ripples) {
      final age = t0 - born;
      canvas.drawCircle(
        pos,
        age * 560,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 30
          ..color = glow.withValues(
            alpha: (0.5 * math.exp(-age * 1.5)).clamp(0, 1),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }
    final t = time.value * 0.3;
    final r = size.longestSide * 0.6;
    final spots = [
      (
        Offset(size.width * (0.2 + 0.1 * math.sin(t)), size.height * 0.25),
        p.c1,
      ),
      (
        Offset(size.width * (0.82 + 0.08 * math.cos(t)), size.height * 0.2),
        p.c2,
      ),
      (
        Offset(size.width * 0.7, size.height * (0.85 + 0.06 * math.sin(t))),
        p.c3,
      ),
      (Offset(size.width * 0.18, size.height * 0.85), p.c4),
    ];
    for (final (center, color) in spots) {
      final c = color.withValues(alpha: p.intensity * 0.8);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(colors: [c, c.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.shader != shader;
}

/// État du toucher partagé entre le widget et le peintre.
class _TouchState {
  final ripples = <(Offset, double)>[];
  Offset finger = Offset.zero;
  bool pressed = false;

  /// Intensité du halo sous le doigt, lissée pour apparaître et s'éteindre en douceur.
  double level = 0;

  void update(double now, double life) {
    ripples.removeWhere((r) => now - r.$2 > life);
    level += ((pressed ? 1.0 : 0.0) - level) * 0.12;
  }
}

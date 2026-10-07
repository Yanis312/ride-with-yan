import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Horloge commune de toutes les animations décoratives (fond animé, halos,
/// bordures lumineuses, illustrations).
///
/// Pourquoi ne pas utiliser un `AnimationController` par animation : tant
/// qu'un contrôleur tourne, Flutter redessine TOUT l'écran à chaque image de
/// l'écran (60 par seconde), même si rien d'autre ne bouge. Ici, un seul
/// minuteur réveille tout le monde 30 fois par seconde : deux fois moins de
/// travail, et un rythme identique pour toutes les animations.
class DecorClock extends ChangeNotifier {
  DecorClock._();

  static final instance = DecorClock._();

  /// Intervalle entre deux images décoratives (30 par seconde).
  static const frame = Duration(milliseconds: 33);

  final _watch = Stopwatch();
  Timer? _timer;
  bool _enabled = true;

  /// Temps écoulé, en secondes, pendant que l'horloge tourne.
  double get seconds => _watch.elapsedMicroseconds / 1e6;

  /// Mouvement réduit demandé par l'appareil : l'horloge s'arrête.
  static set enabled(bool value) {
    if (instance._enabled == value) return;
    instance._enabled = value;
    instance._sync();
  }

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _sync();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _sync();
  }

  /// L'horloge ne tourne que si quelqu'un l'écoute.
  void _sync() {
    final run = hasListeners && _enabled;
    if (run && _timer == null) {
      _watch.start();
      _timer = Timer.periodic(frame, (_) => notifyListeners());
    } else if (!run && _timer != null) {
      _timer!.cancel();
      _timer = null;
      _watch.stop();
    }
  }
}

/// Valeur recalculée à chaque image de [DecorClock], utilisable partout où
/// Flutter attend une `Animation<double>` (AnimatedBuilder, CustomPainter…).
class DecorValue extends Animation<double>
    with
        AnimationLazyListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin {
  DecorValue(this._read);

  final double Function(double seconds) _read;

  @override
  double get value => _read(DecorClock.instance.seconds);

  @override
  AnimationStatus get status => AnimationStatus.forward;

  @override
  void didStartListening() => DecorClock.instance.addListener(notifyListeners);

  @override
  void didStopListening() =>
      DecorClock.instance.removeListener(notifyListeners);
}

/// Boucle de 0 à 1 qui recommence toutes les [period] secondes.
class DecorLoop extends DecorValue {
  DecorLoop(double period, {double phase = 0})
    : super((seconds) => (seconds / period + phase) % 1.0);
}

/// Fait "respirer" [child] : il grossit jusqu'à [scale] puis revient.
class DecorPulse extends StatelessWidget {
  const DecorPulse({
    super.key,
    required this.child,
    this.period = 4.8,
    this.scale = 1.08,
  });

  final Widget child;
  final double period;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final wave = DecorValue(
      (s) => 0.5 - 0.5 * math.cos(s / period * 2 * math.pi),
    );
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: wave,
        child: child,
        builder: (context, child) =>
            Transform.scale(scale: 1 + (scale - 1) * wave.value, child: child),
      ),
    );
  }
}

/// Fait tourner [child] en continu, un tour toutes les [period] secondes.
class DecorSpin extends StatelessWidget {
  const DecorSpin({super.key, required this.child, required this.period});

  final Widget child;
  final double period;

  @override
  Widget build(BuildContext context) {
    final turn = DecorLoop(period);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: turn,
        child: child,
        builder: (context, child) =>
            Transform.rotate(angle: turn.value * 2 * math.pi, child: child),
      ),
    );
  }
}

/// Reflet clair qui balaie [child] de gauche à droite, puis fait une pause.
class DecorShimmer extends StatelessWidget {
  const DecorShimmer({
    super.key,
    required this.child,
    this.period = 4.0,
    this.sweep = 1.4,
    this.radius = 999,
    this.opacity = 0.3,
  });

  final Widget child;

  /// Durée d'un cycle complet (pause comprise), en secondes.
  final double period;

  /// Durée du passage du reflet, en secondes.
  final double sweep;
  final double radius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _ShimmerPainter(
          DecorLoop(period),
          sweep / period,
          radius,
          opacity,
        ),
        child: child,
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter(this.loop, this.share, this.radius, this.opacity)
    : super(repaint: loop);

  final Animation<double> loop;

  /// Part du cycle pendant laquelle le reflet passe.
  final double share;
  final double radius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final t = loop.value;
    // Le reflet passe à la fin du cycle ; le reste du temps, rien à dessiner.
    if (t < 1 - share) return;
    final k = (t - (1 - share)) / share;
    final band = size.width * 0.35;
    final x = -band + (size.width + band * 2) * k;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(math.min(radius, size.height / 2)),
      ),
    );
    canvas.drawRect(
      Rect.fromLTWH(x - band / 2, 0, band, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0x00FFFFFF),
            Color.fromRGBO(255, 255, 255, opacity),
            const Color(0x00FFFFFF),
          ],
        ).createShader(Rect.fromLTWH(x - band / 2, 0, band, size.height)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      old.share != share || old.radius != radius || old.opacity != opacity;
}

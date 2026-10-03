import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Relaie une animation à 30 images/s au plus. Pour les animations purement
/// décoratives (dock, illustrations) : l'œil ne voit pas la différence, mais
/// le processeur reconstruit deux fois moins souvent.
class Throttled extends Animation<double>
    with
        AnimationLazyListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin {
  Throttled(this.parent, {this.interval = const Duration(milliseconds: 33)});

  final Animation<double> parent;
  final Duration interval;
  final Stopwatch _clock = Stopwatch()..start();
  Duration _last = Duration.zero;

  void _onParent() {
    final now = _clock.elapsed;
    if (now - _last < interval) return;
    _last = now;
    notifyListeners();
  }

  @override
  void didStartListening() {
    parent.addListener(_onParent);
    parent.addStatusListener(notifyStatusListeners);
  }

  @override
  void didStopListening() {
    parent.removeListener(_onParent);
    parent.removeStatusListener(notifyStatusListeners);
  }

  @override
  AnimationStatus get status => parent.status;

  @override
  double get value => parent.value;

  @override
  String toStringDetails() =>
      '${super.toStringDetails()} ${describeIdentity(parent)}';
}

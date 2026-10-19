import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'backend.dart';

/// Mesure anonyme de l'usage de la tablette : écrans ouverts, boutons
/// touchés, durée des visites. Aucun nom, aucun appareil : chaque passager
/// reçoit un numéro tiré au hasard, oublié à la fin de sa course.
///
/// Les évènements sont regroupés et envoyés toutes les 20 secondes, en une
/// seule requête. Sans réseau, ils attendent (200 au plus) et partent plus
/// tard ; une mesure perdue n'empêche jamais l'app de fonctionner.
class Usage {
  Usage._();

  static final instance = Usage._();

  static const flushEvery = Duration(seconds: 20);
  static const maxPending = 200;

  final _random = math.Random.secure();
  final List<Map<String, dynamic>> _pending = [];
  Timer? _timer;
  bool _sending = false;

  String? _session;
  String? _language;
  DateTime? _startedAt;

  /// Évènements en attente d'envoi (pour les tests).
  @visibleForTesting
  List<Map<String, dynamic>> get pending => List.unmodifiable(_pending);

  bool get _active => _session != null;

  /// Numéro de la course en cours (aussi utilisé par l'assistant pour ses
  /// plafonds de questions), ou `null` sur l'écran d'accueil.
  String? get sessionId => _session;

  void sessionStarted(String language) {
    if (_active) sessionEnded();
    _session = _uuid();
    _language = language;
    _startedAt = DateTime.now();
    _add('session_start', 'lounge');
  }

  void languageChanged(String language) => _language = language;

  void sessionEnded() {
    if (!_active) return;
    final seconds = DateTime.now().difference(_startedAt!).inSeconds;
    _add('session_end', 'end', value: seconds.clamp(0, 86400));
    _session = null;
    _startedAt = null;
    flush();
  }

  /// Écran ouvert (nom de la route : `store`, `news`…).
  void screen(String name) => _add('screen', name);

  /// Bouton touché (`store.add`, `ads.qr`…).
  void tap(String name) => _add('tap', name);

  void _add(String kind, String name, {int? value}) {
    final session = _session;
    if (session == null) return;
    final clean = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.:-]'), '_');
    if (clean.isEmpty) return;
    _pending.add({
      'session_id': session,
      'kind': kind,
      'name': clean.length > 60 ? clean.substring(0, 60) : clean,
      'language': _language,
      'value': value,
    });
    if (_pending.length > maxPending) {
      _pending.removeRange(0, _pending.length - maxPending);
    }
    _timer ??= Timer(flushEvery, flush);
  }

  /// Envoie ce qui attend. Appelé tout seul ; public pour les tests.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_pending.isEmpty || _sending || !Backend.enabled) return;
    _sending = true;
    final batch = List.of(_pending);
    try {
      await Backend.insertMany('usage_events', batch);
      _pending.removeRange(0, batch.length);
    } catch (_) {
      // Pas de réseau : on réessaiera au prochain envoi.
    } finally {
      _sending = false;
    }
  }

  /// Pour les tests.
  @visibleForTesting
  void reset() {
    _timer?.cancel();
    _timer = null;
    _pending.clear();
    _session = null;
    _startedAt = null;
  }

  String _uuid() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }
}

/// Note chaque écran ouvert, d'après le nom de sa route.
class UsageObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null && name != '/' && route is PageRoute) {
      Usage.instance.screen(name);
    }
  }
}

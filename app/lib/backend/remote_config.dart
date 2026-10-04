import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend.dart';

/// Réglages modifiés depuis le panneau d'administration : prix, stock et
/// visibilité des articles, question du jour imposée.
///
/// La tablette les recharge au début de chaque course. Sans réseau, elle
/// reprend la dernière version reçue ; sans rien, les valeurs de l'app.
class RemoteConfig extends ChangeNotifier {
  RemoteConfig._();

  static final instance = RemoteConfig._();
  static const _cacheKey = 'remote_config_v1';

  Map<String, Map<String, dynamic>> _products = {};
  Map<String, dynamic> _settings = {};
  bool _restored = false;

  /// Change à chaque mise à jour : sert à recalculer le catalogue.
  int revision = 0;

  Map<String, dynamic>? productOverride(String id) => _products[id];

  dynamic setting(String key) => _settings[key];

  void _apply(
    Map<String, Map<String, dynamic>> products,
    Map<String, dynamic> settings,
  ) {
    _products = products;
    _settings = settings;
    revision++;
    notifyListeners();
  }

  Future<void> _restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _apply({
        for (final e in (json['products'] as Map<String, dynamic>).entries)
          e.key: (e.value as Map).cast<String, dynamic>(),
      }, (json['settings'] as Map).cast<String, dynamic>());
    } catch (_) {
      // Pas de copie locale utilisable : on garde les valeurs de l'app.
    }
  }

  /// Recharge depuis la base. Ne lève jamais d'erreur : hors ligne, la
  /// tablette continue simplement avec ce qu'elle a déjà.
  Future<void> refresh() async {
    await _restore();
    if (!Backend.enabled) return;
    try {
      final rows = await Future.wait([
        Backend.select('product_overrides'),
        Backend.select('settings'),
      ]);
      final products = {for (final r in rows[0]) r['id'] as String: r};
      final settings = {
        for (final r in rows[1]) r['key'] as String: r['value'],
      };
      _apply(products, settings);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({'products': products, 'settings': settings}),
      );
    } catch (_) {
      // Voir le commentaire de la méthode.
    }
  }

  /// Pour les tests.
  @visibleForTesting
  void setForTest({
    Map<String, Map<String, dynamic>> products = const {},
    Map<String, dynamic> settings = const {},
  }) => _apply(products, settings);
}

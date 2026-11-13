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
  List<Map<String, dynamic>> _custom = [];

  /// Articles ajoutés depuis l'administration (table custom_products).
  List<Map<String, dynamic>> get customProducts => _custom;
  bool _restored = false;

  /// Change à chaque mise à jour : sert à recalculer le catalogue.
  int revision = 0;

  Map<String, dynamic>? productOverride(String id) => _products[id];

  dynamic setting(String key) => _settings[key];

  void _apply(
    Map<String, Map<String, dynamic>> products,
    Map<String, dynamic> settings, [
    List<Map<String, dynamic>> custom = const [],
  ]) {
    _products = products;
    _settings = settings;
    _custom = custom;
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
      _apply(
        {
          for (final e in (json['products'] as Map<String, dynamic>).entries)
            e.key: (e.value as Map).cast<String, dynamic>(),
        },
        (json['settings'] as Map).cast<String, dynamic>(),
        [
          for (final r in (json['custom'] as List? ?? []))
            (r as Map).cast<String, dynamic>(),
        ],
      );
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
        // Les articles ajoutés ne doivent jamais empêcher de recharger les
        // prix et réglages : en cas d'échec, on garde ceux déjà connus.
        Backend.select(
          'custom_products',
          order: 'created_at.desc',
        ).catchError((Object _) => _custom),
      ]);
      final products = {for (final r in rows[0]) r['id'] as String: r};
      final settings = {
        for (final r in rows[1]) r['key'] as String: r['value'],
      };
      _apply(products, settings, rows[2]);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'products': products,
          'settings': settings,
          'custom': rows[2],
        }),
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
    List<Map<String, dynamic>> custom = const [],
  }) => _apply(products, settings, custom);
}

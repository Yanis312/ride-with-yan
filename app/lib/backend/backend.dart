import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// Erreur renvoyée par la base, avec un message lisible.
class BackendException implements Exception {
  BackendException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Accès à la base en ligne (Supabase, plan gratuit) par son API REST.
/// La clé "publishable" est faite pour être publique : ce sont les règles
/// de la base (RLS) qui décident qui peut lire et écrire.
abstract final class Backend {
  static const _url = AppConfig.supabaseUrl;
  static const _key = AppConfig.supabaseKey;
  static const _timeout = Duration(seconds: 12);

  /// Mis à vrai par les tests pour ne jamais écrire dans la vraie base.
  @visibleForTesting
  static bool offline = false;

  static bool get enabled => !offline && _url.isNotEmpty && _key.isNotEmpty;

  static Map<String, String> _headers(String? token) => {
    'apikey': _key,
    'Authorization': 'Bearer ${token ?? _key}',
    'Content-Type': 'application/json',
  };

  static dynamic _read(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = body is Map
          ? (body['msg'] ??
                body['message'] ??
                body['error_description'] ??
                body['error'])
          : null;
      throw BackendException('${message ?? 'Erreur ${response.statusCode}'}');
    }
    return body;
  }

  /// Lit une table. [token] : pour les tables réservées à l'administration.
  /// [order] : tri au format PostgREST, ex. `created_at.desc`.
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String? token,
    String? order,
  }) async {
    final sort = order == null ? '' : '&order=$order';
    final response = await http
        .get(
          Uri.parse('$_url/rest/v1/$table?select=*$sort'),
          headers: _headers(token),
        )
        .timeout(_timeout);
    return (_read(response) as List).cast<Map<String, dynamic>>();
  }

  /// Ajoute une ligne sans la relire (la tablette n'a pas le droit de lire
  /// les commandes).
  static Future<void> insert(String table, Map<String, dynamic> row) async {
    if (!enabled) throw BackendException('Base indisponible');
    final response = await http
        .post(
          Uri.parse('$_url/rest/v1/$table'),
          headers: {..._headers(null), 'Prefer': 'return=minimal'},
          body: jsonEncode(row),
        )
        .timeout(_timeout);
    _read(response);
  }

  /// Modifie les lignes dont [column] vaut [value].
  static Future<void> update(
    String table,
    String column,
    String value,
    Map<String, dynamic> changes, {
    required String token,
  }) async {
    final response = await http
        .patch(
          Uri.parse(
            '$_url/rest/v1/$table?$column=eq.${Uri.encodeQueryComponent(value)}',
          ),
          headers: {..._headers(token), 'Prefer': 'return=minimal'},
          body: jsonEncode(changes),
        )
        .timeout(_timeout);
    _read(response);
  }

  /// Ajoute la ligne, ou la remplace si sa clé existe déjà.
  static Future<void> upsert(
    String table,
    Map<String, dynamic> row, {
    required String token,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_url/rest/v1/$table'),
          headers: {
            ..._headers(token),
            'Prefer': 'resolution=merge-duplicates,return=minimal',
          },
          body: jsonEncode(row),
        )
        .timeout(_timeout);
    _read(response);
  }

  /// Supprime les lignes dont [column] vaut [value].
  static Future<void> delete(
    String table,
    String column,
    String value, {
    required String token,
  }) async {
    final response = await http
        .delete(
          Uri.parse(
            '$_url/rest/v1/$table?$column=eq.${Uri.encodeQueryComponent(value)}',
          ),
          headers: _headers(token),
        )
        .timeout(_timeout);
    _read(response);
  }

  static Future<dynamic> rpc(
    String function,
    Map<String, dynamic> arguments, {
    String? token,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_url/rest/v1/rpc/$function'),
          headers: _headers(token),
          body: jsonEncode(arguments),
        )
        .timeout(_timeout);
    return _read(response);
  }

  static Future<Map<String, dynamic>> _auth(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_url/auth/v1/$path'),
          headers: {'apikey': _key, 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return (_read(response) as Map).cast<String, dynamic>();
  }
}

/// Connexion de Yanis au panneau d'administration. La session est gardée
/// sur l'appareil pour ne pas retaper le mot de passe à chaque fois.
class AdminSession extends ChangeNotifier {
  static const _refreshKey = 'admin_refresh_token';

  String? _accessToken;
  String? _refreshToken;
  DateTime _expiresAt = DateTime(0);
  String? email;

  bool get signedIn => _accessToken != null;

  void _store(Map<String, dynamic> json) {
    _accessToken = json['access_token'] as String?;
    _refreshToken = json['refresh_token'] as String?;
    _expiresAt = DateTime.now().add(
      Duration(seconds: (json['expires_in'] as num?)?.toInt() ?? 3600),
    );
    email = (json['user'] as Map?)?['email'] as String?;
  }

  Future<void> _remember() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = _refreshToken;
      if (token == null) {
        await prefs.remove(_refreshKey);
      } else {
        await prefs.setString(_refreshKey, token);
      }
    } catch (_) {
      // Stockage indisponible : il faudra se reconnecter la prochaine fois.
    }
  }

  /// Reprend la session gardée sur l'appareil, s'il y en a une.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_refreshKey);
      if (token == null) return;
      _refreshToken = token;
      await _refresh();
    } catch (_) {
      _accessToken = null;
    }
    notifyListeners();
  }

  Future<void> _refresh() async {
    _store(
      await Backend._auth('token?grant_type=refresh_token', {
        'refresh_token': _refreshToken,
      }),
    );
    await _remember();
  }

  /// Jeton valide pour écrire dans la base (renouvelé s'il expire bientôt).
  Future<String> token() async {
    if (_accessToken == null) throw BackendException('Non connecté');
    if (DateTime.now().isAfter(
      _expiresAt.subtract(const Duration(minutes: 1)),
    )) {
      await _refresh();
    }
    return _accessToken!;
  }

  Future<void> signIn(String email, String password) async {
    _store(
      await Backend._auth('token?grant_type=password', {
        'email': email,
        'password': password,
      }),
    );
    await _remember();
    notifyListeners();
  }

  /// Crée le compte ; Supabase envoie un courriel de confirmation.
  Future<void> signUp(String email, String password) =>
      Backend._auth('signup', {'email': email, 'password': password});

  /// Vrai seulement pour le compte de Yanis (vérifié par la base).
  Future<bool> isAdmin() async =>
      await Backend.rpc('is_admin', {}, token: await token()) == true;

  Future<void> signOut() async {
    _accessToken = null;
    _refreshToken = null;
    email = null;
    await _remember();
    notifyListeners();
  }
}

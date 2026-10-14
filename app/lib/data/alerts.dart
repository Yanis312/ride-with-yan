import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../backend/remote_config.dart';
import '../theme/app_icons.dart';
import 'bilingual.dart';
import 'weather.dart';

/// Gravité d'une alerte, de la simple information à l'avertissement.
enum AlertLevel { info, statement, advisory, watch, warning }

/// Message important affiché aux passagers : alerte météo officielle,
/// prévision hors du commun (grand froid, tempête) ou message de Yanis.
@immutable
class RegionAlert {
  const RegionAlert({
    required this.title,
    required this.body,
    required this.level,
    required this.icon,
    required this.source,
    this.key = '',
  });

  final Bi title;
  final Bi body;
  final AlertLevel level;
  final IconData icon;
  final Bi source;

  /// Identifie l'alerte pour éviter les doublons.
  final String key;
}

/// Zone surveillée : Ottawa, Gatineau et les environs.
const alertArea = (west: -76.35, south: 45.25, east: -75.35, north: 45.6);

const _environmentCanada = Bi('Environnement Canada', 'Environment Canada');
const _forecastSource = Bi('Prévisions Open-Meteo', 'Open-Meteo forecast');
const _driverSource = Bi('Votre chauffeur', 'Your driver');

abstract final class AlertService {
  static (DateTime, List<RegionAlert>)? _cache;
  static const _keep = Duration(minutes: 10);

  /// Toutes les alertes en cours, la plus grave d'abord. Une source en
  /// panne n'empêche pas les autres de s'afficher.
  static Future<List<RegionAlert>> fetch() async {
    final hit = _cache;
    if (hit != null && DateTime.now().difference(hit.$1) < _keep) {
      return hit.$2;
    }
    final now = DateTime.now();
    final alerts = <RegionAlert>[
      ?manualAlert(RemoteConfig.instance.setting('passenger_alert'), now),
    ];
    try {
      alerts.addAll(parseOfficialAlerts(await _official(), now));
    } catch (_) {
      // Pas de réseau ou service indisponible : on garde les autres.
    }
    try {
      alerts.addAll(forecastAlerts(await WeatherService.fetch(places.first)));
    } catch (_) {
      // Idem.
    }
    final sorted = sortAlerts(alerts);
    _cache = (DateTime.now(), sorted);
    return sorted;
  }

  static Future<Map<String, dynamic>> _official() async {
    final uri = Uri.https(
      'api.weather.gc.ca',
      '/collections/weather-alerts/items',
      {
        'f': 'json',
        'limit': '50',
        'bbox':
            '${alertArea.west},${alertArea.south},${alertArea.east},${alertArea.north}',
      },
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Environnement Canada ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// Pour les tests.
  static void clearCache() => _cache = null;
}

/// La plus grave d'abord ; une seule alerte par sujet.
List<RegionAlert> sortAlerts(List<RegionAlert> alerts) {
  final seen = <String>{};
  final unique = [
    for (final a in alerts)
      if (a.key.isEmpty || seen.add(a.key)) a,
  ];
  // Tri stable : à gravité égale, l'ordre d'arrivée est gardé.
  return [
    for (final level in AlertLevel.values.reversed)
      ...unique.where((a) => a.level == level),
  ];
}

/// Alertes officielles d'Environnement Canada (API publique, sans clé).
List<RegionAlert> parseOfficialAlerts(Map<String, dynamic> json, DateTime now) {
  final alerts = <RegionAlert>[];
  for (final feature in (json['features'] as List? ?? const [])) {
    final p = (feature as Map)['properties'] as Map? ?? const {};
    if (p['status_en'] == 'ended') continue;
    final expires = DateTime.tryParse('${p['expiration_datetime']}');
    if (expires != null && expires.isBefore(now)) continue;

    final level = switch (p['alert_type']) {
      'warning' => AlertLevel.warning,
      'watch' => AlertLevel.watch,
      'advisory' => AlertLevel.advisory,
      _ => AlertLevel.statement,
    };
    alerts.add(
      RegionAlert(
        key: 'eccc-${p['alert_code']}',
        title: Bi(
          _capitalize('${p['alert_name_fr'] ?? p['alert_short_name_fr']}'),
          _capitalize('${p['alert_name_en'] ?? p['alert_short_name_en']}'),
        ),
        body: Bi(
          _summary('${p['alert_text_fr'] ?? ''}', 'Quoi', 'Quand'),
          _summary('${p['alert_text_en'] ?? ''}', 'What', 'When'),
        ),
        level: level,
        icon: AppIcons.warning,
        source: _environmentCanada,
      ),
    );
  }
  return alerts;
}

/// « Quoi : … Quand : … » ramené à une phrase courte.
String _summary(String text, String what, String when) {
  String? field(String name) {
    final m = RegExp('^$name\\s*:\\s*(.+)\$', multiLine: true).firstMatch(text);
    return m?.group(1)?.trim();
  }

  final parts = [?field(what), ?field(when)];
  final summary = parts.isNotEmpty
      ? parts.join(' — ')
      : text
            .split('\n')
            .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  return summary.length <= 220 ? summary : '${summary.substring(0, 217)}…';
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Seuils au-delà desquels une prévision mérite d'être signalée.
abstract final class AlertThresholds {
  /// Température ressentie (°C) : froid extrême.
  static const extremeCold = -27.0;

  /// Neige sur la journée (cm) : tempête.
  static const heavySnow = 15.0;

  /// Rafales (km/h) : vents violents.
  static const strongGusts = 70.0;

  /// Température maximale (°C) : chaleur accablante.
  static const heat = 32.0;
}

/// Alertes tirées de la prévision d'aujourd'hui et de demain.
List<RegionAlert> forecastAlerts(Weather weather) {
  final alerts = <RegionAlert>[];
  for (final (i, day) in weather.days.take(2).indexed) {
    final when = i == 0
        ? const Bi('aujourd’hui', 'today')
        : const Bi('demain', 'tomorrow');
    String fr(String s) => s.replaceAll('{q}', when.fr);
    String en(String s) => s.replaceAll('{q}', when.en);

    if (day.feelsMin <= AlertThresholds.extremeCold) {
      final t = day.feelsMin.round();
      alerts.add(
        RegionAlert(
          key: 'cold',
          title: Bi(fr('Froid extrême {q}'), en('Extreme cold {q}')),
          body: Bi(
            'Jusqu’à $t °C ressenti. Couvrez-vous bien en sortant.',
            'Down to $t°C with the wind chill. Bundle up when you step out.',
          ),
          level: AlertLevel.advisory,
          icon: AppIcons.thermometer,
          source: _forecastSource,
        ),
      );
    }
    if (day.snow >= AlertThresholds.heavySnow) {
      final cm = day.snow.round();
      alerts.add(
        RegionAlert(
          key: 'snow',
          title: Bi(fr('Tempête de neige {q}'), en('Snowstorm {q}')),
          body: Bi(
            'Environ $cm cm de neige attendus. Prévoyez plus de temps pour vos '
                'déplacements.',
            'About $cm cm of snow expected. Allow extra time to get around.',
          ),
          level: AlertLevel.advisory,
          icon: AppIcons.cloudSnow,
          source: _forecastSource,
        ),
      );
    }
    if (day.gusts >= AlertThresholds.strongGusts) {
      final kmh = day.gusts.round();
      alerts.add(
        RegionAlert(
          key: 'wind',
          title: Bi(fr('Vents violents {q}'), en('Strong winds {q}')),
          body: Bi('Rafales jusqu’à $kmh km/h.', 'Gusts up to $kmh km/h.'),
          level: AlertLevel.advisory,
          icon: AppIcons.wind,
          source: _forecastSource,
        ),
      );
    }
    if (day.code == 66 || day.code == 67) {
      alerts.add(
        RegionAlert(
          key: 'ice',
          title: Bi(fr('Pluie verglaçante {q}'), en('Freezing rain {q}')),
          body: const Bi(
            'Routes et trottoirs glissants. Attention en descendant.',
            'Slippery roads and sidewalks. Watch your step.',
          ),
          level: AlertLevel.advisory,
          icon: AppIcons.cloudRain,
          source: _forecastSource,
        ),
      );
    }
    if (day.max >= AlertThresholds.heat) {
      final t = day.max.round();
      alerts.add(
        RegionAlert(
          key: 'heat',
          title: Bi(fr('Chaleur {q}'), en('Heat {q}')),
          body: Bi(
            'Jusqu’à $t °C. Pensez à boire de l’eau.',
            'Up to $t°C. Remember to drink water.',
          ),
          level: AlertLevel.advisory,
          icon: AppIcons.sun,
          source: _forecastSource,
        ),
      );
    }
  }
  return alerts;
}

/// Message écrit par Yanis dans le panneau d'administration.
/// Forme attendue : `{"fr": "...", "en": "...", "until": "2026-12-24T00:00"}`.
RegionAlert? manualAlert(Object? setting, DateTime now) {
  if (setting is! Map) return null;
  final fr = '${setting['fr'] ?? ''}'.trim();
  final en = '${setting['en'] ?? ''}'.trim();
  if (fr.isEmpty && en.isEmpty) return null;
  final until = DateTime.tryParse('${setting['until']}');
  if (until != null && until.isBefore(now)) return null;
  return RegionAlert(
    key: 'manual',
    title: const Bi('Message de votre chauffeur', 'A note from your driver'),
    body: Bi(fr.isEmpty ? en : fr, en.isEmpty ? fr : en),
    level: AlertLevel.info,
    icon: AppIcons.megaphone,
    source: _driverSource,
  );
}

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../theme/app_icons.dart';
import 'bilingual.dart';

/// Lieu dont on affiche la météo.
@immutable
class Place {
  const Place(this.name, this.latitude, this.longitude);

  final Bi name;
  final double latitude;
  final double longitude;
}

const places = [
  Place(Bi('Montréal', 'Montréal'), 45.5019, -73.5674),
  Place(Bi('Aéroport YUL', 'YUL Airport'), 45.4706, -73.7408),
  Place(Bi('Laval', 'Laval'), 45.6066, -73.7124),
  Place(Bi('Longueuil', 'Longueuil'), 45.5312, -73.5181),
  Place(Bi('Québec', 'Québec City'), 46.8139, -71.2080),
  Place(Bi('Ottawa', 'Ottawa'), 45.4215, -75.6972),
];

@immutable
class HourForecast {
  const HourForecast(this.time, this.temperature, this.code, this.rainChance);

  final DateTime time;
  final double temperature;
  final int code;
  final int rainChance;
}

@immutable
class DayForecast {
  const DayForecast(this.date, this.code, this.max, this.min, this.rainChance);

  final DateTime date;
  final int code;
  final double max;
  final double min;
  final int rainChance;
}

@immutable
class Weather {
  const Weather({
    required this.temperature,
    required this.feelsLike,
    required this.code,
    required this.wind,
    required this.humidity,
    required this.isDay,
    required this.hours,
    required this.days,
  });

  final double temperature;
  final double feelsLike;
  final int code;
  final double wind;
  final int humidity;
  final bool isDay;
  final List<HourForecast> hours;
  final List<DayForecast> days;

  /// Risque de pluie ou de neige dans les prochaines heures.
  int get rainSoon => hours
      .take(6)
      .fold(0, (max, h) => h.rainChance > max ? h.rainChance : max);
}

/// Libellé et icône d'un code météo de l'OMM (ceux que renvoie Open-Meteo).
(Bi, IconData) describeWeather(int code, {bool isDay = true}) => switch (code) {
  0 => (
    const Bi('Ciel dégagé', 'Clear sky'),
    isDay ? AppIcons.sun : AppIcons.moon,
  ),
  1 ||
  2 => (const Bi('Partiellement nuageux', 'Partly cloudy'), AppIcons.cloudSun),
  3 => (const Bi('Couvert', 'Overcast'), AppIcons.cloud),
  45 || 48 => (const Bi('Brouillard', 'Fog'), AppIcons.cloudFog),
  51 ||
  53 ||
  55 ||
  56 ||
  57 => (const Bi('Bruine', 'Drizzle'), AppIcons.cloudRain),
  61 || 63 || 65 || 66 || 67 => (const Bi('Pluie', 'Rain'), AppIcons.cloudRain),
  80 || 81 || 82 => (const Bi('Averses', 'Showers'), AppIcons.cloudRain),
  71 ||
  73 ||
  75 ||
  77 ||
  85 ||
  86 => (const Bi('Neige', 'Snow'), AppIcons.cloudSnow),
  95 ||
  96 ||
  99 => (const Bi('Orage', 'Thunderstorm'), AppIcons.cloudLightning),
  _ => (const Bi('Variable', 'Mixed'), AppIcons.cloudSun),
};

/// Météo en direct par Open-Meteo : gratuit, sans clé, sans compte.
/// Les résultats sont gardés un quart d'heure pour ne pas redemander
/// la même chose à chaque ouverture.
abstract final class WeatherService {
  static final _cache = <Place, (DateTime, Weather)>{};
  static const _keep = Duration(minutes: 15);

  static Weather? cached(Place place) {
    final entry = _cache[place];
    if (entry == null || DateTime.now().difference(entry.$1) > _keep) {
      return null;
    }
    return entry.$2;
  }

  static Future<Weather> fetch(Place place) async {
    final hit = cached(place);
    if (hit != null) return hit;

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${place.latitude}',
      'longitude': '${place.longitude}',
      'current':
          'temperature_2m,apparent_temperature,weather_code,wind_speed_10m,'
          'relative_humidity_2m,is_day',
      'hourly': 'temperature_2m,weather_code,precipitation_probability',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,'
          'precipitation_probability_max',
      'timezone': 'America/Toronto',
      'forecast_days': '6',
      'forecast_hours': '12',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Open-Meteo ${response.statusCode}');
    }
    final weather = parseWeather(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    _cache[place] = (DateTime.now(), weather);
    return weather;
  }
}

/// Transforme la réponse d'Open-Meteo. Séparé pour pouvoir être testé.
Weather parseWeather(Map<String, dynamic> json) {
  final current = json['current'] as Map<String, dynamic>;
  final hourly = json['hourly'] as Map<String, dynamic>;
  final daily = json['daily'] as Map<String, dynamic>;
  num at(Map<String, dynamic> m, String key, int i) =>
      ((m[key] as List)[i] as num?) ?? 0;

  return Weather(
    temperature: (current['temperature_2m'] as num).toDouble(),
    feelsLike: (current['apparent_temperature'] as num).toDouble(),
    code: (current['weather_code'] as num).toInt(),
    wind: (current['wind_speed_10m'] as num).toDouble(),
    humidity: (current['relative_humidity_2m'] as num).toInt(),
    isDay: current['is_day'] == 1,
    hours: [
      for (var i = 0; i < (hourly['time'] as List).length; i++)
        HourForecast(
          DateTime.parse((hourly['time'] as List)[i] as String),
          at(hourly, 'temperature_2m', i).toDouble(),
          at(hourly, 'weather_code', i).toInt(),
          at(hourly, 'precipitation_probability', i).toInt(),
        ),
    ],
    days: [
      for (var i = 0; i < (daily['time'] as List).length; i++)
        DayForecast(
          DateTime.parse((daily['time'] as List)[i] as String),
          at(daily, 'weather_code', i).toInt(),
          at(daily, 'temperature_2m_max', i).toDouble(),
          at(daily, 'temperature_2m_min', i).toDouble(),
          at(daily, 'precipitation_probability_max', i).toInt(),
        ),
    ],
  );
}

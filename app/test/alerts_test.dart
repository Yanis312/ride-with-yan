import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/data/alerts.dart';
import 'package:ride_with_yan/data/weather.dart';

Map<String, dynamic> _official(Map<String, dynamic> props) => {
  'features': [
    {'properties': props},
  ],
};

Weather _weather(List<DayForecast> days) => Weather(
  temperature: 0,
  feelsLike: 0,
  code: 0,
  wind: 0,
  humidity: 0,
  isDay: true,
  hours: const [],
  days: days,
);

DayForecast _day({
  int code = 3,
  double max = 0,
  double feelsMin = -5,
  double snow = 0,
  double gusts = 20,
}) => DayForecast(
  DateTime(2026, 1, 15),
  code,
  max,
  -10,
  10,
  feelsMin: feelsMin,
  snow: snow,
  gusts: gusts,
);

void main() {
  final now = DateTime.utc(2026, 1, 15, 12);

  group('alertes officielles d’Environnement Canada', () {
    final warning = {
      'alert_code': 'WS',
      'alert_type': 'warning',
      'alert_name_fr': 'avertissement de tempête hivernale',
      'alert_name_en': 'winter storm warning',
      'alert_text_fr':
          'Quoi : de 25 à 35 cm de neige.\n\nQuand : demain\n\nOù : Ottawa',
      'alert_text_en': 'What: 25 to 35 cm of snow.\n\nWhen: tomorrow\n\n',
      'status_en': 'issued',
      'expiration_datetime': '2026-01-16T10:00:00Z',
    };

    test('résume « Quoi » et « Quand » dans les deux langues', () {
      final alert = parseOfficialAlerts(_official(warning), now).single;

      expect(alert.level, AlertLevel.warning);
      expect(alert.title.fr, 'Avertissement de tempête hivernale');
      expect(alert.title.en, 'Winter storm warning');
      expect(alert.body.fr, 'de 25 à 35 cm de neige. — demain');
      expect(alert.body.en, '25 to 35 cm of snow. — tomorrow');
    });

    test('ignore les alertes terminées ou expirées', () {
      expect(
        parseOfficialAlerts(_official({...warning, 'status_en': 'ended'}), now),
        isEmpty,
      );
      expect(
        parseOfficialAlerts(
          _official({...warning, 'expiration_datetime': '2026-01-15T11:00Z'}),
          now,
        ),
        isEmpty,
      );
    });

    test('une même alerte sur plusieurs secteurs ne s’affiche qu’une fois', () {
      final twice = {
        'features': [
          {'properties': warning},
          {
            'properties': {...warning, 'feature_name_fr': 'Gatineau'},
          },
        ],
      };
      expect(sortAlerts(parseOfficialAlerts(twice, now)), hasLength(1));
    });

    test('une réponse vide ou inattendue ne plante pas', () {
      expect(parseOfficialAlerts({}, now), isEmpty);
      expect(parseOfficialAlerts({'features': []}, now), isEmpty);
    });
  });

  group('alertes tirées de la prévision', () {
    test('grand froid demain à −30 °C ressenti', () {
      final alerts = forecastAlerts(_weather([_day(), _day(feelsMin: -30.4)]));

      expect(alerts.single.title.fr, 'Froid extrême demain');
      expect(alerts.single.body.fr, contains('-30 °C'));
    });

    test('tempête de neige, vents violents et verglas', () {
      final alerts = forecastAlerts(
        _weather([_day(snow: 22, gusts: 80, code: 67)]),
      );
      expect(alerts.map((a) => a.key), ['snow', 'wind', 'ice']);
      expect(alerts.first.title.en, 'Snowstorm today');
    });

    test('rien à signaler par temps ordinaire', () {
      expect(forecastAlerts(_weather([_day(), _day()])), isEmpty);
    });

    test('on ne regarde que aujourd’hui et demain', () {
      final later = _weather([_day(), _day(), _day(feelsMin: -40)]);
      expect(forecastAlerts(later), isEmpty);
    });
  });

  group('message du chauffeur', () {
    test('affiché jusqu’à sa date de fin', () {
      final setting = {
        'fr': 'Pont fermé, détour',
        'en': 'Bridge closed, detour',
        'until': '2026-01-16T23:59',
      };
      expect(manualAlert(setting, now)!.body.en, 'Bridge closed, detour');
      expect(manualAlert(setting, DateTime(2026, 1, 17)), isNull);
    });

    test('une seule langue remplie sert pour les deux', () {
      expect(manualAlert({'fr': 'Bonjour'}, now)!.body.en, 'Bonjour');
    });

    test('vide ou mal formé : pas de message', () {
      expect(manualAlert(null, now), isNull);
      expect(manualAlert('texte', now), isNull);
      expect(manualAlert({'fr': '  '}, now), isNull);
    });
  });

  test('la plus grave d’abord', () {
    final alerts = sortAlerts([
      manualAlert({'fr': 'Info'}, now)!,
      ...forecastAlerts(_weather([_day(feelsMin: -31)])),
      ...parseOfficialAlerts(
        _official({
          'alert_code': 'X',
          'alert_type': 'warning',
          'status_en': 'issued',
        }),
        now,
      ),
    ]);
    expect(alerts.map((a) => a.level), [
      AlertLevel.warning,
      AlertLevel.advisory,
      AlertLevel.info,
    ]);
  });
}

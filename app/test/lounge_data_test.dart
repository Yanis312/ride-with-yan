import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/backend/backend.dart';
import 'package:ride_with_yan/backend/remote_config.dart';
import 'package:ride_with_yan/data/store_catalog.dart';
import 'package:ride_with_yan/data/news.dart';
import 'package:ride_with_yan/data/poll.dart';
import 'package:ride_with_yan/data/videos.dart';
import 'package:ride_with_yan/data/weather.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => Backend.offline = true);

  test('un fil RSS donne titre, résumé, image et date', () {
    final items = parseRss('''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"><channel><title>Fil</title>
<item>
  <title><![CDATA[ L&#x27;hiver arrive ]]></title>
  <link>https://exemple.ca/a</link>
  <description><![CDATA[ <p>Première <b>neige</b> attendue.</p> ]]></description>
  <pubDate>Sun, 04 Oct 2026 04:18:05 GMT</pubDate>
  <enclosure type="image/jpeg" length="0" url="https://exemple.ca/a.jpg" />
</item>
<item>
  <title>Second</title>
  <link>https://exemple.ca/b</link>
  <description><![CDATA[<img src='https://exemple.ca/b.jpg' alt='x'/><p>Texte</p>]]></description>
  <pubDate>Sat, 03 Oct 2026 12:50:17 EDT</pubDate>
</item>
</channel></rss>''');

    expect(items, hasLength(2));
    expect(items[0].title, 'L’hiver arrive');
    expect(items[0].summary, 'Première neige attendue.');
    expect(items[0].image, 'https://exemple.ca/a.jpg');
    expect(items[0].date, DateTime.utc(2026, 10, 4, 4, 18, 5));
    expect(items[1].image, 'https://exemple.ca/b.jpg');
    expect(items[1].summary, 'Texte');
    // 12 h 50 heure avancée de l'Est = 16 h 50 en heure universelle.
    expect(items[1].date, DateTime.utc(2026, 10, 3, 16, 50, 17));
  });

  test('la réponse météo est lue correctement', () {
    final weather = parseWeather({
      'current': {
        'temperature_2m': 6.6,
        'apparent_temperature': 4.3,
        'weather_code': 61,
        'wind_speed_10m': 4.8,
        'relative_humidity_2m': 78,
        'is_day': 0,
      },
      'hourly': {
        'time': ['2026-10-04T00:00', '2026-10-04T01:00'],
        'temperature_2m': [6.6, 6.1],
        'weather_code': [61, 3],
        'precipitation_probability': [80, null],
      },
      'daily': {
        'time': ['2026-10-04'],
        'weather_code': [61],
        'temperature_2m_max': [12.0],
        'temperature_2m_min': [3.5],
        'precipitation_probability_max': [80],
      },
    });

    expect(weather.temperature, 6.6);
    expect(weather.isDay, isFalse);
    expect(weather.hours, hasLength(2));
    expect(weather.hours[1].rainChance, 0);
    expect(weather.rainSoon, 80);
    expect(weather.days.single.max, 12.0);
    expect(describeWeather(61).$1.fr, 'Pluie');
  });

  test('un passager ne vote qu\'une fois par question', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PollStore.instance..clear();
    final q = pollQuestions.first;

    await store.vote(q, q.options[0], 1);
    await store.vote(q, q.options[1], 1); // même passager : ignoré
    await store.vote(q, q.options[1], 2);

    expect(store.total(q), 2);
    expect(store.share(q, q.options[0]), 0.5);
    expect(store.hasVoted(q, 2), isTrue);
    expect(store.hasVoted(q, 3), isFalse);
  });

  test('la question du jour change chaque jour', () {
    final a = questionOfTheDay(DateTime(2026, 10, 4));
    final b = questionOfTheDay(DateTime(2026, 10, 5));
    expect(a.id, isNot(b.id));
  });

  test('aucune vidéo en double', () {
    final ids = [for (final c in videoCategories) ...c.videos.map((v) => v.id)];
    expect(ids.toSet(), hasLength(ids.length));
  });

  test("les réglages de l'administration s'appliquent au catalogue", () {
    final remote = RemoteConfig.instance;
    addTearDown(remote.setForTest);

    remote.setForTest(
      products: {
        'chaussures-blanc': {
          'price': 85,
          'sizes': {'US 9': 4, 'US 99': 7},
        },
        'water': {'hidden': true},
        'umbrella': {'stock': 9},
      },
      settings: {'poll_question': 'plat'},
    );

    final shoes = catalog.firstWhere((p) => p.id == 'chaussures-blanc');
    expect(shoes.price, 85);
    expect(shoes.stockOf('US 9'), 4);
    expect(
      shoes.sizes.containsKey('US 99'),
      isFalse,
    ); // taille inconnue ignorée
    expect(shoes.stockOf('US 8'), 1); // taille non modifiée
    expect(catalog.any((p) => p.id == 'water'), isFalse);
    expect(catalog.firstWhere((p) => p.id == 'umbrella').stock, 9);
    expect(questionOfTheDay().id, 'plat');

    remote.setForTest();
    expect(catalog.any((p) => p.id == 'water'), isTrue);
  });
}

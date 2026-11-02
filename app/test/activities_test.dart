import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/data/activities.dart';

void main() {
  Map<String, dynamic> row({
    String id = '2026-11-20-concert',
    String city = 'Ottawa',
    String start = '2026-11-20T20:00:00-05:00',
    bool active = true,
  }) => {
    'id': id,
    'title_fr': 'Concert',
    'title_en': '',
    'venue': 'Centre Bronson',
    'city': city,
    'starts_at': start,
    'link': 'https://exemple.ca/billets',
    'photo_url': 'http://pas-securise.ca/a.jpg',
    'active': active,
  };

  test('une ligne de la base devient une activité affichable', () {
    final a = Activity.fromRow(row())!;

    expect(a.title.en, 'Concert', reason: 'une langue vide reprend l’autre');
    expect(a.city, 'Ottawa');
    expect(a.link, 'https://exemple.ca/billets');
    expect(a.photoUrl, isNull, reason: 'seuls les liens https sont gardés');
    expect(a.startsAt.isUtc, isFalse, reason: 'affichée à l’heure locale');
  });

  test('seules Ottawa et Gatineau sont acceptées', () {
    expect(Activity.fromRow(row(city: 'Gatineau')), isNotNull);
    expect(Activity.fromRow(row(city: 'Montréal')), isNull);
  });

  test('une ligne sans date valide est ignorée', () {
    expect(Activity.fromRow(row(start: 'bientôt')), isNull);
  });

  test('les activités à venir sont triées, les jours passés disparaissent', () {
    Activity at(String id, DateTime date) =>
        Activity.fromRow(row(id: id, start: date.toIso8601String()))!;
    final now = DateTime(2026, 11, 20, 23, 30);

    final shown = upcomingActivities([
      at('demain', DateTime(2026, 11, 21, 19)),
      at('hier', DateTime(2026, 11, 19, 19)),
      at('ce-soir', DateTime(2026, 11, 20, 19)),
    ], now);

    expect(shown.map((a) => a.id), ['ce-soir', 'demain']);
  });

  group('fiche saisie dans l’admin', () {
    Map<String, String> form({
      String title = 'Concert',
      String date = '2026-11-20 20:00',
      String link = 'https://exemple.ca',
      String photo = '',
    }) => {
      'title_fr': title,
      'title_en': '',
      'venue': 'Centre Bronson',
      'starts_at': date,
      'link': link,
      'photo_url': photo,
    };

    test('crée un identifiant et une date universelle', () {
      final (row, error) = activityRowFrom(form(), city: 'Gatineau');

      expect(error, isNull);
      expect(row!['id'], '2026-11-20-concert');
      expect(row['city'], 'Gatineau');
      expect(row['starts_at'], endsWith('Z'));
      expect(row['photo_url'], isNull);
    });

    test('garde l’identifiant d’une fiche existante', () {
      final (row, _) = activityRowFrom(form(), city: 'Ottawa', id: 'ancien');
      expect(row!['id'], 'ancien');
    });

    test('refuse le titre vide, la mauvaise date et les liens non sûrs', () {
      expect(activityRowFrom(form(title: ' '), city: 'Ottawa').$2, isNotNull);
      expect(
        activityRowFrom(form(date: '20 novembre'), city: 'Ottawa').$2,
        isNotNull,
      );
      expect(
        activityRowFrom(form(link: 'http://x.ca'), city: 'Ottawa').$2,
        isNotNull,
      );
      expect(activityRowFrom(form(), city: 'Montréal').$2, isNotNull);
    });
  });

  test('sans base, la liste reste vide et il n’y a aucune fausse activité', () {
    final store = ActivityStore.instance..setForTest(const []);
    expect(store.list, isEmpty);
  });
}

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/admin/admin_app.dart';
import 'package:ride_with_yan/data/advertisers.dart';

void main() {
  final row = {
    'id': 'cafe-atlas',
    'name': 'Café Atlas',
    'category_fr': 'Café',
    'category_en': '',
    'description_fr': 'Café de spécialité.',
    'description_en': 'Specialty coffee.',
    'offer_fr': '−10 % avec Ride with Yan',
    'offer_en': '10% off with Ride with Yan',
    'lat': 45.42,
    'lng': -75.70,
    'color': 'E8A23A',
    'photo_url': 'https://exemple.ca/photo.jpg',
    'instagram': 'https://instagram.com/atlas',
    'facebook': 'http://pas-securise.ca',
    'active': true,
  };

  test('une fiche de la base devient un annonceur affichable', () {
    final a = Advertiser.fromRow(row);

    expect(a.id, 'cafe-atlas');
    expect(a.category.en, 'Café', reason: 'une langue vide reprend l’autre');
    expect(a.offer!.en, '10% off with Ride with Yan');
    expect(a.location.latitude, 45.42);
    expect(a.colors.first, const Color(0xFFE8A23A));
    expect(a.image, isA<NetworkImage>());
    expect(a.instagram, 'https://instagram.com/atlas');
    expect(a.facebook, isNull, reason: 'seuls les liens https sont gardés');
    expect(a.example, isFalse);
  });

  test('le QR d’un vrai partenaire passe par le lien suivi', () {
    final a = Advertiser.fromRow(row);
    expect(
      a.qrLink('instagram', a.instagram!),
      endsWith('/functions/v1/go?ad=cafe-atlas&to=instagram'),
    );
    // Les fiches d'exemple gardent leur lien direct.
    final example = exampleAdvertisers.first;
    expect(example.qrLink('instagram', 'https://x.com'), 'https://x.com');
  });

  test('sans partenaire saisi, la tablette montre les exemples', () {
    final store = AdvertiserStore.instance;
    addTearDown(() => store.setForTest(const []));
    expect(store.list, exampleAdvertisers);

    store.setForTest([Advertiser.fromRow(row)]);
    expect(store.list.single.name, 'Café Atlas');
  });

  test('identifiant tiré du nom', () {
    expect(advertiserSlug('Café Atlas'), 'cafe-atlas');
    expect(advertiserSlug('  Sushi & Co. Gatineau! '), 'sushi-co-gatineau');
  });
}

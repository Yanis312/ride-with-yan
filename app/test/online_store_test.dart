import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/data/store_catalog.dart';
import 'package:ride_with_yan/screens/online_store.dart';

void main() {
  final product = catalog.firstWhere((p) => p.photos.isNotEmpty);

  test('le message WhatsApp contient l’article, la taille et la photo', () {
    final message = productOrderMessage(
      product,
      size: 'US 9',
      english: false,
      origin: 'https://exemple.test',
    );
    expect(message, startsWith('Bonjour Yanis, je voudrais commander :'));
    expect(message, contains(product.name.fr));
    expect(message, contains('taille US 9'));
    expect(
      message,
      contains('https://exemple.test/assets/${product.photos.first}'),
    );
    expect(message, contains('Mon adresse de livraison :'));
  });

  test('en anglais aussi', () {
    final message = productOrderMessage(product, english: true);
    expect(message, startsWith('Hi Yanis, I would like to order:'));
    expect(message, contains(product.name.en));
  });

  test('le QR code mène à la boutique seule', () {
    expect(Uri.parse(onlineStoreUrl).queryParameters, contains('boutique'));
  });
}

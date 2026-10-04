import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/data/store_catalog.dart';

void main() {
  final water = catalog.firstWhere((p) => p.id == 'water');
  final umbrella = catalog.firstWhere((p) => p.id == 'umbrella');

  test('le panier additionne quantités et prix', () {
    final cart = Cart()
      ..add(water)
      ..add(water)
      ..add(umbrella);

    expect(cart.count, 3);
    expect(cart.total, water.price * 2 + umbrella.price);
  });

  test('impossible de dépasser le stock', () {
    final cart = Cart();
    for (var i = 0; i < umbrella.stock + 3; i++) {
      cart.add(umbrella);
    }
    expect(cart.quantityOf(umbrella), umbrella.stock);
  });

  test('retirer le dernier exemplaire enlève la ligne', () {
    final cart = Cart()..add(water);
    cart.remove(water);
    expect(cart.isEmpty, isTrue);
  });

  final shoes = catalog.firstWhere((p) => p.id == 'chaussures-blanc');

  test('une ligne par taille, stock propre à chaque taille', () {
    final cart = Cart()
      ..add(shoes, 'US 9')
      ..add(shoes, 'US 10');
    expect(cart.lines, hasLength(2));
    expect(cart.total, shoes.price * 2);

    for (var i = 0; i < 5; i++) {
      cart.add(shoes, 'US 9');
    }
    expect(cart.quantityOf(shoes, 'US 9'), shoes.stockOf('US 9'));
  });

  test("une taille épuisée ne s'ajoute pas", () {
    final jersey = catalog.firstWhere((p) => p.id == 'maillot-exterieur');
    final cart = Cart()..add(jersey, 'S');
    expect(jersey.stockOf('S'), 0);
    expect(cart.isEmpty, isTrue);
  });

  test('aucun nom de marque dans le catalogue', () {
    for (final p in catalog) {
      expect(p.brand, isNull);
    }
  });

  test('la vitrine ne montre que les articles revendus en stock', () {
    expect(featuredProducts, isNotEmpty);
    expect(
      featuredProducts.every((p) => p.isResale && p.stockOf() > 0),
      isTrue,
    );
  });
}

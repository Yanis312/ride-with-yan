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
}

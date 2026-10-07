import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/backend/remote_config.dart';
import 'package:ride_with_yan/data/orders.dart';
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

  test('une taille pas à bord se commande, payable à la livraison', () {
    final jersey = catalog.firstWhere((p) => p.id == 'maillot-mbappe');
    final water = catalog.firstWhere((p) => p.id == 'water');
    final cart = Cart()
      ..add(jersey, 'S')
      ..add(water);

    expect(jersey.stockOf('S'), 0);
    expect(cart.lines.first.onOrder, isTrue);
    expect(cart.hasOnOrder, isTrue);
    expect(cart.payNow, water.price);
    expect(cart.payLater, jersey.price);

    // Quelques pièces au plus pour un même article sur commande.
    for (var i = 0; i < 10; i++) {
      cart.add(jersey, 'S');
    }
    expect(cart.quantityOf(jersey, 'S'), Cart.maxOnOrder);
  });

  test("un article épuisé qui ne se commande pas ne s'ajoute pas", () {
    final remote = RemoteConfig.instance;
    addTearDown(remote.setForTest);
    remote.setForTest(
      products: {
        'umbrella': {'stock': 0},
      },
    );
    final umbrella = catalog.firstWhere((p) => p.id == 'umbrella');
    final cart = Cart()..add(umbrella);
    expect(cart.isEmpty, isTrue);
  });

  test('les lignes de commande copient nom, taille, prix et statut', () {
    final jersey = catalog.firstWhere((p) => p.id == 'maillot-yamal');
    final lines = orderLines(Cart()..add(jersey, 'M'));
    expect(lines.single, {
      'id': 'maillot-yamal',
      'name': 'Maillot Yamal',
      'size': 'M',
      'qty': 1,
      'price': 50.0,
      'on_order': true,
    });
  });

  test('numéros de téléphone acceptés et refusés', () {
    expect(isValidPhone('514 555-0199'), isTrue);
    expect(isValidPhone('+1 (438) 994-8668'), isTrue);
    expect(isValidPhone('12345'), isFalse);
    expect(isValidPhone('appelle-moi'), isFalse);
  });

  test('les maillots sur commande restent dans la vitrine', () {
    final jersey = catalog.firstWhere((p) => p.id == 'maillot-yamal');
    expect(jersey.stockOf(), 0);
    expect(jersey.preorder, isTrue);
    expect(featuredProducts, contains(jersey));
  });

  test('aucun nom de marque dans le catalogue', () {
    for (final p in catalog) {
      expect(p.brand, isNull);
    }
  });

  test('la vitrine montre les articles à bord ou commandables', () {
    expect(featuredProducts, isNotEmpty);
    expect(
      featuredProducts.every(
        (p) => p.isResale && (p.stockOf() > 0 || p.preorder),
      ),
      isTrue,
    );
  });
}

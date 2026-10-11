import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/backend/remote_config.dart';
import 'package:ride_with_yan/data/bilingual.dart';
import 'package:ride_with_yan/data/orders.dart';
import 'package:ride_with_yan/data/store_catalog.dart';
import 'package:ride_with_yan/theme/app_icons.dart';

Product _find(String id) => catalog.firstWhere((p) => p.id == id);

/// Met quelques paires en stock, comme le ferait le panneau d'administration.
void _stockShoes() {
  final remote = RemoteConfig.instance;
  addTearDown(remote.setForTest);
  remote.setForTest(
    products: {
      'chaussures-blanc': {
        'sizes': {'US 9': 2, 'US 10': 1},
      },
    },
  );
}

void main() {
  test(
    'tout le catalogue est sur commande : chaussures 100 \$, maillots 50 \$',
    () {
      expect(catalog, hasLength(15));
      for (final p in catalog) {
        expect(p.stockOf(), 0, reason: p.id);
        expect(p.preorder, isTrue, reason: p.id);
        expect(
          p.price,
          p.category == ProductCategory.sneakers ? 100 : 50,
          reason: p.id,
        );
      }
    },
  );

  test('le panier additionne quantités et prix', () {
    final shoes = _find('chaussures-noir');
    final cart = Cart()
      ..add(shoes, 'US 9')
      ..add(shoes, 'US 9')
      ..add(shoes, 'US 10');

    expect(cart.count, 3);
    expect(cart.lines, hasLength(2));
    expect(cart.total, 300);
    // Rien à bord : tout se paie à la livraison.
    expect(cart.payNow, 0);
    expect(cart.payLater, 300);
  });

  test('retirer le dernier exemplaire enlève la ligne', () {
    final jersey = _find('maillot-olise');
    final cart = Cart()..add(jersey, 'L');
    cart.remove(jersey, 'L');
    expect(cart.isEmpty, isTrue);
  });

  test('quelques pièces au plus pour un même article sur commande', () {
    final jersey = _find('maillot-mbappe');
    final cart = Cart();
    for (var i = 0; i < 10; i++) {
      cart.add(jersey, 'S');
    }
    expect(cart.lines.single.onOrder, isTrue);
    expect(cart.quantityOf(jersey, 'S'), Cart.maxOnOrder);
  });

  group('combo paire + maillot à 140 \$', () {
    test('une paire et un maillot reviennent à 140 \$', () {
      final cart = Cart()
        ..add(_find('chaussures-blanc'), 'US 9')
        ..add(_find('maillot-yamal'), 'M');

      expect(cart.combos, 1);
      expect(cart.comboDiscount, 10);
      expect(cart.total, comboPrice);
      expect(cart.payLater, comboPrice);
    });

    test('pas de rabais sans maillot, ou sans chaussures', () {
      expect((Cart()..add(_find('chaussures-noir'), 'US 8')).total, 100);
      expect((Cart()..add(_find('maillot-olise'), 'S')).total, 50);
      final twoJerseys = Cart()
        ..add(_find('maillot-olise'), 'S')
        ..add(_find('maillot-yamal'), 'S');
      expect(twoJerseys.comboDiscount, 0);
      expect(twoJerseys.total, 100);
    });

    test('un rabais par paire accompagnée d’un maillot', () {
      final cart = Cart()
        ..add(_find('chaussures-noir'), 'US 8')
        ..add(_find('chaussures-camel'), 'US 9')
        ..add(_find('maillot-olise'), 'S')
        ..add(_find('maillot-yamal'), 'M')
        ..add(_find('maillot-mbappe'), 'L');

      // Deux combos (280 \$) et un maillot seul (50 \$).
      expect(cart.combos, 2);
      expect(cart.total, 330);
    });

    test('retirer le maillot annule le rabais', () {
      final jersey = _find('maillot-yamal');
      final cart = Cart()
        ..add(_find('chaussures-blanc'), 'US 9')
        ..add(jersey, 'M');
      cart.remove(jersey, 'M');
      expect(cart.total, 100);
    });
  });

  group('avec du stock à bord', () {
    test('impossible de dépasser le stock d’une taille', () {
      _stockShoes();
      final shoes = _find('chaussures-blanc');
      final cart = Cart();
      for (var i = 0; i < 5; i++) {
        cart.add(shoes, 'US 9');
      }
      expect(cart.quantityOf(shoes, 'US 9'), 2);
    });

    test(
      'ce qui est à bord se paie tout de suite, le reste à la livraison',
      () {
        _stockShoes();
        final cart = Cart()
          ..add(_find('chaussures-blanc'), 'US 9')
          ..add(_find('chaussures-noir'), 'US 9');

        expect(cart.lines.first.onOrder, isFalse);
        expect(cart.lines.last.onOrder, isTrue);
        expect(cart.payNow, 100);
        expect(cart.payLater, 100);
      },
    );

    test('le rabais du combo est retiré de ce qui se paie à la livraison', () {
      _stockShoes();
      final cart = Cart()
        ..add(_find('chaussures-blanc'), 'US 9')
        ..add(_find('maillot-yamal'), 'M');

      expect(cart.payNow, 100);
      expect(cart.payLater, 40);
      expect(cart.total, comboPrice);
    });
  });

  test("un article épuisé qui ne se commande pas ne s'ajoute pas", () {
    const soldOut = Product(
      id: 'test',
      name: Bi('Test', 'Test'),
      blurb: Bi('', ''),
      price: 10,
      category: ProductCategory.jerseys,
      icon: AppIcons.tShirt,
      colors: [],
      stock: 0,
    );
    expect((Cart()..add(soldOut)).isEmpty, isTrue);
  });

  test('les lignes de commande copient nom, taille, prix et statut', () {
    final lines = orderLines(Cart()..add(_find('maillot-yamal'), 'M'));
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

  test('aucun nom de marque dans le catalogue', () {
    for (final p in catalog) {
      expect(p.brand, isNull);
    }
  });

  test('la vitrine montre tous les articles commandables', () {
    expect(featuredProducts, hasLength(catalog.length));
  });
}

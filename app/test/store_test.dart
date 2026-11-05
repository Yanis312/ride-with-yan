import 'dart:io';

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
  test('tout le catalogue est sur commande : chaussures 80 \$, doudounes '
      '120 \$, maillots 50 \$', () {
    for (final p in catalog) {
      expect(p.stockOf(), 0, reason: p.id);
      expect(p.preorder, isTrue, reason: p.id);
      expect(p.price, switch (p.category) {
        ProductCategory.sneakers => 80,
        ProductCategory.jackets => 120,
        ProductCategory.jerseys => 50,
      }, reason: p.id);
    }
  });

  group('deux boutiques : hommes et femmes', () {
    test('chaque article est rangé dans au moins un rayon', () {
      for (final p in catalog) {
        expect(p.shoppers, isNotEmpty, reason: p.id);
      }
    });

    test('le rose chez les femmes, le bleu chez les hommes', () {
      final women = catalogFor(Shopper.women).map((p) => p.id);
      final men = catalogFor(Shopper.men).map((p) => p.id);
      expect(women, contains('chaussures-rose-bonbon'));
      expect(men, isNot(contains('chaussures-rose-bonbon')));
      expect(men, contains('chaussures-bleu-ciel'));
      expect(women, isNot(contains('chaussures-bleu-ciel')));
    });

    test('chaque rayon montre d’abord ses propres articles', () {
      expect(catalogFor(Shopper.women).first.id, 'chaussures-rose-bonbon');
      expect(catalogFor(Shopper.men).first.id, 'chaussures-bleu-ciel');
    });

    test('le blanc, le noir et les doudounes dans les deux rayons', () {
      for (final id in [
        'chaussures-blanc',
        'chaussures-noir',
        'doudoune-noire',
      ]) {
        expect(_find(id).shoppers, {Shopper.men, Shopper.women}, reason: id);
      }
    });

    test('la vitrine d’un rayon alterne les catégories', () {
      final shown = featuredFor(Shopper.men);
      expect(shown.take(3).map((p) => p.category), [
        ProductCategory.sneakers,
        ProductCategory.jackets,
        ProductCategory.jerseys,
      ]);
      expect(shown.every((p) => p.shoppers.contains(Shopper.men)), isTrue);
      expect(featuredFor(Shopper.women, limit: 5), hasLength(5));
    });
  });

  test('le panier additionne quantités et prix', () {
    final shoes = _find('chaussures-noir');
    final cart = Cart()
      ..add(shoes, 'US 9')
      ..add(shoes, 'US 9')
      ..add(shoes, 'US 10');

    expect(cart.count, 3);
    expect(cart.lines, hasLength(2));
    expect(cart.total, 240);
  });

  test('la moitié à la commande, le reste à la livraison', () {
    final cart = Cart()..add(_find('doudoune-noire'), 'M');
    expect(cart.total, 120);
    expect(cart.deposit, 60);
    expect(cart.balance, 60);
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

  group('combo paire + maillot à 120 \$', () {
    test('une paire et un maillot reviennent à 120 \$', () {
      final cart = Cart()
        ..add(_find('chaussures-blanc'), 'US 9')
        ..add(_find('maillot-yamal'), 'M');

      expect(cart.combos, 1);
      expect(cart.comboDiscount, 10);
      expect(cart.total, comboPrice);
      expect(cart.deposit, comboPrice / 2);
    });

    test('pas de rabais sans maillot, ou sans chaussures', () {
      expect((Cart()..add(_find('chaussures-noir'), 'US 8')).total, 80);
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

      // Deux combos (240 \$) et un maillot seul (50 \$).
      expect(cart.combos, 2);
      expect(cart.total, 290);
    });

    test('retirer le maillot annule le rabais', () {
      final jersey = _find('maillot-yamal');
      final cart = Cart()
        ..add(_find('chaussures-blanc'), 'US 9')
        ..add(jersey, 'M');
      cart.remove(jersey, 'M');
      expect(cart.total, 80);
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

  group('message WhatsApp de la commande', () {
    Cart order() => Cart()
      ..add(_find('chaussures-blanc'), 'US 9')
      ..add(_find('maillot-yamal'), 'M');

    test('en français : articles, tailles, total et acompte', () {
      final message = orderMessage(order(), english: false);
      expect(message, startsWith('Bonjour Yanis, je voudrais commander :'));
      expect(message, contains('1 × Blanc intégral (Chaussures), taille US 9'));
      expect(message, contains('1 × Maillot Yamal (Maillots), taille M'));
      expect(message, contains('Rabais combo : −10 \$'));
      expect(message, contains('Total : 120 \$ · acompte 50 % : 60 \$'));
      expect(message, endsWith('Mon adresse de livraison :'));
    });

    test('en anglais', () {
      final message = orderMessage(order(), english: true);
      expect(message, contains('1 × All white (Shoes), size US 9 : \$80'));
      expect(message, contains('Total: \$120 · 50% deposit: \$60'));
      expect(message, endsWith('My delivery address:'));
    });

    test('les montants avec des cents gardent deux décimales', () {
      expect(orderAmount(42.5, english: false), '42,50 \$');
      expect(orderAmount(42.5, english: true), '\$42.50');
    });
  });

  test('aucun nom de marque dans le catalogue', () {
    for (final p in catalog) {
      expect(p.brand, isNull);
    }
  });

  test('la vitrine montre tous les articles commandables', () {
    expect(featuredProducts, hasLength(catalog.length));
  });

  test('chaque photo annoncée existe dans les assets', () {
    for (final p in catalog) {
      for (final photo in p.photos) {
        expect(File(photo).existsSync(), isTrue, reason: photo);
      }
    }
  });
}

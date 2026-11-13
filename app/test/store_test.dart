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
  test('tout le catalogue est sur commande : 80 \$, sacs 100 \$', () {
    for (final p in catalog) {
      expect(p.stockOf(), 0, reason: p.id);
      expect(p.preorder, isTrue, reason: p.id);
      expect(
        p.price,
        p.category == ProductCategory.bags ? 100 : 80,
        reason: p.id,
      );
    }
  });

  test('quatre sections : Air Force 1, Dunk, Vans, The North Face', () {
    for (final c in ProductCategory.values) {
      // « Nouveautés » ne se remplit qu'avec les articles de l'administration.
      if (c == ProductCategory.other) continue;
      expect(catalog.where((p) => p.category == c), isNotEmpty, reason: '$c');
    }
    expect(_find('chaussures-rose-bonbon').category, ProductCategory.dunk);
    expect(_find('chaussures-patchwork').category, ProductCategory.vans);
    expect(_find('doudoune-noire').category, ProductCategory.northFace);
  });

  test('plus de maillots dans la boutique', () {
    expect(catalog.where((p) => p.id.startsWith('maillot')), isEmpty);
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
      expect(catalogFor(Shopper.women).first.id, 'chaussures-rose-bordeaux');
      expect(catalogFor(Shopper.men).first.id, 'chaussures-bleu-vernis');
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

    test('la vitrine d’un rayon alterne les sections', () {
      final shown = featuredFor(Shopper.men);
      expect(shown.take(4).map((p) => p.category), [
        ProductCategory.airForce1,
        ProductCategory.dunk,
        ProductCategory.vans,
        ProductCategory.northFace,
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
    final cart = Cart()
      ..add(_find('doudoune-noire'), 'M')
      ..add(_find('chaussures-moka'), 'US 9');
    expect(cart.total, 160);
    expect(cart.deposit, 80);
    expect(cart.balance, 80);
  });

  test('retirer le dernier exemplaire enlève la ligne', () {
    final jacket = _find('doudoune-orange');
    final cart = Cart()..add(jacket, 'L');
    cart.remove(jacket, 'L');
    expect(cart.isEmpty, isTrue);
  });

  test('quelques pièces au plus pour un même article sur commande', () {
    final jacket = _find('doudoune-jaune');
    final cart = Cart();
    for (var i = 0; i < 10; i++) {
      cart.add(jacket, 'S');
    }
    expect(cart.lines.single.onOrder, isTrue);
    expect(cart.quantityOf(jacket, 'S'), Cart.maxOnOrder);
  });

  test('impossible de dépasser le stock d’une taille à bord', () {
    _stockShoes();
    final shoes = _find('chaussures-blanc');
    final cart = Cart();
    for (var i = 0; i < 5; i++) {
      cart.add(shoes, 'US 9');
    }
    expect(cart.quantityOf(shoes, 'US 9'), 2);
  });

  test("un article épuisé qui ne se commande pas ne s'ajoute pas", () {
    const soldOut = Product(
      id: 'test',
      name: Bi('Test', 'Test'),
      blurb: Bi('', ''),
      price: 10,
      category: ProductCategory.northFace,
      icon: AppIcons.snowflake,
      colors: [],
      stock: 0,
    );
    expect((Cart()..add(soldOut)).isEmpty, isTrue);
  });

  group('message WhatsApp de la commande', () {
    Cart order() => Cart()
      ..add(_find('chaussures-blanc'), 'US 9')
      ..add(_find('doudoune-noire'), 'M');

    test('en français : articles, tailles, total et acompte', () {
      final message = orderMessage(order(), english: false);
      expect(message, startsWith('Bonjour Yanis, je voudrais commander :'));
      expect(
        message,
        contains('1 × Blanc intégral (Air Force 1), taille US 9 : 80 \$'),
      );
      expect(
        message,
        contains('1 × Doudoune noire (The North Face), taille M'),
      );
      expect(message, contains('Total : 160 \$ · acompte 50 % : 80 \$'));
      expect(message, endsWith('Mon adresse de livraison :'));
    });

    test('en anglais', () {
      final message = orderMessage(order(), english: true);
      expect(
        message,
        contains('1 × All white (Air Force 1), size US 9 : \$80'),
      );
      expect(message, contains('Total: \$160 · 50% deposit: \$80'));
      expect(message, endsWith('My delivery address:'));
    });

    test('les montants avec des cents gardent deux décimales', () {
      expect(orderAmount(42.5, english: false), '42,50 \$');
      expect(orderAmount(42.5, english: true), '\$42.50');
    });
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

  test('un article ajouté depuis l’administration apparaît en boutique', () {
    RemoteConfig.instance.setForTest(
      custom: [
        {
          'id': 'casquette-noire',
          'name_fr': 'Casquette noire',
          'name_en': 'Black cap',
          'description_fr': '',
          'description_en': '',
          'price': 35,
          'category': 'other',
          'shoppers': ['men'],
          'sizes': <String>[],
          'photos': ['https://exemple.test/casquette.jpg'],
        },
      ],
    );
    addTearDown(RemoteConfig.instance.setForTest);

    final p = _find('casquette-noire');
    expect(p.price, 35);
    expect(p.category, ProductCategory.other);
    expect(p.photos, ['https://exemple.test/casquette.jpg']);
    expect(catalogFor(Shopper.men), contains(p));
    expect(catalogFor(Shopper.women), isNot(contains(p)));
  });
}

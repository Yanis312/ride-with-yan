import 'package:flutter/widgets.dart';

import '../backend/remote_config.dart';
import '../theme/app_icons.dart';
import 'bilingual.dart';

enum ProductCategory {
  sneakers(Bi('Chaussures', 'Shoes'), AppIcons.sneaker),
  jerseys(Bi('Maillots', 'Jerseys'), AppIcons.tShirt);

  const ProductCategory(this.label, this.icon);

  final Bi label;
  final IconData icon;
}

enum ArtKind { sneaker, jersey }

/// Illustration dessinée (sans logo) affichée tant qu'il n'y a pas de photo.
@immutable
class ProductArt {
  const ProductArt.sneaker({
    required this.base,
    required this.accent,
    this.sole = const Color(0xFFF4F2EC),
  }) : kind = ArtKind.sneaker,
       trim = accent,
       number = null,
       stripes = false;

  const ProductArt.jersey({
    required this.base,
    required this.accent,
    required this.trim,
    this.number,
    this.stripes = false,
  }) : kind = ArtKind.jersey,
       sole = const Color(0x00000000);

  final ArtKind kind;
  final Color base;
  final Color accent;
  final Color trim;
  final Color sole;
  final String? number;
  final bool stripes;
}

/// Article de la boutique à bord.
///
/// Pour ajouter les vraies photos d'un article : les déposer dans
/// `D:/Yan/boutique/<id>/`, lancer `python tools/process_products.py`,
/// puis indiquer leur nombre dans [photoCount].
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.blurb,
    required this.price,
    required this.category,
    required this.icon,
    required this.colors,
    this.brand,
    this.art,
    this.sizes = const {},
    this.stock = 5,
    this.photoCount = 0,
    this.framed = false,
    this.preorder = false,
    this.details = const [],
  });

  final String id;
  final Bi name;
  final Bi blurb;
  final double price;
  final ProductCategory category;
  final IconData icon;

  /// Fond de la vitrine (dégradé), choisi pour faire ressortir l'article.
  final List<Color> colors;
  final String? brand;
  final ProductArt? art;

  /// Taille → quantité en stock. Vide pour un article sans taille.
  final Map<String, int> sizes;

  /// Stock d'un article sans taille.
  final int stock;
  final int photoCount;

  /// Photos de studio gardées entières (.jpg, affichées plein cadre) plutôt
  /// que détourées sur fond transparent (.png).
  final bool framed;

  /// Peut être commandé quand la taille voulue n'est pas à bord : Yanis le
  /// livre ensuite chez le client (voir [preorderNotice]).
  final bool preorder;
  final List<Bi> details;

  bool get hasSizes => sizes.isNotEmpty;

  /// Le même article avec le prix et le stock saisis dans l'administration.
  Product withOverride(Map<String, dynamic> o) => Product(
    id: id,
    name: name,
    blurb: blurb,
    price: _amount(o['price']) ?? price,
    category: category,
    icon: icon,
    colors: colors,
    brand: brand,
    art: art,
    // On ne garde que les tailles connues de l'app.
    sizes: o['sizes'] is Map
        ? {
            for (final size in sizes.keys)
              size: _count((o['sizes'] as Map)[size]) ?? sizes[size]!,
          }
        : sizes,
    stock: _count(o['stock']) ?? stock,
    photoCount: photoCount,
    framed: framed,
    preorder: preorder,
    details: details,
  );

  // Une valeur mal saisie dans la base (texte, négatif) est ignorée plutôt
  // que de faire planter l'affichage.
  static double? _amount(Object? v) =>
      v is num && v.isFinite && v >= 0 ? v.toDouble() : null;
  static int? _count(Object? v) =>
      v is num && v.isFinite && v >= 0 ? v.toInt() : null;

  List<String> get photos => [
    for (var i = 1; i <= photoCount; i++)
      'assets/products/$id-$i.${framed ? 'jpg' : 'png'}',
  ];

  int stockOf([String? size]) {
    if (!hasSizes) return stock;
    if (size == null) return sizes.values.fold(0, (a, b) => a + b);
    return sizes[size] ?? 0;
  }

  List<String> get availableSizes => [
    for (final e in sizes.entries)
      if (e.value > 0) e.key,
  ];
}

/// Mention légale affichée dans la boutique.
const resellerNotice = Bi(
  'Revendeur indépendant · articles neufs. Non affilié à une marque.',
  'Independent reseller · new items. Not affiliated with any brand.',
);

/// Délai de livraison d'un article sur commande, en jours.
const deliveryDays = 30;

const _sneakerDetails = [
  Bi('Neuves, jamais portées', 'New, never worn'),
  Bi(
    'Livrées chez vous en $deliveryDays jours',
    'Delivered to your door in $deliveryDays days',
  ),
  Bi('Vous payez à la réception', 'You pay when it arrives'),
  Bi(
    'Combo : 1 paire + 1 maillot = 120 \$',
    'Combo: 1 pair + 1 jersey = \$120',
  ),
];

const _jerseyDetails = [
  Bi('Neuf, jamais porté', 'New, never worn'),
  Bi(
    'Livré chez vous en $deliveryDays jours',
    'Delivered to your door in $deliveryDays days',
  ),
  Bi('Vous payez à la réception', 'You pay when it arrives'),
  Bi(
    'Combo : 1 paire + 1 maillot = 120 \$',
    'Combo: 1 pair + 1 jersey = \$120',
  ),
];

/// Délai et paiement d'une commande, affichés sous les tailles.
const preorderNotice = Bi(
  'Sur commande : je vous le livre chez vous en $deliveryDays jours, et vous '
      'payez à la réception.',
  'On order: I deliver it to your door in $deliveryDays days, and you pay '
      'when it arrives.',
);

/// Prix d'un combo : une paire de chaussures et un maillot ensemble.
const comboPrice = 120.0;

/// Rappel des prix affiché en haut de la boutique.
const storePitch = Bi(
  'Chaussures 80 \$ · Maillots 50 \$ · Combo paire + maillot 120 \$ · '
      'Livraison chez vous en $deliveryDays jours.',
  'Shoes \$80 · Jerseys \$50 · Pair + jersey combo \$120 · Delivered to '
      'your door in $deliveryDays days.',
);

/// Tailles des maillots. Zéro partout par défaut : tout est sur commande
/// tant que le stock réel n'est pas saisi dans le panneau d'administration.
const _jerseySizes = {'S': 0, 'M': 0, 'L': 0, 'XL': 0};

/// Fond sombre derrière les photos de maillots (texte clair par-dessus).
const _jerseyStage = [Color(0xFF2A2D36), Color(0xFF0E0F13)];

const _shoeBlurb = Bi('Chaussures basses · neuves', 'Low-top shoes · new');

/// Couleurs du fond de studio des photos (texte sombre par-dessus).
const _studio = [Color(0xFFD5D9E0), Color(0xFF9AA2AE)];

/// Tailles des chaussures. Zéro partout : tout est sur commande tant que le
/// stock réel n'est pas saisi dans le panneau d'administration.
const _shoeSizes = {'US 7': 0, 'US 8': 0, 'US 9': 0, 'US 10': 0, 'US 11': 0};

/// Catalogue. Aucun nom de marque : les chaussures sont désignées par leur
/// couleur. Tailles, quantités et prix sont à ajuster au vrai stock.
const baseCatalog = [
  Product(
    id: 'chaussures-blanc',
    name: Bi('Blanc intégral', 'All white'),
    blurb: _shoeBlurb,
    price: 80,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    preorder: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-blanc-noir',
    name: Bi('Blanc et noir', 'White and black'),
    blurb: _shoeBlurb,
    price: 80,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    preorder: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-blanc-noir-or',
    name: Bi('Blanc, noir et or', 'White, black and gold'),
    blurb: _shoeBlurb,
    price: 80,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    preorder: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-blanc-gris',
    name: Bi('Blanc et gris', 'White and grey'),
    blurb: _shoeBlurb,
    price: 80,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    preorder: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-camel',
    name: Bi('Camel', 'Wheat'),
    blurb: _shoeBlurb,
    price: 80,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    preorder: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-blanc-lacets-noirs',
    name: Bi('Blanc, lacets noirs', 'White, black laces'),
    blurb: _shoeBlurb,
    price: 80,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    preorder: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-noir-blanc',
    name: Bi('Noir et blanc', 'Black and white'),
    blurb: _shoeBlurb,
    price: 80,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    preorder: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-noir',
    name: Bi('Noir intégral', 'All black'),
    blurb: _shoeBlurb,
    price: 80,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    preorder: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-blanc-vert',
    name: Bi('Blanc et vert, nœud rouge', 'White and green, red knot'),
    blurb: _shoeBlurb,
    price: 80,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    preorder: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-blanc-rouge',
    name: Bi('Blanc, semelle rouge', 'White, red sole'),
    blurb: _shoeBlurb,
    price: 80,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    preorder: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-creme-menthe',
    name: Bi('Crème et menthe', 'Cream and mint'),
    blurb: _shoeBlurb,
    price: 80,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    preorder: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'maillot-yamal',
    name: Bi('Maillot Yamal', 'Yamal jersey'),
    blurb: Bi(
      'Rayé bleu et grenat · n° 10',
      'Blue and garnet stripes · no. 10',
    ),
    price: 50,
    category: ProductCategory.jerseys,
    icon: AppIcons.tShirt,
    colors: _jerseyStage,
    sizes: _jerseySizes,
    photoCount: 2,
    framed: true,
    preorder: true,
    details: _jerseyDetails,
  ),
  Product(
    id: 'maillot-olise',
    name: Bi('Maillot Olise', 'Olise jersey'),
    blurb: Bi('Rouge · n° 17', 'Red · no. 17'),
    price: 50,
    category: ProductCategory.jerseys,
    icon: AppIcons.tShirt,
    colors: _jerseyStage,
    sizes: _jerseySizes,
    photoCount: 2,
    framed: true,
    preorder: true,
    details: _jerseyDetails,
  ),
  Product(
    id: 'maillot-mbappe',
    name: Bi('Maillot Mbappé', 'Mbappé jersey'),
    blurb: Bi('Blanc, manches longues · n° 10', 'White, long sleeves · no. 10'),
    price: 50,
    category: ProductCategory.jerseys,
    icon: AppIcons.tShirt,
    colors: _jerseyStage,
    sizes: _jerseySizes,
    photoCount: 2,
    framed: true,
    preorder: true,
    details: _jerseyDetails,
  ),
  Product(
    id: 'maillot-bellingham',
    name: Bi('Maillot Bellingham', 'Bellingham jersey'),
    blurb: Bi('Blanc, manches longues · n° 5', 'White, long sleeves · no. 5'),
    price: 50,
    category: ProductCategory.jerseys,
    icon: AppIcons.tShirt,
    colors: _jerseyStage,
    sizes: _jerseySizes,
    photoCount: 2,
    framed: true,
    preorder: true,
    details: _jerseyDetails,
  ),
];

List<Product>? _catalog;
int _catalogRevision = -1;

/// Catalogue affiché : celui de l'app, avec les prix, stocks et articles
/// masqués décidés dans le panneau d'administration.
List<Product> get catalog {
  final remote = RemoteConfig.instance;
  if (_catalog == null || _catalogRevision != remote.revision) {
    _catalogRevision = remote.revision;
    final products = <Product>[];
    for (final p in baseCatalog) {
      final o = remote.productOverride(p.id);
      if (o == null) {
        products.add(p);
      } else if (o['hidden'] != true) {
        products.add(p.withOverride(o));
      }
    }
    _catalog = products;
  }
  return _catalog!;
}

/// Articles mis en avant dans la vitrine de l'écran de veille.
List<Product> get featuredProducts => [
  for (final p in catalog)
    if (p.stockOf() > 0 || p.preorder) p,
];

/// Fenêtre de [size] articles contenant l'article n° [index], chacun avec
/// sa position dans [all] (pour les rangées de miniatures).
Iterable<(int, Product)> productWindow(
  List<Product> all,
  int index,
  int size,
) sync* {
  final start = (index ~/ size) * size;
  for (var i = start; i < all.length && i < start + size; i++) {
    yield (i, all[i]);
  }
}

/// Une ligne du panier : un article, et sa taille s'il en a une.
@immutable
class CartLine {
  const CartLine(this.product, this.size, this.quantity);

  final Product product;
  final String? size;
  final int quantity;

  double get subtotal => product.price * quantity;

  /// Pas à bord dans cette taille : commandé, livré chez le client et payé
  /// à la réception.
  bool get onOrder => product.preorder && product.stockOf(size) == 0;
}

/// Panier du passager en cours. Vidé à chaque fin de session.
class Cart extends ChangeNotifier {
  final Map<(String, String?), int> _lines = {};

  List<CartLine> get lines => [
    for (final e in _lines.entries)
      CartLine(
        catalog.firstWhere(
          (p) => p.id == e.key.$1,
          orElse: () => baseCatalog.firstWhere((p) => p.id == e.key.$1),
        ),
        e.key.$2,
        e.value,
      ),
  ];

  bool get isEmpty => _lines.isEmpty;
  int get count => _lines.values.fold(0, (a, b) => a + b);
  double get total => payNow + payLater;

  int _quantityIn(ProductCategory category) => lines
      .where((l) => l.product.category == category)
      .fold(0, (sum, l) => sum + l.quantity);

  /// Nombre de combos dans le panier : une paire avec un maillot.
  int get combos {
    final shoes = _quantityIn(ProductCategory.sneakers);
    final jerseys = _quantityIn(ProductCategory.jerseys);
    return shoes < jerseys ? shoes : jerseys;
  }

  /// Rabais des combos : chaque paire prise avec un maillot revient à
  /// [comboPrice] au lieu du prix des deux articles séparés.
  double get comboDiscount {
    if (combos == 0) return 0;
    double cheapest(ProductCategory category) => lines
        .where((l) => l.product.category == category)
        .map((l) => l.product.price)
        .reduce((a, b) => a < b ? a : b);
    final saving =
        cheapest(ProductCategory.sneakers) +
        cheapest(ProductCategory.jerseys) -
        comboPrice;
    return saving > 0 ? saving * combos : 0;
  }

  double _subtotal({required bool onOrder}) => lines
      .where((l) => l.onOrder == onOrder)
      .fold(0, (sum, l) => sum + l.subtotal);

  // Le rabais s'applique d'abord à ce qui se paie à la livraison ; s'il
  // dépasse ce montant, le reste est retiré de ce qui se paie tout de suite.
  double get _discountLater {
    final later = _subtotal(onOrder: true);
    return comboDiscount < later ? comboDiscount : later;
  }

  /// Ce qui se paie tout de suite par Interac (articles à bord).
  double get payNow {
    final now = _subtotal(onOrder: false) - (comboDiscount - _discountLater);
    return now > 0 ? now : 0;
  }

  /// Ce qui se paiera à la livraison (articles sur commande).
  double get payLater => _subtotal(onOrder: true) - _discountLater;

  bool get hasOnOrder => lines.any((l) => l.onOrder);

  /// Quantité maximale d'un même article sur commande.
  static const maxOnOrder = 3;

  int quantityOf(Product p, [String? size]) => _lines[(p.id, size)] ?? 0;

  void add(Product p, [String? size]) {
    final q = quantityOf(p, size);
    final stock = p.stockOf(size);
    // À bord : jusqu'au stock. Pas à bord mais commandable : quelques pièces.
    final limit = stock > 0 ? stock : (p.preorder ? maxOnOrder : 0);
    if (q >= limit) return;
    _lines[(p.id, size)] = q + 1;
    notifyListeners();
  }

  void remove(Product p, [String? size]) {
    final q = quantityOf(p, size);
    if (q == 0) return;
    if (q == 1) {
      _lines.remove((p.id, size));
    } else {
      _lines[(p.id, size)] = q - 1;
    }
    notifyListeners();
  }

  void clear() {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }
}

import 'package:flutter/widgets.dart';

import '../theme/app_icons.dart';
import 'bilingual.dart';

enum ProductCategory {
  sneakers(Bi('Chaussures', 'Shoes'), AppIcons.sneaker),
  jerseys(Bi('Maillots', 'Jerseys'), AppIcons.tShirt),
  essentials(Bi('Essentiels', 'Essentials'), AppIcons.batteryCharging);

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
  final List<Bi> details;

  bool get hasSizes => sizes.isNotEmpty;

  /// Article revendu (neuf), par opposition aux essentiels.
  bool get isResale => category != ProductCategory.essentials;

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

const _sneakerDetails = [
  Bi('Neuves, jamais portées', 'New, never worn'),
  Bi('Paiement par virement Interac', 'Pay by Interac e-Transfer'),
  Bi('Remise en main propre, ici même', 'Handed to you right here'),
];

const _jerseyDetails = [
  Bi('Neuf, jamais porté', 'New, never worn'),
  Bi('Paiement par virement Interac', 'Pay by Interac e-Transfer'),
  Bi('Remise en main propre, ici même', 'Handed to you right here'),
];

const _shoeBlurb = Bi('Chaussures basses · neuves', 'Low-top shoes · new');

/// Couleurs du fond de studio des photos (texte sombre par-dessus).
const _studio = [Color(0xFFD5D9E0), Color(0xFF9AA2AE)];

/// Tailles et quantités provisoires : à remplacer par le vrai stock.
const _shoeSizes = {'US 7': 1, 'US 8': 1, 'US 9': 1, 'US 10': 1, 'US 11': 1};

/// Catalogue. Aucun nom de marque : les chaussures sont désignées par leur
/// couleur. Tailles, quantités et prix sont à ajuster au vrai stock.
const catalog = [
  Product(
    id: 'chaussures-blanc',
    name: Bi('Blanc intégral', 'All white'),
    blurb: _shoeBlurb,
    price: 100,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-blanc-noir',
    name: Bi('Blanc et noir', 'White and black'),
    blurb: _shoeBlurb,
    price: 100,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-blanc-noir-or',
    name: Bi('Blanc, noir et or', 'White, black and gold'),
    blurb: _shoeBlurb,
    price: 100,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-blanc-gris',
    name: Bi('Blanc et gris', 'White and grey'),
    blurb: _shoeBlurb,
    price: 100,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-camel',
    name: Bi('Camel', 'Wheat'),
    blurb: _shoeBlurb,
    price: 100,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-blanc-lacets-noirs',
    name: Bi('Blanc, lacets noirs', 'White, black laces'),
    blurb: _shoeBlurb,
    price: 100,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-noir-blanc',
    name: Bi('Noir et blanc', 'Black and white'),
    blurb: _shoeBlurb,
    price: 100,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-noir',
    name: Bi('Noir intégral', 'All black'),
    blurb: _shoeBlurb,
    price: 100,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-blanc-vert',
    name: Bi('Blanc et vert, nœud rouge', 'White and green, red knot'),
    blurb: _shoeBlurb,
    price: 100,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-blanc-rouge',
    name: Bi('Blanc, semelle rouge', 'White, red sole'),
    blurb: _shoeBlurb,
    price: 100,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'chaussures-creme-menthe',
    name: Bi('Crème et menthe', 'Cream and mint'),
    blurb: _shoeBlurb,
    price: 100,
    category: ProductCategory.sneakers,
    icon: AppIcons.sneaker,
    colors: _studio,
    sizes: _shoeSizes,
    photoCount: 1,
    framed: true,
    details: _sneakerDetails,
  ),
  Product(
    id: 'maillot-domicile',
    name: Bi('Maillot domicile', 'Home jersey'),
    blurb: Bi('Saison en cours · coupe stade', 'Current season · stadium fit'),
    price: 90,
    category: ProductCategory.jerseys,
    icon: AppIcons.tShirt,
    colors: [Color(0xFF2A1A3E), Color(0xFF0B0712)],
    art: ProductArt.jersey(
      base: Color(0xFFC8102E),
      accent: Color(0xFF9E0B23),
      trim: Color(0xFFF5F2EA),
      number: '10',
    ),
    sizes: {'S': 1, 'M': 2, 'L': 2, 'XL': 1},
    details: _jerseyDetails,
  ),
  Product(
    id: 'maillot-exterieur',
    name: Bi('Maillot extérieur', 'Away jersey'),
    blurb: Bi('Saison en cours · coupe stade', 'Current season · stadium fit'),
    price: 90,
    category: ProductCategory.jerseys,
    icon: AppIcons.tShirt,
    colors: [Color(0xFFF3E7C9), Color(0xFFC79A3B)],
    art: ProductArt.jersey(
      base: Color(0xFF0B2A5B),
      accent: Color(0xFF1C4A8F),
      trim: Color(0xFFF5B700),
      number: '7',
      stripes: true,
    ),
    sizes: {'S': 0, 'M': 1, 'L': 2, 'XL': 1},
    details: _jerseyDetails,
  ),
  Product(
    id: 'charger',
    name: Bi('Câble de recharge 3 en 1', '3-in-1 charging cable'),
    blurb: Bi(
      'USB-C, Lightning et micro-USB',
      'USB-C, Lightning and micro-USB',
    ),
    price: 12,
    category: ProductCategory.essentials,
    icon: AppIcons.batteryCharging,
    colors: [Color(0xFF5B8CFF), Color(0xFF1B2A6B)],
  ),
  Product(
    id: 'earbuds',
    name: Bi('Écouteurs sans fil', 'Wireless earbuds'),
    blurb: Bi(
      'Boîtier de recharge, 20 h d’autonomie',
      'Charging case, 20 h battery',
    ),
    price: 29,
    category: ProductCategory.essentials,
    icon: AppIcons.headphones,
    colors: [Color(0xFFB57BFF), Color(0xFF3B1A6B)],
    stock: 3,
  ),
  Product(
    id: 'water',
    name: Bi('Eau de source', 'Spring water'),
    blurb: Bi('Bouteille fraîche 500 ml', 'Cold 500 ml bottle'),
    price: 2,
    category: ProductCategory.essentials,
    icon: AppIcons.drop,
    colors: [Color(0xFF3AA6FF), Color(0xFF0B3A6E)],
    stock: 12,
  ),
  Product(
    id: 'umbrella',
    name: Bi('Parapluie compact', 'Compact umbrella'),
    blurb: Bi('Pour les jours de pluie à Montréal', 'For rainy Montréal days'),
    price: 15,
    category: ProductCategory.essentials,
    icon: AppIcons.umbrella,
    colors: [Color(0xFF18C2C9), Color(0xFF0E4E52)],
    stock: 2,
  ),
];

/// Articles mis en avant dans la vitrine de l'écran de veille.
List<Product> get featuredProducts => [
  for (final p in catalog)
    if (p.isResale && p.stockOf() > 0) p,
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
}

/// Panier du passager en cours. Vidé à chaque fin de session.
class Cart extends ChangeNotifier {
  final Map<(String, String?), int> _lines = {};

  List<CartLine> get lines => [
    for (final e in _lines.entries)
      CartLine(catalog.firstWhere((p) => p.id == e.key.$1), e.key.$2, e.value),
  ];

  bool get isEmpty => _lines.isEmpty;
  int get count => _lines.values.fold(0, (a, b) => a + b);
  double get total => lines.fold(0, (sum, l) => sum + l.subtotal);

  int quantityOf(Product p, [String? size]) => _lines[(p.id, size)] ?? 0;

  void add(Product p, [String? size]) {
    final q = quantityOf(p, size);
    if (q >= p.stockOf(size)) return;
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

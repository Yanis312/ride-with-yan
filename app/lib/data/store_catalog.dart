import 'package:flutter/widgets.dart';

import '../backend/remote_config.dart';
import '../theme/app_icons.dart';
import 'bilingual.dart';

/// Les deux boutiques : chaque article est rangé chez les hommes, chez les
/// femmes, ou dans les deux.
enum Shopper {
  men(Bi('Hommes', 'Men'), AppIcons.users),
  women(Bi('Femmes', 'Women'), AppIcons.sparkle);

  const Shopper(this.label, this.icon);

  final Bi label;
  final IconData icon;
}

const _everyone = {Shopper.men, Shopper.women};

/// Les sections de la boutique, par modèle.
enum ProductCategory {
  airForce1(Bi('Air Force 1', 'Air Force 1'), AppIcons.sneaker),
  dunk(Bi('Dunk', 'Dunk'), AppIcons.sneaker),
  vans(Bi('Vans', 'Vans'), AppIcons.sneaker),
  northFace(Bi('The North Face', 'The North Face'), AppIcons.snowflake),
  bags(Bi('Sacs', 'Bags'), AppIcons.handbag);

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
    this.shoppers = _everyone,
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

  /// Boutiques où l'article apparaît (hommes, femmes ou les deux).
  final Set<Shopper> shoppers;
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
  /// livre ensuite chez le client (voir [orderNotice]).
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
    shoppers: shoppers,
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

/// Délai de livraison, chez le client.
const deliveryWindow = Bi('20 à 30 jours', '20 to 30 days');

/// Part du prix payée par Interac à la commande ; le reste à la livraison.
const depositShare = 0.5;

/// Comment se passe une commande, rappelé sur chaque fiche article.
const _howToOrder = [
  Bi(
    'Livré chez vous en 20 à 30 jours',
    'Delivered to your door in 20 to 30 days',
  ),
  Bi(
    'Acompte de 50 % par Interac, le reste à la livraison',
    '50% deposit by Interac, the rest on delivery',
  ),
  Bi('Pas satisfait : remboursé', 'Not satisfied: refunded'),
];

const _sneakerDetails = [
  Bi('Neuves, jamais portées', 'New, never worn'),
  ..._howToOrder,
];

const _bagDetails = [
  Bi('Neuf, avec sa pochette assortie', 'New, with its matching pouch'),
  ..._howToOrder,
];

const _jacketDetails = [
  Bi('Neuve, jamais portée', 'New, never worn'),
  ..._howToOrder,
];

/// Délai et paiement d'une commande, affichés sous les tailles.
const orderNotice = Bi(
  'Livré chez vous en 20 à 30 jours · 50 % à la commande, le reste à la '
      'livraison.',
  'Delivered to your door in 20 to 30 days · 50% when you order, the rest '
      'on delivery.',
);

/// Rappel des prix affiché en haut de la boutique.
const storePitch = Bi(
  'À partir de 80 \$ · Livré chez vous en 20 à 30 jours.',
  'From \$80 · Delivered to your door in 20 to 30 days.',
);

/// Tailles des doudounes, sur commande comme le reste.
const _jacketSizes = {'XS': 0, 'S': 0, 'M': 0, 'L': 0, 'XL': 0, 'XXL': 0};

const _shoeBlurb = Bi('Chaussures basses · neuves', 'Low-top shoes · new');
const _jacketBlurb = Bi('Doudoune · neuve', 'Puffer jacket · new');
const _vestBlurb = Bi('Doudoune sans manches · neuve', 'Puffer vest · new');

/// Couleurs du fond de studio des photos (texte sombre par-dessus).
const _studio = [Color(0xFFD5D9E0), Color(0xFF9AA2AE)];

/// Tailles des chaussures. Zéro partout : tout est sur commande tant que le
/// stock réel n'est pas saisi dans le panneau d'administration.
const _shoeSizes = {
  'US 5': 0,
  'US 6': 0,
  'US 7': 0,
  'US 8': 0,
  'US 9': 0,
  'US 10': 0,
  'US 11': 0,
  'US 12': 0,
};
const _womenShoeSizes = {
  'US 5': 0,
  'US 6': 0,
  'US 7': 0,
  'US 8': 0,
  'US 9': 0,
  'US 10': 0,
};
const _menShoeSizes = {
  'US 7': 0,
  'US 8': 0,
  'US 9': 0,
  'US 10': 0,
  'US 11': 0,
  'US 12': 0,
};

/// Une paire de la boutique : 80 $, sur commande, une photo cadrée.
Product _shoe(
  ProductCategory category,
  String id,
  Bi name, {
  Set<Shopper> shoppers = _everyone,
  int photos = 1,
}) => Product(
  id: id,
  name: name,
  blurb: _shoeBlurb,
  price: 80,
  category: category,
  icon: AppIcons.sneaker,
  colors: _studio,
  shoppers: shoppers,
  sizes: shoppers.length == 2
      ? _shoeSizes
      : (shoppers.contains(Shopper.women) ? _womenShoeSizes : _menShoeSizes),
  photoCount: photos,
  framed: true,
  preorder: true,
  details: _sneakerDetails,
);

/// Une doudoune : 80 $, pour hommes et femmes sauf indication contraire.
Product _jacket(
  String id,
  Bi name, {
  Set<Shopper> shoppers = _everyone,
  int photos = 1,
  Bi blurb = _jacketBlurb,
}) => Product(
  id: id,
  name: name,
  blurb: blurb,
  price: 80,
  category: ProductCategory.northFace,
  icon: AppIcons.snowflake,
  colors: _studio,
  shoppers: shoppers,
  sizes: _jacketSizes,
  photoCount: photos,
  framed: true,
  preorder: true,
  details: _jacketDetails,
);

/// Un sac cabas à carreaux pour femmes : 100 \$, sur commande, une photo.
Product _bag(String id, Bi name) => Product(
  id: id,
  name: name,
  blurb: const Bi('Sac cabas à carreaux · neuf', 'Check tote bag · new'),
  price: 100,
  category: ProductCategory.bags,
  icon: AppIcons.handbag,
  colors: _studio,
  shoppers: const {Shopper.women},
  stock: 0,
  photoCount: 1,
  framed: true,
  preorder: true,
  details: _bagDetails,
);

/// Catalogue, rangé par modèle ; chaque article est désigné par sa couleur. Tailles, quantités et prix sont à ajuster au vrai stock.
final baseCatalog = <Product>[
  // Les nouveautés d'abord, avec leurs vraies photos.
  // Air Force 1
  _shoe(
    ProductCategory.airForce1,
    'chaussures-rose-bordeaux',
    Bi('Rose et bordeaux vernis', 'Pink and burgundy patent'),
    shoppers: {Shopper.women},
    photos: 2,
  ),
  _shoe(
    ProductCategory.airForce1,
    'chaussures-vache',
    Bi('Crème, motif vache', 'Cream, cow print'),
    shoppers: {Shopper.women},
  ),
  _shoe(
    ProductCategory.airForce1,
    'chaussures-bleu-vernis',
    Bi('Bleu vernis', 'Blue patent'),
    shoppers: {Shopper.men},
  ),
  _shoe(
    ProductCategory.airForce1,
    'chaussures-jaune-vert',
    Bi('Jaune et vert vernis', 'Yellow and green patent'),
    shoppers: {Shopper.men},
  ),
  _shoe(
    ProductCategory.airForce1,
    'chaussures-bordeaux-orange',
    Bi('Bordeaux et orange', 'Burgundy and orange'),
    shoppers: {Shopper.men},
  ),
  _shoe(
    ProductCategory.airForce1,
    'chaussures-vert-jaune-rouge',
    Bi('Vert, jaune et rouge', 'Green, yellow and red'),
    shoppers: {Shopper.men},
  ),
  _shoe(
    ProductCategory.airForce1,
    'chaussures-rouge',
    Bi('Rouge intégral', 'All red'),
  ),
  _shoe(
    ProductCategory.airForce1,
    'chaussures-blanc',
    Bi('Blanc intégral', 'All white'),
  ),
  _shoe(
    ProductCategory.airForce1,
    'chaussures-blanc-noir',
    Bi('Blanc, virgule noire', 'White, black swoosh'),
  ),
  _shoe(
    ProductCategory.airForce1,
    'chaussures-blanc-semelle-noire',
    Bi('Blanc, semelle et lacets noirs', 'White, black sole and laces'),
  ),
  _shoe(
    ProductCategory.airForce1,
    'chaussures-noir',
    Bi('Noir intégral', 'All black'),
  ),
  // Dunk
  _shoe(
    ProductCategory.dunk,
    'chaussures-rose-bonbon',
    Bi('Rose bonbon', 'Candy pink'),
    shoppers: {Shopper.women},
    photos: 2,
  ),
  _shoe(
    ProductCategory.dunk,
    'chaussures-fuchsia-blanc',
    Bi('Fuchsia et blanc', 'Fuchsia and white'),
    shoppers: {Shopper.women},
  ),
  _shoe(
    ProductCategory.dunk,
    'chaussures-bleu-ciel',
    Bi('Bleu ciel et blanc', 'Sky blue and white'),
    shoppers: {Shopper.men},
  ),
  _shoe(
    ProductCategory.dunk,
    'chaussures-rouge-jaune-bleu',
    Bi('Rouge, jaune et bleu', 'Red, yellow and blue'),
    shoppers: {Shopper.men},
  ),
  _shoe(
    ProductCategory.dunk,
    'chaussures-moka',
    Bi('Moka et blanc', 'Mocha and white'),
  ),
  _shoe(
    ProductCategory.dunk,
    'chaussures-voile',
    Bi('Voile et gris clair', 'Sail and light grey'),
  ),
  // Vans
  _shoe(
    ProductCategory.vans,
    'chaussures-cloutees-rose',
    Bi('Rose et noir à clous', 'Pink and black, studded'),
    shoppers: {Shopper.women},
  ),
  _shoe(
    ProductCategory.vans,
    'chaussures-daim-rose',
    Bi('Daim rose', 'Pink suede'),
    shoppers: {Shopper.women},
  ),
  _shoe(
    ProductCategory.vans,
    'chaussures-cloutees-blanc',
    Bi('Blanc à clous', 'White, studded'),
  ),
  _shoe(
    ProductCategory.vans,
    'chaussures-cloutees-bordeaux',
    Bi('Bordeaux et noir à clous', 'Burgundy and black, studded'),
  ),
  _shoe(
    ProductCategory.vans,
    'chaussures-patchwork',
    Bi('Patchwork et badges', 'Patchwork with pins'),
  ),
  // The North Face, toutes couleurs, pour tous
  _jacket('doudoune-noire', Bi('Doudoune noire', 'Black puffer'), photos: 3),
  _jacket('doudoune-bleue', Bi('Doudoune bleue', 'Blue puffer'), photos: 2),
  _jacket('doudoune-orange', Bi('Doudoune orange', 'Orange puffer')),
  _jacket('doudoune-jaune', Bi('Doudoune jaune', 'Yellow puffer')),
  _jacket('doudoune-verte', Bi('Doudoune verte', 'Green puffer')),
  _jacket(
    'doudoune-blanche-courte',
    Bi('Doudoune blanche courte', 'White cropped puffer'),
    shoppers: {Shopper.women},
  ),
  _jacket(
    'veste-sans-manches-noire',
    Bi('Sans manches noire', 'Black vest'),
    blurb: _vestBlurb,
  ),
  // Sacs, pour femmes
  _bag(
    'sac-carreaux-blanc-rose',
    Bi(
      'Cabas à carreaux blanc, intérieur rose',
      'White check tote, pink lining',
    ),
  ),
  _bag(
    'sac-carreaux-blanc-beige',
    Bi(
      'Cabas à carreaux blanc, intérieur beige',
      'White check tote, beige lining',
    ),
  ),
  _bag(
    'sac-carreaux-marron-rouge',
    Bi(
      'Cabas à carreaux marron, intérieur rouge',
      'Brown check tote, red lining',
    ),
  ),
  _bag(
    'sac-carreaux-marron-rose',
    Bi(
      'Cabas à carreaux marron, intérieur rose',
      'Brown check tote, pink lining',
    ),
  ),
  _bag(
    'sac-carreaux-marron-beige',
    Bi(
      'Cabas à carreaux marron, intérieur beige',
      'Brown check tote, beige lining',
    ),
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

/// Catalogue d'une des deux boutiques : ce qui est propre à ce rayon
/// d'abord (le rose chez les femmes, le bleu chez les hommes), puis ce qui
/// va à tout le monde.
List<Product> catalogFor(Shopper shopper) => _shelf(catalog, shopper);

List<Product> _shelf(List<Product> products, Shopper shopper) => [
  for (final p in products)
    if (p.shoppers.length == 1 && p.shoppers.contains(shopper)) p,
  for (final p in products)
    if (p.shoppers.length > 1 && p.shoppers.contains(shopper)) p,
];

/// Vitrine d'une boutique sur l'écran de veille : les catégories alternent
/// (Air Force 1, Dunk, Vans, The North Face…), pour montrer tout l'éventail
/// même quand la diapo n'a le temps de montrer que [limit] articles.
List<Product> featuredFor(Shopper shopper, {int limit = 24}) {
  final queues = {
    for (final c in ProductCategory.values)
      c: [
        for (final p in _shelf(featuredProducts, shopper))
          if (p.category == c) p,
      ],
  };
  final mixed = <Product>[];
  while (mixed.length < limit && queues.values.any((q) => q.isNotEmpty)) {
    for (final q in queues.values) {
      if (q.isNotEmpty && mixed.length < limit) mixed.add(q.removeAt(0));
    }
  }
  return mixed;
}

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

  /// Pas à bord dans cette taille : commandé, puis livré chez le client.
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
  double get subtotal => lines.fold(0, (sum, l) => sum + l.subtotal);

  double get total => subtotal;

  /// Acompte versé par Interac à la commande.
  double get deposit => total * depositShare;

  /// Reste payé à la livraison, si le client est satisfait.
  double get balance => total - deposit;

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

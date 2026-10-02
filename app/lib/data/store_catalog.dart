import 'package:flutter/widgets.dart';

import '../theme/app_icons.dart';
import 'bilingual.dart';

/// Article de la boutique à bord. Catalogue de démonstration : il sera
/// remplacé par les données de l'API .NET (Supabase) gérées depuis l'admin.
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.blurb,
    required this.price,
    required this.icon,
    required this.colors,
    this.stock = 5,
  });

  final String id;
  final Bi name;
  final Bi blurb;
  final double price;
  final IconData icon;
  final List<Color> colors;
  final int stock;
}

const catalog = [
  Product(
    id: 'charger',
    name: Bi('Câble de recharge 3 en 1', '3-in-1 charging cable'),
    blurb: Bi(
      'USB-C, Lightning et micro-USB',
      'USB-C, Lightning and micro-USB',
    ),
    price: 12,
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
    icon: AppIcons.headphones,
    colors: [Color(0xFFB57BFF), Color(0xFF3B1A6B)],
    stock: 3,
  ),
  Product(
    id: 'water',
    name: Bi('Eau de source', 'Spring water'),
    blurb: Bi('Bouteille fraîche 500 ml', 'Cold 500 ml bottle'),
    price: 2,
    icon: AppIcons.drop,
    colors: [Color(0xFF3AA6FF), Color(0xFF0B3A6E)],
    stock: 12,
  ),
  Product(
    id: 'snack',
    name: Bi('Biscuits artisanaux', 'Artisan cookies'),
    blurb: Bi('Chocolat et sel de mer', 'Chocolate and sea salt'),
    price: 4,
    icon: AppIcons.cookie,
    colors: [Color(0xFFE8A23A), Color(0xFF6B3A0B)],
    stock: 8,
  ),
  Product(
    id: 'coffee',
    name: Bi('Café froid', 'Cold brew'),
    blurb: Bi('Canette 250 ml', '250 ml can'),
    price: 4.5,
    icon: AppIcons.coffee,
    colors: [Color(0xFFC08457), Color(0xFF3A2010)],
  ),
  Product(
    id: 'umbrella',
    name: Bi('Parapluie compact', 'Compact umbrella'),
    blurb: Bi('Pour les jours de pluie à Montréal', 'For rainy Montréal days'),
    price: 15,
    icon: AppIcons.umbrella,
    colors: [Color(0xFF18C2C9), Color(0xFF0E4E52)],
    stock: 2,
  ),
];

/// Panier du passager en cours. Vidé à chaque fin de session.
class Cart extends ChangeNotifier {
  final Map<String, int> _lines = {};

  Map<String, int> get lines => Map.unmodifiable(_lines);
  bool get isEmpty => _lines.isEmpty;
  int get count => _lines.values.fold(0, (a, b) => a + b);

  double get total => _lines.entries.fold(
    0,
    (sum, e) => sum + catalog.firstWhere((p) => p.id == e.key).price * e.value,
  );

  int quantityOf(Product p) => _lines[p.id] ?? 0;

  void add(Product p) {
    final q = quantityOf(p);
    if (q >= p.stock) return;
    _lines[p.id] = q + 1;
    notifyListeners();
  }

  void remove(Product p) {
    final q = quantityOf(p);
    if (q <= 1) {
      _lines.remove(p.id);
    } else {
      _lines[p.id] = q - 1;
    }
    notifyListeners();
  }

  void clear() {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }
}

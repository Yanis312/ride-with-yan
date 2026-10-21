import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../backend/backend.dart';
import '../config.dart';
import '../theme/app_icons.dart';
import 'bilingual.dart';

/// Commerce partenaire affiché dans la section publicité.
/// [example] : fiche de démonstration, clairement marquée comme telle,
/// affichée tant qu'aucun vrai partenaire n'est saisi dans l'admin.
@immutable
class Advertiser {
  const Advertiser({
    this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.phone,
    required this.hours,
    required this.location,
    required this.icon,
    required this.colors,
    this.instagram,
    this.tiktok,
    this.facebook,
    this.photo,
    this.photoUrl,
    this.website,
    this.offer,
    this.example = false,
  });

  /// Fiche saisie dans l'admin (ligne de la table `advertisers`).
  factory Advertiser.fromRow(Map<String, dynamic> r) {
    String text(String key) => '${r[key] ?? ''}'.trim();
    String? link(String key) {
      final v = text(key);
      return v.startsWith('https://') ? v : null;
    }

    Bi bi(String key) {
      final fr = text('${key}_fr');
      final en = text('${key}_en');
      return Bi(fr.isEmpty ? en : fr, en.isEmpty ? fr : en);
    }

    final color = int.tryParse(text('color'), radix: 16) ?? 0xE8A23A;
    final base = Color(0xFF000000 | color);
    final offer = bi('offer');
    return Advertiser(
      id: text('id'),
      name: text('name'),
      category: bi('category'),
      description: bi('description'),
      address: text('address'),
      phone: text('phone'),
      hours: bi('hours'),
      location: LatLng(
        (r['lat'] as num?)?.toDouble() ?? 45.4215,
        (r['lng'] as num?)?.toDouble() ?? -75.6972,
      ),
      icon: AppIcons.storefront,
      colors: [base, Color.lerp(base, const Color(0xFF000000), 0.7)!],
      photoUrl: link('photo_url'),
      website: link('website'),
      instagram: link('instagram'),
      tiktok: link('tiktok'),
      facebook: link('facebook'),
      offer: offer.fr.isEmpty ? null : offer,
    );
  }

  /// Identifiant dans la base ; `null` pour les fiches d'exemple.
  final String? id;

  final String name;
  final Bi category;
  final Bi description;
  final String address;
  final String phone;
  final Bi hours;
  final LatLng location;
  final IconData icon;
  final List<Color> colors;
  final String? instagram;
  final String? tiktok;
  final String? facebook;

  /// Photo du commerce (asset). Sans photo, un visuel dégradé est utilisé.
  final String? photo;

  /// Photo en ligne, saisie dans l'admin.
  final String? photoUrl;
  final String? website;

  /// Offre réservée aux passagers (ex. « −10 % avec Ride with Yan »).
  final Bi? offer;
  final bool example;

  ImageProvider? get image => photoUrl != null
      ? NetworkImage(photoUrl!)
      : (photo != null ? AssetImage(photo!) : null);

  /// Adresse mise dans un QR code : pour un vrai partenaire, elle passe par
  /// la fonction `go`, qui compte le scan avant de rediriger.
  String qrLink(String target, String url) => id == null
      ? url
      : '${AppConfig.supabaseUrl}/functions/v1/go?ad=$id&to=$target';
}

/// Partenaires saisis dans l'admin ; les exemples tant qu'il n'y en a aucun.
class AdvertiserStore extends ChangeNotifier {
  AdvertiserStore._();

  static final instance = AdvertiserStore._();

  List<Advertiser> _real = const [];

  List<Advertiser> get list => _real.isEmpty ? exampleAdvertisers : _real;

  Future<void> load() async {
    if (!Backend.enabled) return;
    try {
      final rows = await Backend.select(
        'advertisers',
        order: 'sort.asc,name.asc',
      );
      _real = [
        for (final r in rows)
          if (r['active'] != false) Advertiser.fromRow(r),
      ];
      notifyListeners();
    } catch (_) {
      // Pas de réseau : on garde ce qu'on avait (ou les exemples).
    }
  }

  @visibleForTesting
  void setForTest(List<Advertiser> real) {
    _real = real;
    notifyListeners();
  }
}

const exampleAdvertisers = [
  Advertiser(
    name: 'Sushi Kumo',
    category: Bi('Restaurant japonais', 'Japanese restaurant'),
    description: Bi(
      'Sushis faits minute, bols poké et ramen maison. À deux pas du centre-ville, ouvert tard le soir.',
      'Made-to-order sushi, poke bowls and house ramen. Steps from downtown, open late.',
    ),
    address: '123, rue Exemple, Ottawa',
    phone: '613 000-0000',
    hours: Bi('Tous les jours, 11 h à 23 h', 'Every day, 11 am to 11 pm'),
    location: LatLng(45.4250, -75.6950),
    icon: AppIcons.storefront,
    colors: [Color(0xFFFF6B6B), Color(0xFF7A1F3D)],
    photo: 'assets/photos/ad-sushi.jpg',
    instagram: 'https://www.instagram.com/',
    tiktok: 'https://www.tiktok.com/',
    facebook: 'https://www.facebook.com/',
    example: true,
  ),
  Advertiser(
    name: 'Café Atlas',
    category: Bi('Café et pâtisserie', 'Coffee and pastries'),
    description: Bi(
      'Café de spécialité torréfié sur place, croissants au beurre et coin travail tranquille.',
      'Specialty coffee roasted in house, butter croissants and a quiet work corner.',
    ),
    address: '456, boulevard Démo, Gatineau',
    phone: '819 000-0001',
    hours: Bi('Lun. à sam., 7 h à 18 h', 'Mon. to Sat., 7 am to 6 pm'),
    location: LatLng(45.4290, -75.7140),
    icon: AppIcons.coffee,
    colors: [Color(0xFFE8A23A), Color(0xFF4A2A0B)],
    photo: 'assets/photos/ad-cafe.jpg',
    instagram: 'https://www.instagram.com/',
    facebook: 'https://www.facebook.com/',
    example: true,
  ),
];

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_icons.dart';
import 'bilingual.dart';

/// Commerce partenaire affiché dans la section publicité.
/// [example] : fiche de démonstration, clairement marquée comme telle,
/// à remplacer par les vrais partenaires (plus tard depuis l'admin).
@immutable
class Advertiser {
  const Advertiser({
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
    this.example = false,
  });

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
  final bool example;
}

const advertisers = [
  Advertiser(
    name: 'Sushi Kumo',
    category: Bi('Restaurant japonais', 'Japanese restaurant'),
    description: Bi(
      'Sushis faits minute, bols poké et ramen maison. À deux pas du centre-ville, ouvert tard le soir.',
      'Made-to-order sushi, poke bowls and house ramen. Steps from downtown, open late.',
    ),
    address: '123, rue Exemple, Montréal',
    phone: '514 000-0000',
    hours: Bi('Tous les jours, 11 h à 23 h', 'Every day, 11 am to 11 pm'),
    location: LatLng(45.5048, -73.5698),
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
    address: '456, avenue Démo, Montréal',
    phone: '514 000-0001',
    hours: Bi('Lun. à sam., 7 h à 18 h', 'Mon. to Sat., 7 am to 6 pm'),
    location: LatLng(45.5225, -73.5810),
    icon: AppIcons.coffee,
    colors: [Color(0xFFE8A23A), Color(0xFF4A2A0B)],
    photo: 'assets/photos/ad-cafe.jpg',
    instagram: 'https://www.instagram.com/',
    facebook: 'https://www.facebook.com/',
    example: true,
  ),
];

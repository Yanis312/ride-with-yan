import 'package:flutter/widgets.dart';

import '../theme/app_icons.dart';
import 'bilingual.dart';

enum ShowcaseFrame { browser, phone, dashboard }

/// Une réalisation de démonstration montrée dans la section Collaborations.
/// Images et vidéos à placer dans assets/showcase/ puis à déclarer ici.
@immutable
class Showcase {
  const Showcase({
    required this.title,
    required this.kind,
    required this.image,
    required this.frame,
    required this.accent,
    this.video,
  });

  final String title;
  final Bi kind;
  final String image;
  final String? video;
  final ShowcaseFrame frame;
  final Color accent;
}

/// Un onglet de la section : un type de service et ses démos.
@immutable
class ServiceTab {
  const ServiceTab({
    required this.label,
    required this.icon,
    required this.headline,
    required this.pitch,
    required this.points,
    required this.showcases,
    this.frame = ShowcaseFrame.browser,
  });

  final Bi label;
  final IconData icon;
  final Bi headline;
  final Bi pitch;
  final List<Bi> points;
  final List<Showcase> showcases;

  /// Cadre utilisé tant qu'aucune démo n'est fournie.
  final ShowcaseFrame frame;
}

const serviceTabs = [
  ServiceTab(
    label: Bi('Sites web', 'Websites'),
    icon: AppIcons.browser,
    headline: Bi('Un site qui donne envie.', 'A website people remember.'),
    pitch: Bi(
      'Vitrine, réservation, boutique en ligne : un design sur mesure, rapide sur téléphone et bien référencé sur Google.',
      'Showcase, booking or online store: a custom design that is fast on phones and ranks well on Google.',
    ),
    points: [
      Bi(
        'Design unique, pas de modèle générique',
        'Unique design, no generic template',
      ),
      Bi('Réservation et paiement en ligne', 'Online booking and payments'),
      Bi('Bilingue français et anglais', 'Bilingual French and English'),
      Bi('Mise en ligne et hébergement inclus', 'Launch and hosting included'),
    ],
    showcases: [
      Showcase(
        title: 'Maison Mokka',
        kind: Bi('Café et boulangerie', 'Coffee shop and bakery'),
        image: 'assets/showcase/mokka.jpg',
        video: 'assets/showcase/mokka.mp4',
        frame: ShowcaseFrame.browser,
        accent: Color(0xFFC98A4B),
      ),
      Showcase(
        title: 'Atelier Nord',
        kind: Bi('Boutique de mode', 'Fashion boutique'),
        image: 'assets/showcase/atelier-nord.jpg',
        video: 'assets/showcase/atelier-nord.mp4',
        frame: ShowcaseFrame.browser,
        accent: Color(0xFFD2552B),
      ),
      Showcase(
        title: 'Noir Tailor',
        kind: Bi('Prêt-à-porter de luxe', 'Luxury menswear'),
        image: 'assets/showcase/noir-tailor.jpg',
        video: 'assets/showcase/noir-tailor.mp4',
        frame: ShowcaseFrame.browser,
        accent: Color(0xFFC9A36A),
      ),
      Showcase(
        title: 'VLT Active',
        kind: Bi('Vêtements de sport', 'Sportswear'),
        image: 'assets/showcase/vlt-active.jpg',
        video: 'assets/showcase/vlt-active.mp4',
        frame: ShowcaseFrame.browser,
        accent: Color(0xFFD4FF3A),
      ),
    ],
  ),
  ServiceTab(
    label: Bi('Applications', 'Mobile apps'),
    icon: AppIcons.deviceMobile,
    frame: ShowcaseFrame.phone,
    headline: Bi('Votre app, dans leur poche.', 'Your app, in their pocket.'),
    pitch: Bi(
      'Applications Android et iPhone avec un seul code (Flutter), comme celle que vous utilisez en ce moment.',
      'Android and iPhone apps from a single codebase (Flutter), just like the one you are using right now.',
    ),
    points: [
      Bi('Android et iPhone en même temps', 'Android and iPhone at once'),
      Bi('Commandes, rendez-vous, fidélité', 'Orders, bookings, loyalty'),
      Bi('Notifications et paiements', 'Notifications and payments'),
      Bi('Publication sur les stores', 'Store publishing'),
    ],
    showcases: [
      Showcase(
        title: 'Lumière',
        kind: Bi('App de boutique de mode', 'Fashion store app'),
        image: 'assets/showcase/app-boutique.jpg',
        frame: ShowcaseFrame.phone,
        accent: Color(0xFFC9A36A),
      ),
      Showcase(
        title: 'VLT Run',
        kind: Bi('App de course à pied', 'Running app'),
        image: 'assets/showcase/app-sport.jpg',
        frame: ShowcaseFrame.phone,
        accent: Color(0xFFD4FF3A),
      ),
    ],
  ),
  ServiceTab(
    label: Bi('Automatisation et IA', 'Automation and AI'),
    icon: AppIcons.robot,
    frame: ShowcaseFrame.dashboard,
    headline: Bi(
      'Moins de tâches, plus de clients.',
      'Less busywork, more clients.',
    ),
    pitch: Bi(
      'Factures, courriels, relances, réponses aux clients : je connecte vos outils et j’ajoute un assistant IA qui travaille pour vous.',
      'Invoices, emails, follow-ups, customer replies: I connect your tools and add an AI assistant that works for you.',
    ),
    points: [
      Bi('Shopify, Stripe, Google, CRM', 'Shopify, Stripe, Google, CRM'),
      Bi('Chatbot qui répond 24 h sur 24', 'Chatbot answering 24/7'),
      Bi('Rapports automatiques chaque matin', 'Automatic morning reports'),
      Bi('Solutions ERP sur mesure', 'Custom ERP solutions'),
    ],
    showcases: [
      Showcase(
        title: 'Flux',
        kind: Bi('Commandes automatisées', 'Automated orders'),
        image: 'assets/showcase/dashboard-commandes.jpg',
        frame: ShowcaseFrame.dashboard,
        accent: Color(0xFF7EE3A8),
      ),
      Showcase(
        title: 'Pulse',
        kind: Bi('Tableau de bord des ventes', 'Sales dashboard'),
        image: 'assets/showcase/dashboard-ventes.jpg',
        frame: ShowcaseFrame.dashboard,
        accent: Color(0xFF1F4DFF),
      ),
    ],
  ),
];

import 'package:flutter/widgets.dart';

import '../theme/app_icons.dart';
import 'bilingual.dart';

enum ShowcaseFrame { browser, phone, dashboard }

/// Une réalisation de démonstration montrée dans la section Collaborations.
/// Les démos sont dans /portfolio (HTML) et capturées dans assets/portfolio.
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
  });

  final Bi label;
  final IconData icon;
  final Bi headline;
  final Bi pitch;
  final List<Bi> points;
  final List<Showcase> showcases;
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
        title: 'Maison Safran',
        kind: Bi('Restaurant gastronomique', 'Fine dining restaurant'),
        image: 'assets/portfolio/restaurant.jpg',
        video: 'assets/portfolio/restaurant.mp4',
        frame: ShowcaseFrame.browser,
        accent: Color(0xFFE8A23A),
      ),
      Showcase(
        title: 'Atelier Lumen',
        kind: Bi('Spa et soins', 'Spa and wellness'),
        image: 'assets/portfolio/spa.jpg',
        video: 'assets/portfolio/spa.mp4',
        frame: ShowcaseFrame.browser,
        accent: Color(0xFFE7B7A8),
      ),
      Showcase(
        title: 'Nordhaus',
        kind: Bi('Agence immobilière', 'Real estate agency'),
        image: 'assets/portfolio/immobilier.jpg',
        video: 'assets/portfolio/immobilier.mp4',
        frame: ShowcaseFrame.browser,
        accent: Color(0xFF1F4DFF),
      ),
      Showcase(
        title: 'Pulse',
        kind: Bi('Startup logicielle', 'Software startup'),
        image: 'assets/portfolio/saas.jpg',
        video: 'assets/portfolio/saas.mp4',
        frame: ShowcaseFrame.browser,
        accent: Color(0xFFC6FF3D),
      ),
    ],
  ),
  ServiceTab(
    label: Bi('Applications', 'Mobile apps'),
    icon: AppIcons.deviceMobile,
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
        title: 'Croque',
        kind: Bi('Livraison de repas', 'Food delivery'),
        image: 'assets/portfolio/app-livraison.jpg',
        frame: ShowcaseFrame.phone,
        accent: Color(0xFFFF6B3D),
      ),
      Showcase(
        title: 'Stride',
        kind: Bi('Suivi sportif', 'Fitness tracking'),
        image: 'assets/portfolio/app-fitness.jpg',
        frame: ShowcaseFrame.phone,
        accent: Color(0xFF3EE6B4),
      ),
    ],
  ),
  ServiceTab(
    label: Bi('Automatisation et IA', 'Automation and AI'),
    icon: AppIcons.robot,
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
        image: 'assets/portfolio/automatisation.jpg',
        frame: ShowcaseFrame.dashboard,
        accent: Color(0xFF7EE3A8),
      ),
    ],
  ),
];

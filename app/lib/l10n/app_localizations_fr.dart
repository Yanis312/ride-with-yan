// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get sectionAbout => 'À propos de Yan';

  @override
  String get sectionAboutHint => 'Qui conduit, services et contact';

  @override
  String get sectionEntertainment => 'Divertissement';

  @override
  String get sectionEntertainmentHint => 'Vidéos YouTube';

  @override
  String get sectionNews => 'Actualités';

  @override
  String get sectionNewsHint => 'Sport, finance, monde';

  @override
  String get sectionPoll => 'Question du jour';

  @override
  String get sectionPollHint => 'Votez et voyez les résultats';

  @override
  String get sectionStore => 'Boutique';

  @override
  String get sectionStoreHint => 'Petits articles à bord';

  @override
  String get sectionWeather => 'Météo';

  @override
  String get sectionWeatherHint => 'Le temps à destination';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get switchLanguage => 'English';

  @override
  String get backToWelcome => 'Retour à l\'accueil';

  @override
  String get loungeEyebrow => 'Lounge à bord';

  @override
  String get greetingLead => 'Bonne route.';

  @override
  String get greetingTail => 'Installez-vous.';

  @override
  String get featuredEyebrow => 'À la une';

  @override
  String get entertainmentCta => 'Regarder';

  @override
  String get pollQuestion => 'Quelle est votre ville préférée ?';

  @override
  String get aboutCta => 'Services & collaborations';

  @override
  String get driverEyebrow => 'Votre chauffeur';

  @override
  String get greetingLead1 => 'Bienvenue.';

  @override
  String get greetingTail1 => 'Le lounge est à vous.';

  @override
  String get greetingLead2 => 'Détendez-vous.';

  @override
  String get greetingTail2 => 'On s\'occupe du reste.';

  @override
  String get greetingLead3 => 'Profitez du trajet.';

  @override
  String get greetingTail3 => 'Tout est à portée de main.';

  @override
  String get dockLinkedIn => 'LinkedIn';

  @override
  String get dockCollab => 'Collaborations';

  @override
  String get dockStore => 'Boutique';

  @override
  String get back => 'Retour';

  @override
  String get collabTitle => 'Collaborations';

  @override
  String get collabCta => 'Discutons de votre projet';

  @override
  String get collabDemoBadge => 'Démo réalisée par Yanis';

  @override
  String get storeTitle => 'Boutique à bord';

  @override
  String get storeSubtitle =>
      'Petits essentiels pour le trajet, payés par Interac.';

  @override
  String get addToCart => 'Ajouter';

  @override
  String get cartTitle => 'Votre panier';

  @override
  String get cartEmpty => 'Votre panier est vide.';

  @override
  String get total => 'Total';

  @override
  String get checkout => 'Payer par Interac';

  @override
  String stockLeft(int count) {
    return '$count en stock';
  }

  @override
  String interacSend(String amount) {
    return 'Envoyez $amount par virement Interac à';
  }

  @override
  String get interacCode => 'Indiquez ce code dans le message';

  @override
  String get interacDone => 'Virement envoyé';

  @override
  String get orderThanks =>
      'Merci ! Yanis confirme votre commande dès réception du virement.';

  @override
  String get toConfigure => 'À configurer';

  @override
  String get whatsappAsk => 'Une question ? Écrivez-moi sur WhatsApp';

  @override
  String get scanLinkedIn => 'Scannez pour ouvrir mon profil';

  @override
  String get scanHint =>
      'Le code ouvre l\'app LinkedIn si elle est installée, sinon votre navigateur.';

  @override
  String get profilePreview => 'Aperçu du profil';

  @override
  String get aboutTitle => 'À propos';

  @override
  String get experienceTitle => 'Expérience';

  @override
  String get skillsTitle => 'Compétences';

  @override
  String get languagesTitle => 'Langues';

  @override
  String get contactTitle => 'Parlons de votre projet';

  @override
  String get contactScan => 'Scannez un code avec votre téléphone';

  @override
  String get newOrder => 'Nouvelle commande';

  @override
  String get dockAds => 'Votre pub';

  @override
  String get adsTitle => 'Votre publicité à bord';

  @override
  String get adsHeadline => 'Votre commerce ici.';

  @override
  String get adsPrice => '1 \$ / mois';

  @override
  String get adsFreeBadge => 'Gratuit à vie pour les premiers partenaires';

  @override
  String get adsPoint1 => 'Photo et description de votre commerce';

  @override
  String get adsPoint2 => 'Liens Instagram, TikTok et Facebook';

  @override
  String get adsPoint3 => 'Carte, adresse et téléphone';

  @override
  String get adsPoint4 => 'Vu par chaque passager, jour et nuit';

  @override
  String get adsCta => 'Réserver ma place';

  @override
  String get adsTapHint => 'Touchez une carte pour la retourner';

  @override
  String get adsExample => 'Exemple';

  @override
  String adsScanSocial(String network) {
    return 'Scannez pour ouvrir $network';
  }

  @override
  String get adsYourSpot => 'Cette place est libre';

  @override
  String get adsYourSpotHint =>
      'Soyez parmi les premiers : c’est gratuit, à vie.';
}

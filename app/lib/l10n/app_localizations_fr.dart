// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get homeGreeting => 'Bonne route !';

  @override
  String get homeSubtitle => 'Installez-vous, choisissez une section.';

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
}

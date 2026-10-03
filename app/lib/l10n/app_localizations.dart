import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @sectionAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos de Yan'**
  String get sectionAbout;

  /// No description provided for @sectionAboutHint.
  ///
  /// In fr, this message translates to:
  /// **'Qui conduit, services et contact'**
  String get sectionAboutHint;

  /// No description provided for @sectionEntertainment.
  ///
  /// In fr, this message translates to:
  /// **'Divertissement'**
  String get sectionEntertainment;

  /// No description provided for @sectionEntertainmentHint.
  ///
  /// In fr, this message translates to:
  /// **'Vidéos YouTube'**
  String get sectionEntertainmentHint;

  /// No description provided for @sectionNews.
  ///
  /// In fr, this message translates to:
  /// **'Actualités'**
  String get sectionNews;

  /// No description provided for @sectionNewsHint.
  ///
  /// In fr, this message translates to:
  /// **'Sport, finance, monde'**
  String get sectionNewsHint;

  /// No description provided for @sectionPoll.
  ///
  /// In fr, this message translates to:
  /// **'Question du jour'**
  String get sectionPoll;

  /// No description provided for @sectionPollHint.
  ///
  /// In fr, this message translates to:
  /// **'Votez et voyez les résultats'**
  String get sectionPollHint;

  /// No description provided for @sectionStore.
  ///
  /// In fr, this message translates to:
  /// **'Boutique'**
  String get sectionStore;

  /// No description provided for @sectionStoreHint.
  ///
  /// In fr, this message translates to:
  /// **'Petits articles à bord'**
  String get sectionStoreHint;

  /// No description provided for @sectionWeather.
  ///
  /// In fr, this message translates to:
  /// **'Météo'**
  String get sectionWeather;

  /// No description provided for @sectionWeatherHint.
  ///
  /// In fr, this message translates to:
  /// **'Le temps à destination'**
  String get sectionWeatherHint;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoon;

  /// No description provided for @switchLanguage.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get switchLanguage;

  /// No description provided for @backToWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToWelcome;

  /// No description provided for @loungeEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Lounge à bord'**
  String get loungeEyebrow;

  /// No description provided for @greetingLead.
  ///
  /// In fr, this message translates to:
  /// **'Bonne route.'**
  String get greetingLead;

  /// No description provided for @greetingTail.
  ///
  /// In fr, this message translates to:
  /// **'Installez-vous.'**
  String get greetingTail;

  /// No description provided for @featuredEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'À la une'**
  String get featuredEyebrow;

  /// No description provided for @entertainmentCta.
  ///
  /// In fr, this message translates to:
  /// **'Regarder'**
  String get entertainmentCta;

  /// No description provided for @pollQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Quelle est votre ville préférée ?'**
  String get pollQuestion;

  /// No description provided for @aboutCta.
  ///
  /// In fr, this message translates to:
  /// **'Services & collaborations'**
  String get aboutCta;

  /// No description provided for @driverEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Votre chauffeur'**
  String get driverEyebrow;

  /// No description provided for @greetingLead1.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue.'**
  String get greetingLead1;

  /// No description provided for @greetingTail1.
  ///
  /// In fr, this message translates to:
  /// **'Le lounge est à vous.'**
  String get greetingTail1;

  /// No description provided for @greetingLead2.
  ///
  /// In fr, this message translates to:
  /// **'Détendez-vous.'**
  String get greetingLead2;

  /// No description provided for @greetingTail2.
  ///
  /// In fr, this message translates to:
  /// **'On s\'occupe du reste.'**
  String get greetingTail2;

  /// No description provided for @greetingLead3.
  ///
  /// In fr, this message translates to:
  /// **'Profitez du trajet.'**
  String get greetingLead3;

  /// No description provided for @greetingTail3.
  ///
  /// In fr, this message translates to:
  /// **'Tout est à portée de main.'**
  String get greetingTail3;

  /// No description provided for @dockLinkedIn.
  ///
  /// In fr, this message translates to:
  /// **'LinkedIn'**
  String get dockLinkedIn;

  /// No description provided for @dockCollab.
  ///
  /// In fr, this message translates to:
  /// **'Collaborations'**
  String get dockCollab;

  /// No description provided for @dockStore.
  ///
  /// In fr, this message translates to:
  /// **'Boutique'**
  String get dockStore;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @collabTitle.
  ///
  /// In fr, this message translates to:
  /// **'Collaborations'**
  String get collabTitle;

  /// No description provided for @collabCta.
  ///
  /// In fr, this message translates to:
  /// **'Discutons de votre projet'**
  String get collabCta;

  /// No description provided for @collabDemoBadge.
  ///
  /// In fr, this message translates to:
  /// **'Démo réalisée par Yanis'**
  String get collabDemoBadge;

  /// No description provided for @storeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Boutique à bord'**
  String get storeTitle;

  /// No description provided for @storeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sneakers, maillots et petits essentiels, payés par Interac.'**
  String get storeSubtitle;

  /// No description provided for @addToCart.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addToCart;

  /// No description provided for @cartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre panier'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Votre panier est vide.'**
  String get cartEmpty;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @checkout.
  ///
  /// In fr, this message translates to:
  /// **'Payer par Interac'**
  String get checkout;

  /// No description provided for @stockLeft.
  ///
  /// In fr, this message translates to:
  /// **'{count} en stock'**
  String stockLeft(int count);

  /// No description provided for @interacSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyez {amount} par virement Interac à'**
  String interacSend(String amount);

  /// No description provided for @interacCode.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez ce code dans le message'**
  String get interacCode;

  /// No description provided for @interacDone.
  ///
  /// In fr, this message translates to:
  /// **'Virement envoyé'**
  String get interacDone;

  /// No description provided for @orderThanks.
  ///
  /// In fr, this message translates to:
  /// **'Merci ! Yanis confirme votre commande dès réception du virement.'**
  String get orderThanks;

  /// No description provided for @toConfigure.
  ///
  /// In fr, this message translates to:
  /// **'À configurer'**
  String get toConfigure;

  /// No description provided for @whatsappAsk.
  ///
  /// In fr, this message translates to:
  /// **'Une question ? Écrivez-moi sur WhatsApp'**
  String get whatsappAsk;

  /// No description provided for @scanLinkedIn.
  ///
  /// In fr, this message translates to:
  /// **'Scannez pour ouvrir mon profil'**
  String get scanLinkedIn;

  /// No description provided for @scanHint.
  ///
  /// In fr, this message translates to:
  /// **'Le code ouvre l\'app LinkedIn si elle est installée, sinon votre navigateur.'**
  String get scanHint;

  /// No description provided for @profilePreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu du profil'**
  String get profilePreview;

  /// No description provided for @aboutTitle.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get aboutTitle;

  /// No description provided for @experienceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Expérience'**
  String get experienceTitle;

  /// No description provided for @skillsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compétences'**
  String get skillsTitle;

  /// No description provided for @languagesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Langues'**
  String get languagesTitle;

  /// No description provided for @contactTitle.
  ///
  /// In fr, this message translates to:
  /// **'Parlons de votre projet'**
  String get contactTitle;

  /// No description provided for @contactScan.
  ///
  /// In fr, this message translates to:
  /// **'Scannez un code avec votre téléphone'**
  String get contactScan;

  /// No description provided for @newOrder.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle commande'**
  String get newOrder;

  /// No description provided for @dockAds.
  ///
  /// In fr, this message translates to:
  /// **'Votre pub'**
  String get dockAds;

  /// No description provided for @adsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre publicité à bord'**
  String get adsTitle;

  /// No description provided for @adsHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Votre commerce ici.'**
  String get adsHeadline;

  /// No description provided for @adsPrice.
  ///
  /// In fr, this message translates to:
  /// **'1 \$ / mois'**
  String get adsPrice;

  /// No description provided for @adsFreeBadge.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit à vie pour les premiers partenaires'**
  String get adsFreeBadge;

  /// No description provided for @adsPoint1.
  ///
  /// In fr, this message translates to:
  /// **'Photo et description de votre commerce'**
  String get adsPoint1;

  /// No description provided for @adsPoint2.
  ///
  /// In fr, this message translates to:
  /// **'Liens Instagram, TikTok et Facebook'**
  String get adsPoint2;

  /// No description provided for @adsPoint3.
  ///
  /// In fr, this message translates to:
  /// **'Carte, adresse et téléphone'**
  String get adsPoint3;

  /// No description provided for @adsPoint4.
  ///
  /// In fr, this message translates to:
  /// **'Vu par chaque passager, jour et nuit'**
  String get adsPoint4;

  /// No description provided for @adsCta.
  ///
  /// In fr, this message translates to:
  /// **'Réserver ma place'**
  String get adsCta;

  /// No description provided for @adsTapHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez une carte pour la retourner'**
  String get adsTapHint;

  /// No description provided for @adsExample.
  ///
  /// In fr, this message translates to:
  /// **'Exemple'**
  String get adsExample;

  /// No description provided for @adsScanSocial.
  ///
  /// In fr, this message translates to:
  /// **'Scannez pour ouvrir {network}'**
  String adsScanSocial(String network);

  /// No description provided for @adsYourSpot.
  ///
  /// In fr, this message translates to:
  /// **'Cette place est libre'**
  String get adsYourSpot;

  /// No description provided for @adsYourSpotHint.
  ///
  /// In fr, this message translates to:
  /// **'Soyez parmi les premiers : c’est gratuit, à vie.'**
  String get adsYourSpotHint;

  /// No description provided for @dockMusic.
  ///
  /// In fr, this message translates to:
  /// **'Musique'**
  String get dockMusic;

  /// No description provided for @musicTitle.
  ///
  /// In fr, this message translates to:
  /// **'Coin musique'**
  String get musicTitle;

  /// No description provided for @musicYanPick.
  ///
  /// In fr, this message translates to:
  /// **'Le choix de Yan'**
  String get musicYanPick;

  /// No description provided for @musicYanPickHint.
  ///
  /// In fr, this message translates to:
  /// **'Sa chanson pour toute une vie'**
  String get musicYanPickHint;

  /// No description provided for @musicPlayIt.
  ///
  /// In fr, this message translates to:
  /// **'Fais-moi écouter'**
  String get musicPlayIt;

  /// No description provided for @musicNowPlaying.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get musicNowPlaying;

  /// No description provided for @musicVolume.
  ///
  /// In fr, this message translates to:
  /// **'Volume'**
  String get musicVolume;

  /// No description provided for @musicMaxHint.
  ///
  /// In fr, this message translates to:
  /// **'Volume limité pour la sécurité du conducteur'**
  String get musicMaxHint;

  /// No description provided for @musicPlaylistTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez l’ambiance du trajet'**
  String get musicPlaylistTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

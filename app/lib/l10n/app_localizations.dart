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

  /// No description provided for @homeGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonne route !'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Installez-vous, choisissez une section.'**
  String get homeSubtitle;

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

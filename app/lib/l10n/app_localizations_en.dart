// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get homeGreeting => 'Enjoy the ride!';

  @override
  String get homeSubtitle => 'Make yourself comfortable and pick a section.';

  @override
  String get sectionAbout => 'About Yan';

  @override
  String get sectionAboutHint => 'Your driver, services and contact';

  @override
  String get sectionEntertainment => 'Entertainment';

  @override
  String get sectionEntertainmentHint => 'YouTube videos';

  @override
  String get sectionNews => 'News';

  @override
  String get sectionNewsHint => 'Sports, finance, world';

  @override
  String get sectionPoll => 'Question of the day';

  @override
  String get sectionPollHint => 'Vote and see the results';

  @override
  String get sectionStore => 'Store';

  @override
  String get sectionStoreHint => 'Small items on board';

  @override
  String get sectionWeather => 'Weather';

  @override
  String get sectionWeatherHint => 'Weather at your destination';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get switchLanguage => 'Français';

  @override
  String get backToWelcome => 'Back to welcome';
}

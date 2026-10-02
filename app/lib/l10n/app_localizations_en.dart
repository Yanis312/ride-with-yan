// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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

  @override
  String get loungeEyebrow => 'Onboard lounge';

  @override
  String get greetingLead => 'Enjoy the ride.';

  @override
  String get greetingTail => 'Make yourself at home.';

  @override
  String get featuredEyebrow => 'Featured';

  @override
  String get entertainmentCta => 'Watch';

  @override
  String get pollQuestion => 'What\'s your favourite city?';

  @override
  String get aboutCta => 'Services & collaborations';

  @override
  String get driverEyebrow => 'Your driver';

  @override
  String get greetingLead1 => 'Welcome.';

  @override
  String get greetingTail1 => 'The lounge is yours.';

  @override
  String get greetingLead2 => 'Relax.';

  @override
  String get greetingTail2 => 'We\'ll take care of the rest.';

  @override
  String get greetingLead3 => 'Enjoy the journey.';

  @override
  String get greetingTail3 => 'Everything is at your fingertips.';

  @override
  String get dockLinkedIn => 'LinkedIn';

  @override
  String get dockCollab => 'Collaborations';

  @override
  String get dockStore => 'Store';

  @override
  String get back => 'Back';

  @override
  String get collabTitle => 'Collaborations';

  @override
  String get collabCta => 'Let\'s talk about your project';

  @override
  String get collabDemoBadge => 'Demo built by Yanis';

  @override
  String get storeTitle => 'Onboard store';

  @override
  String get storeSubtitle => 'Small essentials for the ride, paid by Interac.';

  @override
  String get addToCart => 'Add';

  @override
  String get cartTitle => 'Your cart';

  @override
  String get cartEmpty => 'Your cart is empty.';

  @override
  String get total => 'Total';

  @override
  String get checkout => 'Pay with Interac';

  @override
  String stockLeft(int count) {
    return '$count in stock';
  }

  @override
  String interacSend(String amount) {
    return 'Send $amount by Interac e-Transfer to';
  }

  @override
  String get interacCode => 'Add this code to the message';

  @override
  String get interacDone => 'Transfer sent';

  @override
  String get orderThanks =>
      'Thank you! Yanis will confirm your order as soon as the transfer arrives.';

  @override
  String get toConfigure => 'To be configured';

  @override
  String get whatsappAsk => 'A question? Message me on WhatsApp';

  @override
  String get scanLinkedIn => 'Scan to open my profile';

  @override
  String get scanHint =>
      'The code opens the LinkedIn app if installed, otherwise your browser.';

  @override
  String get profilePreview => 'Profile preview';

  @override
  String get aboutTitle => 'About';

  @override
  String get experienceTitle => 'Experience';

  @override
  String get skillsTitle => 'Skills';

  @override
  String get languagesTitle => 'Languages';

  @override
  String get contactTitle => 'Let\'s talk about your project';

  @override
  String get contactScan => 'Scan a code with your phone';

  @override
  String get newOrder => 'New order';
}

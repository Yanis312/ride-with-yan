import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../data/store_catalog.dart';

/// État de la course en cours : langue choisie et retour automatique
/// à l'accueil quand le passager n'a plus touché l'écran depuis un moment.
class SessionController extends ChangeNotifier {
  SessionController({
    this.inactivityTimeout = const Duration(seconds: 90),
    math.Random? random,
  }) : _random = random ?? math.Random();

  static const greetingCount = 4;

  final Duration inactivityTimeout;

  final math.Random _random;

  /// Panier du passager, vidé en fin de session.
  final cart = Cart();
  Locale? _locale;
  int _greeting = 0;

  /// Formule d'accueil du lounge, tirée au hasard pour chaque passager.
  int get greeting => _greeting;
  Timer? _inactivityTimer;
  int _generation = 0;

  /// Augmente à chaque fin de session : l'accueil repart toujours de zéro
  /// pour le passager suivant.
  int get generation => _generation;

  /// Langue du passager, ou `null` tant qu'il est sur l'écran d'accueil.
  Locale? get locale => _locale;

  // Langue affichée avant le choix du passager : anglais par défaut
  // (beaucoup d'anglophones à Montréal), modifiable par le bouton de l'accueil.
  Locale _preferred = const Locale('en');

  /// Langue de l'interface : celle du passager, sinon la langue préférée.
  Locale get displayLocale => _locale ?? _preferred;

  /// Bascule la langue de l'écran d'accueil (avant le début de la session).
  void togglePreferred() {
    _preferred = _preferred.languageCode == 'en'
        ? const Locale('fr')
        : const Locale('en');
    notifyListeners();
  }

  bool get isActive => _locale != null;

  void start(Locale locale) {
    _greeting = _random.nextInt(greetingCount);
    _setLocale(locale);
  }

  void _setLocale(Locale locale) {
    _locale = locale;
    _restartTimer();
    notifyListeners();
  }

  void switchLanguage() {
    if (_locale == null) return;
    // Même passager : on garde sa formule d'accueil.
    _setLocale(
      _locale!.languageCode == 'fr' ? const Locale('en') : const Locale('fr'),
    );
  }

  /// À appeler à chaque toucher de l'écran.
  void registerInteraction() {
    if (isActive) _restartTimer();
  }

  /// Termine la session : la langue est oubliée, l'app revient à l'accueil.
  void reset() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _mediaPlaying = false;
    _paying = false;
    if (_locale == null) return;
    // Le passager suivant retrouve la langue d'accueil par défaut.
    _preferred = const Locale('en');
    _locale = null;
    cart.clear();
    _generation++;
    notifyListeners();
  }

  bool _mediaPlaying = false;

  /// Délai sans toucher l'écran tant qu'une vidéo ou une chanson joue.
  /// Plus long que la plus longue vidéo proposée (30 min).
  static const mediaTimeout = Duration(minutes: 45);

  bool _paying = false;

  /// Délai pendant un paiement ou une commande : le passager est sur son
  /// téléphone, en train de faire son virement ou d'écrire sur WhatsApp.
  static const payingTimeout = Duration(minutes: 6);

  /// À appeler quand l'écran de paiement (ou de commande) s'ouvre ou se ferme.
  void setPaying(bool paying) {
    if (_paying == paying) return;
    _paying = paying;
    if (isActive) _restartTimer();
  }

  /// À appeler quand la lecture démarre ou s'arrête : pendant une vidéo, le
  /// passager ne touche plus l'écran et la session ne doit pas se terminer
  /// au bout du délai habituel.
  void setMediaPlaying(bool playing) {
    if (_mediaPlaying == playing) return;
    _mediaPlaying = playing;
    if (isActive) _restartTimer();
  }

  void _restartTimer() {
    _inactivityTimer?.cancel();
    final delay = _mediaPlaying
        ? mediaTimeout
        : (_paying ? payingTimeout : inactivityTimeout);
    _inactivityTimer = Timer(delay, reset);
  }

  @override
  void dispose() {
    cart.dispose();
    _inactivityTimer?.cancel();
    super.dispose();
  }
}

/// Donne accès au [SessionController] partout sous [RideWithYanApp].
class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({
    super.key,
    required SessionController controller,
    required super.child,
  }) : super(notifier: controller);

  static SessionController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}

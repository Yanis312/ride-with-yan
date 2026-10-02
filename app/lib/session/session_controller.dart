import 'dart:async';

import 'package:flutter/widgets.dart';

/// État de la course en cours : langue choisie et retour automatique
/// à l'accueil quand le passager n'a plus touché l'écran depuis un moment.
class SessionController extends ChangeNotifier {
  SessionController({this.inactivityTimeout = const Duration(seconds: 90)});

  final Duration inactivityTimeout;

  Locale? _locale;
  Timer? _inactivityTimer;

  /// Langue du passager, ou `null` tant qu'il est sur l'écran d'accueil.
  Locale? get locale => _locale;
  bool get isActive => _locale != null;

  void start(Locale locale) {
    _locale = locale;
    _restartTimer();
    notifyListeners();
  }

  void switchLanguage() {
    if (_locale == null) return;
    start(
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
    if (_locale == null) return;
    _locale = null;
    notifyListeners();
  }

  void _restartTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, reset);
  }

  @override
  void dispose() {
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

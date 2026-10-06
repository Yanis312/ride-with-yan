import 'dart:async';

import 'package:flutter/widgets.dart';

enum AppearanceMode { auto, light, dark }

/// Mode clair / sombre. En automatique, l'app passe en sombre la nuit
/// (de 18 h à 7 h) pour ne pas éblouir le passager.
class AppearanceController extends ChangeNotifier {
  AppearanceController({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => notifyListeners(),
    );
  }

  final DateTime Function() _clock;
  late final Timer _timer;

  AppearanceMode _mode = AppearanceMode.auto;
  AppearanceMode get mode => _mode;

  Brightness get brightness => switch (_mode) {
    AppearanceMode.light => Brightness.light,
    AppearanceMode.dark => Brightness.dark,
    AppearanceMode.auto =>
      _isNight(_clock()) ? Brightness.dark : Brightness.light,
  };

  static bool _isNight(DateTime now) => now.hour >= 18 || now.hour < 7;

  /// Bascule manuelle vers le mode opposé à celui affiché.
  void toggle() {
    _mode = brightness == Brightness.dark
        ? AppearanceMode.light
        : AppearanceMode.dark;
    notifyListeners();
  }

  /// Retour au mode automatique : le choix d'un passager ne s'impose pas
  /// au suivant.
  void resetToAuto() {
    if (_mode == AppearanceMode.auto) return;
    _mode = AppearanceMode.auto;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class AppearanceScope extends InheritedNotifier<AppearanceController> {
  const AppearanceScope({
    super.key,
    required AppearanceController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppearanceController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()!.notifier!;
}

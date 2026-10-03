import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'session/session_controller.dart';
import 'theme/app_theme.dart';
import 'theme/appearance_controller.dart';

class RideWithYanApp extends StatefulWidget {
  const RideWithYanApp({super.key, this.session, this.appearance});

  /// Injectables pour les tests (délai d'inactivité court, mode forcé...).
  final SessionController? session;
  final AppearanceController? appearance;

  @override
  State<RideWithYanApp> createState() => _RideWithYanAppState();
}

class _RideWithYanAppState extends State<RideWithYanApp> {
  late final SessionController _session = widget.session ?? SessionController();
  late final AppearanceController _appearance =
      widget.appearance ?? AppearanceController();
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
  }

  // En fin de session, on referme tout écran ouvert par-dessus le menu.
  void _onSessionChanged() {
    if (!_session.isActive) {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    if (widget.session == null) _session.dispose();
    if (widget.appearance == null) _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: _session,
      child: AppearanceScope(
        controller: _appearance,
        child: ListenableBuilder(
          listenable: Listenable.merge([_session, _appearance]),
          builder: (context, _) => MaterialApp(
            title: 'Ride with Yan',
            debugShowCheckedModeBanner: false,
            navigatorKey: _navigatorKey,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: _appearance.brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            themeAnimationDuration: const Duration(milliseconds: 700),
            themeAnimationCurve: AppMotion.spring,
            locale: _session.displayLocale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _session.registerInteraction(),
              child: child,
            ),
            home: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: AppMotion.spring,
              switchOutCurve: AppMotion.spring,
              child: _session.isActive
                  ? const HomeScreen(key: ValueKey('home'))
                  : WelcomeScreen(
                      key: ValueKey('welcome-${_session.generation}'),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

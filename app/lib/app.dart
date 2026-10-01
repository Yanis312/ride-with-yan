import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'session/session_controller.dart';
import 'theme/app_theme.dart';

class RideWithYanApp extends StatefulWidget {
  const RideWithYanApp({super.key, this.session});

  /// Injectable pour les tests (délai d'inactivité court, par exemple).
  final SessionController? session;

  @override
  State<RideWithYanApp> createState() => _RideWithYanAppState();
}

class _RideWithYanAppState extends State<RideWithYanApp> {
  late final SessionController _session = widget.session ?? SessionController();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: _session,
      child: ListenableBuilder(
        listenable: _session,
        builder: (context, _) => MaterialApp(
          title: 'Ride with Yan',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          theme: buildAppTheme(),
          locale: _session.locale ?? const Locale('fr'),
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
            duration: const Duration(milliseconds: 500),
            child: _session.isActive
                ? const HomeScreen(key: ValueKey('home'))
                : const WelcomeScreen(key: ValueKey('welcome')),
          ),
        ),
      ),
    );
  }
}

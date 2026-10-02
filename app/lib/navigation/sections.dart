import 'package:flutter/material.dart';

import '../screens/ads_screen.dart';
import '../screens/collaboration_screen.dart';
import '../screens/linkedin_screen.dart';
import '../screens/store_screen.dart';
import '../session/session_controller.dart';
import '../theme/app_theme.dart';

/// Sections accessibles depuis le dock, partout dans l'app.
enum Section { linkedin, collaboration, store, ads }

/// Ouvre une section. Depuis l'écran de veille, la session démarre d'abord
/// (en français par défaut, le passager peut changer ensuite).
void openSection(BuildContext context, Section section) {
  final session = SessionScope.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  if (!session.isActive) session.start(Localizations.localeOf(context));

  // Une seule section à la fois au-dessus du lounge.
  navigator.popUntil((route) => route.isFirst);
  navigator.push(_sectionRoute(section));
}

Route<void> _sectionRoute(Section section) {
  return PageRouteBuilder<void>(
    settings: RouteSettings(name: section.name),
    transitionDuration: const Duration(milliseconds: 650),
    reverseTransitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, _, _) => switch (section) {
      Section.linkedin => const LinkedInScreen(),
      Section.collaboration => const CollaborationScreen(),
      Section.store => const StoreScreen(),
      Section.ads => const AdsScreen(),
    },
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.spring,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

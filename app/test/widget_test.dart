import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ride_with_yan/theme/app_icons.dart';
import 'package:ride_with_yan/app.dart';
import 'package:ride_with_yan/session/session_controller.dart';

void main() {
  setUpAll(initializeDateFormatting);

  Future<void> pumpApp(WidgetTester tester, SessionController session) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RideWithYanApp(session: session));
    await tester.pump(const Duration(seconds: 3));
  }

  Future<void> chooseLanguage(WidgetTester tester, String label) async {
    await tester.tapAt(const Offset(640, 300));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text(label).last); // le bouton du panneau, pas celui du haut
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(); // retire l'accueil une fois la transition finie
  }

  // Arrête le minuteur d'inactivité et laisse finir les animations de
  // l'accueil, sinon le test échoue avec des timers en attente.
  Future<void> endSession(
    WidgetTester tester,
    SessionController session,
  ) async {
    session.reset();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('choisir le français ouvre le lounge en français', (
    tester,
  ) async {
    final session = SessionController(random: _FirstChoice());
    addTearDown(session.dispose);
    await pumpApp(tester, session);

    expect(find.text('Bienvenue à bord.'), findsOneWidget);

    await chooseLanguage(tester, 'Français');

    expect(
      find.textContaining('Bonne route.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Divertissement'), findsOneWidget);
    await endSession(tester, session);
  });

  testWidgets('le bouton de langue bascule en anglais', (tester) async {
    final session = SessionController(random: _FirstChoice());
    addTearDown(session.dispose);
    await pumpApp(tester, session);
    await chooseLanguage(tester, 'Français');

    await tester.tap(find.byIcon(AppIcons.translate).last);
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.textContaining('Enjoy the ride.', findRichText: true),
      findsOneWidget,
    );
    await endSession(tester, session);
  });

  testWidgets(
    "le dock ouvre la boutique depuis l'écran de veille (anglais par défaut)",
    (tester) async {
      final session = SessionController(random: _FirstChoice());
      addTearDown(session.dispose);
      await pumpApp(tester, session);

      await tester.tap(find.text('Store'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(session.isActive, isTrue);
      expect(find.text('Onboard store'), findsOneWidget);
      await endSession(tester, session);
    },
  );

  testWidgets("retour à l'accueil après inactivité", (tester) async {
    final session = SessionController(
      inactivityTimeout: const Duration(seconds: 5),
      random: _FirstChoice(),
    );
    addTearDown(session.dispose);
    await pumpApp(tester, session);
    await chooseLanguage(tester, 'English');
    expect(find.text('Entertainment'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));

    expect(session.isActive, isFalse);
    expect(find.text('Bienvenue à bord.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}

/// Hasard prévisible : toujours le premier choix.
class _FirstChoice implements math.Random {
  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

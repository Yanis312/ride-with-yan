import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/session/session_controller.dart';

void main() {
  test("changer de langue garde la formule d'accueil du passager", () {
    final session = SessionController(random: math.Random(7));
    addTearDown(session.dispose);

    session.start(const Locale('fr'));
    final greeting = session.greeting;
    session.switchLanguage();

    expect(session.locale, const Locale('en'));
    expect(session.greeting, greeting);
    session.reset();
  });

  test('chaque fin de session fait avancer la génération', () {
    final session = SessionController();
    addTearDown(session.dispose);

    session.start(const Locale('en'));
    session.reset();

    expect(session.generation, 1);
    expect(session.isActive, isFalse);
  });
}

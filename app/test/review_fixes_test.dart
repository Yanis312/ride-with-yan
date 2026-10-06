import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ride_with_yan/app.dart';
import 'package:ride_with_yan/backend/backend.dart';
import 'package:ride_with_yan/backend/remote_config.dart';
import 'package:ride_with_yan/data/store_catalog.dart';
import 'package:ride_with_yan/screens/store_screen.dart';
import 'package:ride_with_yan/session/session_controller.dart';
import 'package:ride_with_yan/theme/app_icons.dart';
import 'package:ride_with_yan/theme/appearance_controller.dart';

/// Toujours le premier choix : phrases d'accueil prévisibles.
class _FirstChoice implements math.Random {
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}

void main() {
  setUpAll(() async {
    Backend.offline = true;
    await initializeDateFormatting();
    // Les vraies polices : sans elles, les tests mesurent le texte avec une
    // police de remplacement bien plus large, et voient de faux débordements.
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(
          File('assets/fonts/$file').readAsBytes().then(ByteData.sublistView),
        );
      }
      await loader.load();
    }

    await load('Cormorant', [
      'cormorant-garamond-500-normal.ttf',
      'cormorant-garamond-600-normal.ttf',
      'cormorant-garamond-500-italic.ttf',
    ]);
    await load('Jakarta', [
      'plus-jakarta-sans-300-normal.ttf',
      'plus-jakarta-sans-400-normal.ttf',
      'plus-jakarta-sans-500-normal.ttf',
      'plus-jakarta-sans-600-normal.ttf',
    ]);
    await load('PhosphorLight', ['phosphor-light.ttf']);
  });

  testWidgets(
    'petite tablette (960 x 600) : lounge et boutique sans débordement',
    (tester) async {
      tester.view.physicalSize = const Size(960, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final session = SessionController(random: _FirstChoice());
      addTearDown(session.dispose);
      await tester.pumpWidget(RideWithYanApp(session: session));
      await tester.pump(const Duration(seconds: 3));

      // Un débordement de mise en page ferait échouer le test tout seul.
      session.start(const Locale('fr'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Divertissement'), findsOneWidget);

      await tester.tap(find.text('Ma boutique').last);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.byType(StoreScreen), findsOneWidget);

      // Un essentiel au panier : le compteur - / + doit tenir dans la carte.
      await tester.tap(find.text('Essentiels'));
      await tester.pump(const Duration(seconds: 2));
      final plus = find.byIcon(AppIcons.plus).first;
      await tester.ensureVisible(plus);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(plus);
      await tester.pump(const Duration(seconds: 1));
      expect(session.cart.count, 1);

      session.reset();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('pendant un paiement, la session attend plus longtemps', (
    tester,
  ) async {
    final session = SessionController(
      inactivityTimeout: const Duration(seconds: 2),
    );
    addTearDown(session.dispose);

    session.start(const Locale('fr'));
    session.setPaying(true);
    await tester.pump(const Duration(seconds: 5));
    expect(session.isActive, isTrue);

    session.setPaying(false);
    await tester.pump(const Duration(seconds: 3));
    expect(session.isActive, isFalse);
  });

  test("la langue d'accueil revient à l'anglais au passager suivant", () {
    final session = SessionController();
    addTearDown(session.dispose);

    session.togglePreferred();
    expect(session.displayLocale, const Locale('fr'));
    session.start(const Locale('fr'));
    session.reset();

    expect(session.displayLocale, const Locale('en'));
  });

  test('le mode clair ou sombre choisi ne reste pas au passager suivant', () {
    final appearance = AppearanceController(
      clock: () => DateTime(2026, 10, 6, 12),
    );
    addTearDown(appearance.dispose);

    appearance.toggle();
    expect(appearance.brightness, Brightness.dark);
    appearance.resetToAuto();
    expect(appearance.mode, AppearanceMode.auto);
    expect(appearance.brightness, Brightness.light);
  });

  test("une valeur mal saisie dans la base n'abîme pas le catalogue", () {
    final remote = RemoteConfig.instance;
    addTearDown(remote.setForTest);

    remote.setForTest(
      products: {
        'chaussures-blanc': {
          'price': 'cent dollars',
          'sizes': {'US 9': -3, 'US 8': 'deux'},
        },
        'umbrella': {'price': -5, 'stock': 'beaucoup'},
      },
    );

    final shoes = catalog.firstWhere((p) => p.id == 'chaussures-blanc');
    final base = baseCatalog.firstWhere((p) => p.id == 'chaussures-blanc');
    expect(shoes.price, base.price);
    expect(shoes.stockOf('US 9'), base.stockOf('US 9'));
    expect(shoes.stockOf('US 8'), base.stockOf('US 8'));

    final umbrella = catalog.firstWhere((p) => p.id == 'umbrella');
    expect(umbrella.price, 15);
    expect(umbrella.stock, 2);
  });
}

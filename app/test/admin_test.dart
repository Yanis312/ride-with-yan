import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/admin/admin_app.dart';
import 'package:ride_with_yan/backend/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => Backend.offline = true);

  testWidgets(
    'le panneau affiche les articles et le sondage sur un téléphone',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: AdminHome(session: AdminSession()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Blanc intégral'), findsOneWidget);
      expect(find.text('Enregistrer'), findsWidgets);

      // Modifier un stock rend la fiche enregistrable.
      await tester.tap(
        find.byIcon(const IconData(0xe3d4, fontFamily: 'PhosphorLight')).first,
      );
      await tester.pump();
      final save = tester.widget<FilledButton>(find.byType(FilledButton).first);
      expect(save.onPressed, isNotNull);

      await tester.tap(find.text('Sondage'));
      await tester.pumpAndSettle();
      expect(find.text('Question du jour'), findsOneWidget);
      expect(find.text('Poutine ou smoked meat ?'), findsWidgets);
    },
  );
}

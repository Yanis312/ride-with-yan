import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/theme/app_theme.dart';
import 'package:ride_with_yan/widgets/pull_cord.dart';

void main() {
  Future<List<int>> pump(WidgetTester tester) async {
    final toggles = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Center(
            child: PullCord(
              dark: false,
              label: 'Mode nuit',
              onToggle: () => toggles.add(1),
            ),
          ),
        ),
      ),
    );
    return toggles;
  }

  testWidgets('tirer le fil assez loin change de mode', (tester) async {
    final toggles = await pump(tester);
    await tester.drag(find.byKey(PullCord.handleKey), const Offset(0, 80));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(toggles, hasLength(1));
  });

  testWidgets('un petit tiraillement ne change rien', (tester) async {
    final toggles = await pump(tester);
    await tester.drag(find.byKey(PullCord.handleKey), const Offset(0, 30));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(toggles, isEmpty);
  });

  testWidgets('un toucher suffit aussi', (tester) async {
    final toggles = await pump(tester);
    await tester.tap(find.byType(PullCord));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(toggles, hasLength(1));
  });

  testWidgets('toucher le fil aussi', (tester) async {
    final toggles = await pump(tester);
    await tester.tap(find.byKey(PullCord.handleKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(toggles, hasLength(1));
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/theme/appearance_controller.dart';

void main() {
  AppearanceController at(int hour) =>
      AppearanceController(clock: () => DateTime(2026, 10, 2, hour));

  test('automatique : clair le jour, sombre la nuit', () {
    final day = at(10);
    final night = at(22);
    addTearDown(day.dispose);
    addTearDown(night.dispose);

    expect(day.brightness, Brightness.light);
    expect(night.brightness, Brightness.dark);
  });

  test('la bascule manuelle passe au mode opposé', () {
    final c = at(10);
    addTearDown(c.dispose);

    c.toggle();
    expect(c.mode, AppearanceMode.dark);
    expect(c.brightness, Brightness.dark);

    c.toggle();
    expect(c.brightness, Brightness.light);
  });
}

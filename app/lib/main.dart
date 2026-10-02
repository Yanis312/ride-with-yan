import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  runApp(
    LiquidGlassWidgets.wrap(
      // Le verre suit le mode clair/sombre de l'app, pas celui du système.
      brightnessResolver: Theme.maybeBrightnessOf,
      // Tablette d'entrée de gamme : la qualité s'adapte à l'appareil.
      adaptiveQuality: true,
      child: const RideWithYanApp(),
    ),
  );
}

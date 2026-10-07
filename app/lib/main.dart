import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'admin/admin_app.dart';
import 'app.dart';
import 'backend/remote_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Adresse terminée par ?admin : panneau d'administration de Yanis.
  if (Uri.base.queryParameters.containsKey('admin')) {
    try {
      await initializeDateFormatting();
    } catch (_) {
      // Les dates s'afficheront au format par défaut.
    }
    runApp(const AdminApp());
    return;
  }

  // Une erreur d'affichage ne doit jamais laisser un carré gris ou rouge
  // sur une tablette sans surveillance : on montre un message discret.
  ErrorWidget.builder = (details) => const _Fallback();

  try {
    await initializeDateFormatting();
  } catch (error) {
    // L'app démarre quand même, avec les réglages par défaut.
    debugPrint('Initialisation incomplète : $error');
  }

  if (!kIsWeb) await _prepareKiosk();

  // Prix, stocks et réglages de l'administration, dès le démarrage.
  unawaited(RemoteConfig.instance.refresh());

  runApp(const RideWithYanApp());
}

/// Tablette de bord : plein écran sans les barres d'Android, et paysage
/// verrouillé (un téléphone, lui, reste libre de tourner).
Future<void> _prepareKiosk() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final view = PlatformDispatcher.instance.views.first;
  final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
  if (shortestSide >= 600) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}

/// Affiché à la place d'un élément qui n'a pas pu se dessiner.
class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF0B0B0F),
      child: Center(
        child: Icon(Icons.refresh, color: Color(0x66FFFFFF), size: 28),
      ),
    );
  }
}

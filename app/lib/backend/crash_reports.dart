import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../config.dart';

/// Signale les plantages à Sentry : la tablette tourne sans surveillance.
/// Seule l'erreur technique part : ni commande, ni client, ni capture d'écran.
abstract final class CrashReports {
  /// Lance l'app, avec le signalement quand il est permis.
  static Future<void> run(FutureOr<void> Function() app) async {
    if (!shouldReport(AppConfig.sentryDsn, Uri.base)) {
      await app();
      return;
    }
    await SentryFlutter.init((options) {
      options.dsn = AppConfig.sentryDsn;
      options.sendDefaultPii = false;
      options.attachScreenshot = false;
      options.maxRequestBodySize = MaxRequestBodySize.never;
      // Le fil d'une requête peut contenir une adresse ou un texte de passager.
      options.beforeBreadcrumb = (crumb, _) =>
          crumb?.category == 'http' ? null : crumb;
    }, appRunner: app);
  }

  static bool shouldReport(String dsn, Uri address) =>
      dsn.isNotEmpty && !address.queryParameters.containsKey('e2e');
}

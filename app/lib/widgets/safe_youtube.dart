import 'dart:async';

import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Commandes YouTube qui ne font jamais planter l'app.
///
/// Sans réseau, le lecteur peut ne jamais démarrer : chaque commande
/// (préparer, lire, volume…) échoue alors au bout de 30 s avec une
/// TimeoutException non rattrapée, que Sentry signale comme fatale. Ici,
/// la commande est simplement abandonnée.
extension SafeYoutube on YoutubePlayerController {
  void safely(Future<void> Function(YoutubePlayerController player) command) {
    unawaited(guardYoutube(() => command(this)));
  }
}

/// Exécute [command] en ignorant l'échec de démarrage du lecteur.
Future<void> guardYoutube(Future<void> Function() command) async {
  try {
    await command();
  } on TimeoutException {
    // Lecteur jamais prêt (hors ligne) : rien à faire.
  }
}

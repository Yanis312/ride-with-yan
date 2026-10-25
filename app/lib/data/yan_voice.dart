import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../backend/usage.dart';
import '../config.dart';

/// Voix de Yan : lit une réponse avec Azure AI Speech (fonction `speak`).
/// Une seule lecture à la fois ; [playing] indique le texte en cours.
class YanVoice extends ChangeNotifier {
  YanVoice._();

  static final instance = YanVoice._();

  VideoPlayerController? _player;
  String? _playing;

  String? get playing => _playing;

  /// Adresse de l'audio. Séparée pour être testée.
  static Uri audioUrl(String text, String language) =>
      Uri.parse('${AppConfig.supabaseUrl}/functions/v1/speak')
          .replace(queryParameters: {'lang': language, 'text': text});

  /// Lit [text], ou arrête la lecture s'il est déjà en cours.
  Future<void> toggle(String text, {required String language}) async {
    final again = _playing == text;
    await stop();
    if (again) return;

    Usage.instance.tap('assistant.listen');
    final player = VideoPlayerController.networkUrl(audioUrl(text, language));
    _player = player;
    _playing = text;
    notifyListeners();
    try {
      await player.initialize();
      // Une autre lecture a commencé entre-temps.
      if (_player != player) return;
      player.addListener(() {
        final v = player.value;
        if (v.isInitialized && !v.isPlaying && v.position >= v.duration) {
          if (_player == player) {
            stop();
          }
        }
      });
      await player.play();
    } catch (_) {
      if (_player == player) await stop();
    }
  }

  Future<void> stop() async {
    final player = _player;
    _player = null;
    _playing = null;
    notifyListeners();
    await player?.dispose();
  }
}

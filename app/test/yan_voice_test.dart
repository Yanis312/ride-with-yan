import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/data/yan_voice.dart';

void main() {
  test('l’audio est demandé à la fonction speak, texte encodé', () {
    final url = YanVoice.audioUrl('Le combo : 120 \$ & plus', 'fr');
    expect(url.path, '/functions/v1/speak');
    expect(url.queryParameters, {
      'lang': 'fr',
      'text': 'Le combo : 120 \$ & plus',
    });
  });
}

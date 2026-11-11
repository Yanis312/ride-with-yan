import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/widgets/safe_youtube.dart';

void main() {
  test('un lecteur YouTube jamais prêt ne fait pas planter l’app', () async {
    await expectLater(
      guardYoutube(
        () => Future.error(TimeoutException('YouTube player not ready')),
      ),
      completes,
    );
  });

  test('les autres erreurs restent signalées', () async {
    await expectLater(
      guardYoutube(() => Future.error(StateError('bug'))),
      throwsStateError,
    );
  });
}

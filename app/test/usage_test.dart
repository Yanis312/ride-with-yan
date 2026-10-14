import 'package:flutter_test/flutter_test.dart';
import 'package:ride_with_yan/admin/admin_app.dart';
import 'package:ride_with_yan/backend/backend.dart';
import 'package:ride_with_yan/backend/usage.dart';

void main() {
  final usage = Usage.instance;

  setUp(() {
    Backend.offline = true;
    usage.reset();
  });
  tearDown(usage.reset);

  test('rien n’est compté avant le début d’une course', () {
    usage.tap('store.add:x');
    usage.screen('store');
    expect(usage.pending, isEmpty);
  });

  test('une course : début, écrans, boutons, fin avec sa durée', () {
    usage.sessionStarted('fr');
    usage.screen('store');
    usage.tap('store.add:chaussures-noir');
    usage.sessionEnded();

    final kinds = [for (final e in usage.pending) e['kind']];
    expect(kinds, ['session_start', 'screen', 'tap', 'session_end']);
    expect(usage.pending.map((e) => e['session_id']).toSet(), hasLength(1));
    expect(usage.pending.last['value'], isA<int>());
    expect(usage.pending.every((e) => e['language'] == 'fr'), isTrue);
  });

  test('chaque passager reçoit un nouveau numéro au hasard', () {
    usage.sessionStarted('en');
    usage.sessionEnded();
    usage.sessionStarted('en');
    final ids = usage.pending.map((e) => e['session_id']).toSet();
    expect(ids, hasLength(2));
    expect(
      ids.first,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('les noms sont nettoyés pour respecter les règles de la base', () {
    usage.sessionStarted('en');
    usage.tap('Vidéo lancée !');
    expect(
      usage.pending.last['name'],
      matches(RegExp(r'^[a-z0-9_.:-]{1,60}$')),
    );
  });

  test('sans réseau, on garde au plus 200 évènements', () {
    usage.sessionStarted('en');
    for (var i = 0; i < 300; i++) {
      usage.tap('t$i');
    }
    expect(usage.pending, hasLength(Usage.maxPending));
    expect(usage.pending.last['name'], 't299');
  });

  test('libellés lisibles dans le panneau d’administration', () {
    expect(usageLabel('store'), 'Boutique');
    expect(usageLabel('contact.open'), 'Demande de contact (services)');
    expect(
      usageLabel('store.add:chaussures-noir'),
      'Ajout au panier : Noir intégral',
    );
    expect(usageLabel('inconnu'), 'inconnu');
  });
}

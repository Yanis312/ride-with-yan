import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ride_with_yan/backend/backend.dart';
import 'package:ride_with_yan/backend/usage.dart';
import 'package:ride_with_yan/data/assistant.dart';

void main() {
  group('réponse de la fonction chat', () {
    test('renvoie le texte de l’assistant', () {
      expect(
        parseAssistantReply(200, jsonEncode({'reply': '  Bonjour !  '})),
        'Bonjour !',
      );
    });

    test('plafond atteint, question filtrée, panne', () {
      Matcher fails(AssistantFailure f) => throwsA(
        isA<AssistantException>().having((e) => e.failure, 'failure', f),
      );
      expect(
        () => parseAssistantReply(429, '{}'),
        fails(AssistantFailure.quota),
      );
      expect(
        () => parseAssistantReply(200, jsonEncode({'filtered': true})),
        fails(AssistantFailure.filtered),
      );
      expect(
        () => parseAssistantReply(502, '{}'),
        fails(AssistantFailure.unavailable),
      );
      expect(
        () => parseAssistantReply(200, jsonEncode({'reply': ''})),
        fails(AssistantFailure.unavailable),
      );
    });
  });

  group('conversation', () {
    late List<Map<String, dynamic>> sent;

    AssistantController controllerReplying(http.Response Function() answer) {
      return AssistantController(
        client: MockClient((request) async {
          sent.add(jsonDecode(request.body) as Map<String, dynamic>);
          return answer();
        }),
      );
    }

    setUp(() {
      sent = [];
      Backend.offline = false;
      Usage.instance.reset();
      Usage.instance.sessionStarted('fr');
    });

    tearDown(() {
      Backend.offline = true;
      Usage.instance.reset();
    });

    test('envoie toute la conversation et garde la réponse', () async {
      final assistant = controllerReplying(
        () =>
            http.Response(jsonEncode({'reply': 'Le combo vaut 120 \$.'}), 200),
      );

      await assistant.ask('C’est quoi le combo ?', language: 'fr');
      await assistant.ask('Et la livraison ?', language: 'fr');

      expect(assistant.messages.map((m) => m.fromPassenger), [
        true,
        false,
        true,
        false,
      ]);
      expect(sent.last['language'], 'fr');
      expect(sent.last['session_id'], Usage.instance.sessionId);
      expect((sent.last['messages'] as List).length, 3);
      expect((sent.last['messages'] as List).last, {
        'role': 'user',
        'content': 'Et la livraison ?',
      });
    });

    test('une panne est signalée sans perdre la question', () async {
      final assistant = controllerReplying(() => http.Response('{}', 503));

      await assistant.ask('Bonjour', language: 'fr');

      expect(assistant.failure, AssistantFailure.unavailable);
      expect(assistant.messages.single.text, 'Bonjour');
      expect(assistant.waiting, isFalse);
    });

    test(
      'le passager suivant ne voit pas la conversation précédente',
      () async {
        final assistant = controllerReplying(
          () => http.Response(jsonEncode({'reply': 'Oui'}), 200),
        );
        await assistant.ask('Question privée', language: 'fr');
        expect(assistant.messages, isNotEmpty);

        Usage.instance.sessionEnded();
        Usage.instance.sessionStarted('en');

        expect(assistant.messages, isEmpty);
      },
    );

    test('une question vide n’est pas envoyée', () async {
      final assistant = controllerReplying(() => http.Response('{}', 200));
      await assistant.ask('   ', language: 'fr');
      expect(sent, isEmpty);
    });
  });
}

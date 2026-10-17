import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../backend/backend.dart';
import '../backend/usage.dart';
import '../config.dart';
import 'bilingual.dart';

/// Un message de la conversation avec l'assistant.
@immutable
class ChatMessage {
  const ChatMessage.passenger(this.text) : fromPassenger = true;
  const ChatMessage.assistant(this.text) : fromPassenger = false;

  final String text;
  final bool fromPassenger;

  Map<String, String> toJson() => {
    'role': fromPassenger ? 'user' : 'assistant',
    'content': text,
  };
}

/// Pourquoi l'assistant n'a pas pu répondre.
enum AssistantFailure { offline, quota, filtered, unavailable }

class AssistantException implements Exception {
  const AssistantException(this.failure);
  final AssistantFailure failure;
}

/// Message affiché au passager pour chaque échec.
Bi failureMessage(AssistantFailure failure) => switch (failure) {
  AssistantFailure.offline => const Bi(
    'Pas de réseau pour le moment. Réessayez dans un instant.',
    'No network right now. Try again in a moment.',
  ),
  AssistantFailure.quota => const Bi(
    'Vous avez posé beaucoup de questions ! Pour la suite, écrivez à Yanis '
        'sur WhatsApp depuis la boutique.',
    'You asked a lot of questions! For more, message Yanis on WhatsApp from '
        'the store.',
  ),
  AssistantFailure.filtered => const Bi(
    'Je ne peux pas répondre à cette question. Essayez autrement ?',
    'I can’t answer that one. Try asking another way?',
  ),
  AssistantFailure.unavailable => const Bi(
    'Yan fait une pause. Réessayez plus tard.',
    'Yan is taking a break. Try again later.',
  ),
};

/// Questions proposées quand la conversation est vide.
const assistantSuggestions = [
  Bi('Que faire à Ottawa ce soir ?', 'What to do in Ottawa tonight?'),
  Bi('C’est quoi le combo à 140 \$ ?', 'What is the \$140 combo?'),
  Bi('Yanis peut-il créer mon site web ?', 'Can Yanis build my website?'),
  Bi('Comment commander un maillot ?', 'How do I order a jersey?'),
];

/// Conversation du passager en cours, oubliée à la fin de sa course.
class AssistantController extends ChangeNotifier {
  AssistantController({http.Client? client})
    : _client = client ?? http.Client();

  static final instance = AssistantController();

  final http.Client _client;
  final List<ChatMessage> _messages = [];
  String? _session;
  bool _waiting = false;
  AssistantFailure? _failure;

  List<ChatMessage> get messages {
    _forgetPreviousPassenger();
    return List.unmodifiable(_messages);
  }

  bool get waiting => _waiting;
  AssistantFailure? get failure => _failure;

  /// Nouvelle course : la conversation du passager précédent disparaît.
  void _forgetPreviousPassenger() {
    final session = Usage.instance.sessionId;
    if (session != _session) {
      _session = session;
      _messages.clear();
      _failure = null;
    }
  }

  Future<void> ask(String question, {required String language}) async {
    final text = question.trim();
    if (text.isEmpty || _waiting) return;
    _forgetPreviousPassenger();
    _messages.add(ChatMessage.passenger(text));
    _waiting = true;
    _failure = null;
    notifyListeners();
    Usage.instance.tap('assistant.ask');

    try {
      final answer = await _send(language);
      _messages.add(ChatMessage.assistant(answer));
    } on AssistantException catch (e) {
      _failure = e.failure;
    } catch (_) {
      _failure = AssistantFailure.offline;
    } finally {
      _waiting = false;
      notifyListeners();
    }
  }

  Future<String> _send(String language) async {
    if (!Backend.enabled) {
      throw const AssistantException(AssistantFailure.unavailable);
    }
    final response = await _client
        .post(
          Uri.parse('${AppConfig.supabaseUrl}/functions/v1/chat'),
          headers: {
            'apikey': AppConfig.supabaseKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'session_id': _session ?? '',
            'language': language,
            'messages': [for (final m in _messages) m.toJson()],
          }),
        )
        .timeout(const Duration(seconds: 30));
    return parseAssistantReply(response.statusCode, response.body);
  }
}

/// Lit la réponse de la fonction `chat`. Séparé pour pouvoir être testé.
String parseAssistantReply(int status, String body) {
  if (status == 429) throw const AssistantException(AssistantFailure.quota);
  if (status != 200) {
    throw const AssistantException(AssistantFailure.unavailable);
  }
  final json = jsonDecode(body);
  if (json is Map && json['filtered'] == true) {
    throw const AssistantException(AssistantFailure.filtered);
  }
  final reply = json is Map ? json['reply'] : null;
  if (reply is! String || reply.trim().isEmpty) {
    throw const AssistantException(AssistantFailure.unavailable);
  }
  return reply.trim();
}

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/backend.dart';
import '../backend/remote_config.dart';
import 'bilingual.dart';

@immutable
class PollOption {
  const PollOption(this.id, this.label, {this.photo, required this.colors});

  final String id;
  final Bi label;

  /// Photo de la carte ; sans photo, un dégradé de [colors].
  final String? photo;
  final List<Color> colors;
}

@immutable
class PollQuestion {
  const PollQuestion(this.id, this.question, this.options);

  final String id;
  final Bi question;
  final List<PollOption> options;
}

const _warm = [Color(0xFFE07A1F), Color(0xFF7A1F3D)];
const _cool = [Color(0xFF3AA6FF), Color(0xFF0B2A5B)];
const _green = [Color(0xFF18C29C), Color(0xFF0E4E52)];
const _violet = [Color(0xFFB57BFF), Color(0xFF3B1A6B)];

const pollQuestions = [
  PollQuestion(
    'ville',
    Bi('Quelle est votre ville préférée ?', "What's your favourite city?"),
    [
      PollOption(
        'montreal',
        Bi('Montréal', 'Montréal'),
        photo: 'assets/photos/city-montreal.jpg',
        colors: _cool,
      ),
      PollOption(
        'paris',
        Bi('Paris', 'Paris'),
        photo: 'assets/photos/city-paris.jpg',
        colors: _warm,
      ),
      PollOption(
        'tokyo',
        Bi('Tokyo', 'Tokyo'),
        photo: 'assets/photos/city-tokyo.jpg',
        colors: _violet,
      ),
      PollOption(
        'barcelone',
        Bi('Barcelone', 'Barcelona'),
        photo: 'assets/photos/city-barcelona.jpg',
        colors: _warm,
      ),
      PollOption(
        'londres',
        Bi('Londres', 'London'),
        photo: 'assets/photos/city-london.jpg',
        colors: _cool,
      ),
      PollOption(
        'amsterdam',
        Bi('Amsterdam', 'Amsterdam'),
        photo: 'assets/photos/city-amsterdam.jpg',
        colors: _green,
      ),
    ],
  ),
  PollQuestion(
    'saison',
    Bi(
      'Votre saison préférée à Montréal ?',
      'Your favourite season in Montréal?',
    ),
    [
      PollOption('hiver', Bi('Hiver', 'Winter'), colors: _cool),
      PollOption('printemps', Bi('Printemps', 'Spring'), colors: _green),
      PollOption('ete', Bi('Été', 'Summer'), colors: _warm),
      PollOption('automne', Bi('Automne', 'Fall'), colors: _violet),
    ],
  ),
  PollQuestion(
    'plat',
    Bi('Poutine ou smoked meat ?', 'Poutine or smoked meat?'),
    [
      PollOption('poutine', Bi('Poutine', 'Poutine'), colors: _warm),
      PollOption('smoked', Bi('Smoked meat', 'Smoked meat'), colors: _violet),
      PollOption(
        'bagel',
        Bi('Bagel de Montréal', 'Montréal bagel'),
        colors: _green,
      ),
    ],
  ),
  PollQuestion('soiree', Bi('Votre soirée idéale ?', 'Your ideal night out?'), [
    PollOption(
      'resto',
      Bi('Un bon restaurant', 'A great restaurant'),
      colors: _warm,
    ),
    PollOption(
      'match',
      Bi('Un match au Centre Bell', 'A game at the Bell Centre'),
      colors: _cool,
    ),
    PollOption('concert', Bi('Un concert', 'A concert'), colors: _violet),
    PollOption(
      'maison',
      Bi('Tranquille à la maison', 'A quiet night in'),
      colors: _green,
    ),
  ]),
  PollQuestion(
    'musique',
    Bi('Quelle musique pour la route ?', 'What music for the ride?'),
    [
      PollOption('rock', Bi('Rock', 'Rock'), colors: _violet),
      PollOption('pop', Bi('Pop', 'Pop'), colors: _warm),
      PollOption('rap', Bi('Rap', 'Hip-hop'), colors: _cool),
      PollOption('silence', Bi('Le silence', 'Silence'), colors: _green),
    ],
  ),
];

/// Question du jour : elle change chaque jour, la même pour tous les
/// passagers d'une même journée.
PollQuestion questionOfTheDay([DateTime? now]) {
  // Question imposée depuis le panneau d'administration, s'il y en a une.
  final forced = RemoteConfig.instance.setting('poll_question');
  for (final q in pollQuestions) {
    if (q.id == forced) return q;
  }
  final date = now ?? DateTime.now();
  final day = date.difference(DateTime(date.year)).inDays;
  return pollQuestions[day % pollQuestions.length];
}

/// Votes des passagers, gardés sur la tablette. Aucun nom ni donnée
/// personnelle : seulement un compteur par réponse.
class PollStore extends ChangeNotifier {
  PollStore._();

  static final instance = PollStore._();
  static const _key = 'poll_votes_v1';

  final Map<String, Map<String, int>> _votes = {};
  bool _loaded = false;

  /// Votes pas encore envoyés à la base (question, réponse).
  final List<(String, String)> _pending = [];

  /// Passager (numéro de session) qui a déjà voté, par question.
  final Map<String, int> _votedBy = {};

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      for (final q in json.entries) {
        _votes[q.key] = {
          for (final o in (q.value as Map<String, dynamic>).entries)
            o.key: (o.value as num).toInt(),
        };
      }
      notifyListeners();
    } catch (_) {
      // Stockage indisponible : le sondage marche quand même, sans mémoire.
    }
    await syncFromBackend();
  }

  /// Reprend les totaux de la base en ligne (toutes les tablettes, tous les
  /// passagers). Hors ligne, on garde les votes connus de cette tablette.
  Future<void> syncFromBackend() async {
    if (!Backend.enabled) return;
    try {
      // D'abord les votes restés sur la tablette faute de réseau.
      while (_pending.isNotEmpty) {
        final (question, choice) = _pending.first;
        await Backend.rpc('cast_vote', {
          'question': question,
          'choice': choice,
        });
        _pending.removeAt(0);
      }
      final rows = await Backend.select('poll_votes');
      _votes.clear();
      for (final r in rows) {
        _votes.putIfAbsent(r['question_id'] as String, () => {})[r['option_id']
            as String] = (r['votes'] as num)
            .toInt();
      }
      notifyListeners();
    } catch (_) {
      // Voir le commentaire de la méthode.
    }
  }

  int count(PollQuestion q, PollOption o) => _votes[q.id]?[o.id] ?? 0;

  int total(PollQuestion q) => q.options.fold(0, (sum, o) => sum + count(q, o));

  /// Part des votes, de 0 à 1.
  double share(PollQuestion q, PollOption o) {
    final all = total(q);
    return all == 0 ? 0 : count(q, o) / all;
  }

  bool hasVoted(PollQuestion q, int passenger) => _votedBy[q.id] == passenger;

  /// Un vote par passager et par question.
  Future<void> vote(PollQuestion q, PollOption o, int passenger) async {
    if (hasVoted(q, passenger)) return;
    _votedBy[q.id] = passenger;
    final answers = _votes.putIfAbsent(q.id, () => {});
    answers[o.id] = (answers[o.id] ?? 0) + 1;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_votes));
    } catch (_) {
      // Voir load().
    }
    if (Backend.enabled) {
      try {
        await Backend.rpc('cast_vote', {'question': q.id, 'choice': o.id});
      } catch (_) {
        // Hors ligne : le vote est gardé et renvoyé à la prochaine
        // synchronisation.
        _pending.add((q.id, o.id));
      }
    }
  }

  /// Pour les tests.
  @visibleForTesting
  void clear() {
    _votes.clear();
    _votedBy.clear();
    _pending.clear();
  }
}

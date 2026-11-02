import 'package:flutter/foundation.dart';

import '../backend/backend.dart';
import 'advertisers.dart' show advertiserSlug;
import 'bilingual.dart';

/// Seules les sorties de la région sont affichées.
const activityCities = ['Ottawa', 'Gatineau'];

/// Sortie à proposer aux passagers : concert, film, match, festival…
@immutable
class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.venue,
    required this.city,
    required this.startsAt,
    this.link,
    this.photoUrl,
  });

  /// Ligne de la table `activities`, ou `null` si elle n'est pas affichable.
  static Activity? fromRow(Map<String, dynamic> r) {
    String text(String key) => '${r[key] ?? ''}'.trim();
    String? link(String key) {
      final v = text(key);
      return v.startsWith('https://') ? v : null;
    }

    final city = text('city');
    final start = DateTime.tryParse(text('starts_at'));
    if (start == null || !activityCities.contains(city)) return null;

    final fr = text('title_fr');
    final en = text('title_en');
    return Activity(
      id: text('id'),
      title: Bi(fr.isEmpty ? en : fr, en.isEmpty ? fr : en),
      venue: text('venue'),
      city: city,
      startsAt: start.toLocal(),
      link: link('link'),
      photoUrl: link('photo_url'),
    );
  }

  final String id;
  final Bi title;
  final String venue;
  final String city;
  final DateTime startsAt;

  /// Billetterie ou page de l'évènement, montrée en QR code.
  final String? link;
  final String? photoUrl;
}

/// Les activités d'aujourd'hui et des jours suivants, les plus proches d'abord.
List<Activity> upcomingActivities(Iterable<Activity> all, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return all.where((a) => !a.startsAt.isBefore(today)).toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
}

/// Ligne à enregistrer à partir du formulaire de l'admin, ou un message
/// d'erreur lisible.
(Map<String, dynamic>?, String?) activityRowFrom(
  Map<String, String> form, {
  required String city,
  String? id,
}) {
  String text(String key) => (form[key] ?? '').trim();
  final title = text('title_fr');
  if (title.isEmpty) return (null, 'Le titre en français est obligatoire.');
  if (!activityCities.contains(city)) {
    return (null, 'Choisis Ottawa ou Gatineau.');
  }
  final start = DateTime.tryParse(text('starts_at'));
  if (start == null) {
    return (null, 'Date : écris-la ainsi, 2026-11-20 20:00.');
  }
  for (final key in ['link', 'photo_url']) {
    if (text(key).isNotEmpty && !text(key).startsWith('https://')) {
      return (null, 'Les liens doivent commencer par https://');
    }
  }
  final day = text('starts_at').substring(0, 10);
  final slug = '$day-${advertiserSlug(title)}';
  return (
    {
      'id': id ?? (slug.length > 60 ? slug.substring(0, 60) : slug),
      'title_fr': title,
      'title_en': text('title_en'),
      'venue': text('venue'),
      'city': city,
      'starts_at': start.toUtc().toIso8601String(),
      'link': text('link').isEmpty ? null : text('link'),
      'photo_url': text('photo_url').isEmpty ? null : text('photo_url'),
    },
    null,
  );
}

/// Activités saisies dans l'admin. Aucune fiche d'exemple : on n'affiche
/// jamais une fausse sortie à un passager.
class ActivityStore extends ChangeNotifier {
  ActivityStore._();

  static final instance = ActivityStore._();

  List<Activity> _all = const [];
  bool loading = false;
  bool failed = false;

  List<Activity> get list => upcomingActivities(_all, DateTime.now());

  Future<void> load() async {
    if (!Backend.enabled || loading) return;
    loading = true;
    failed = false;
    notifyListeners();
    try {
      final rows = await Backend.select('activities', order: 'starts_at.asc');
      _all = [
        for (final r in rows)
          if (r['active'] != false) ?Activity.fromRow(r),
      ];
    } catch (_) {
      // Pas de réseau : on garde ce qu'on avait et l'écran le signale s'il est vide.
      failed = true;
    }
    loading = false;
    notifyListeners();
  }

  @visibleForTesting
  void setForTest(List<Activity> all) {
    _all = all;
    notifyListeners();
  }
}

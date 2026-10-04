import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../theme/app_icons.dart';
import 'bilingual.dart';

/// Rubrique d'actualités : un fil RSS par langue.
/// Français : Radio-Canada. Anglais : CBC. On n'affiche que le titre, le
/// résumé fourni par le fil et un lien vers l'article d'origine.
@immutable
class NewsTopic {
  const NewsTopic(this.label, this.icon, this.frenchFeed, this.englishFeed);

  final Bi label;
  final IconData icon;
  final String frenchFeed;
  final String englishFeed;

  String feed(String languageCode) =>
      languageCode == 'en' ? englishFeed : frenchFeed;
}

const newsSource = Bi('Radio-Canada', 'CBC News');

const newsTopics = [
  NewsTopic(
    Bi('À la une', 'Top stories'),
    AppIcons.newspaper,
    'https://ici.radio-canada.ca/rss/4159',
    'https://www.cbc.ca/webfeed/rss/rss-topstories',
  ),
  NewsTopic(
    Bi('Montréal', 'Montréal'),
    AppIcons.buildings,
    'https://ici.radio-canada.ca/rss/4201',
    'https://www.cbc.ca/webfeed/rss/rss-canada-montreal',
  ),
  NewsTopic(
    Bi('Sport', 'Sports'),
    AppIcons.trophy,
    'https://ici.radio-canada.ca/rss/771',
    'https://www.cbc.ca/webfeed/rss/rss-sports',
  ),
  NewsTopic(
    Bi('Économie', 'Business'),
    AppIcons.chartLineUp,
    'https://ici.radio-canada.ca/rss/5717',
    'https://www.cbc.ca/webfeed/rss/rss-business',
  ),
  NewsTopic(
    Bi('Monde', 'World'),
    AppIcons.globe,
    'https://ici.radio-canada.ca/rss/96',
    'https://www.cbc.ca/webfeed/rss/rss-world',
  ),
];

@immutable
class NewsItem {
  const NewsItem({
    required this.title,
    required this.summary,
    required this.link,
    this.image,
    this.date,
  });

  final String title;
  final String summary;
  final String link;
  final String? image;
  final DateTime? date;
}

abstract final class NewsService {
  static final _cache = <String, (DateTime, List<NewsItem>)>{};
  static const _keep = Duration(minutes: 10);

  static Future<List<NewsItem>> fetch(String feedUrl) async {
    final hit = _cache[feedUrl];
    if (hit != null && DateTime.now().difference(hit.$1) < _keep) return hit.$2;

    List<NewsItem> items;
    try {
      final response = await http
          .get(Uri.parse(feedUrl))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) throw Exception(response.statusCode);
      items = parseRss(utf8.decode(response.bodyBytes));
    } catch (_) {
      // Dans un navigateur, certains fils refusent l'accès direct : on passe
      // alors par un relais public qui les convertit en JSON.
      items = await _viaRelay(feedUrl);
    }
    _cache[feedUrl] = (DateTime.now(), items);
    return items;
  }

  static Future<List<NewsItem>> _viaRelay(String feedUrl) async {
    final uri = Uri.https('api.rss2json.com', '/v1/api.json', {
      'rss_url': feedUrl,
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw Exception(response.statusCode);
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    return [
      for (final e in (json['items'] as List).cast<Map<String, dynamic>>())
        NewsItem(
          title: _plain(e['title'] as String? ?? ''),
          summary: _plain(e['description'] as String? ?? ''),
          link: e['link'] as String? ?? '',
          image:
              _nonEmpty(e['thumbnail'] as String?) ??
              _nonEmpty((e['enclosure'] as Map?)?['link'] as String?),
          date: DateTime.tryParse(
            '${(e['pubDate'] as String? ?? '').replaceFirst(' ', 'T')}Z',
          ),
        ),
    ];
  }
}

String? _nonEmpty(String? s) => (s == null || s.isEmpty) ? null : s;

final _tag = RegExp(r'<[^>]+>');
final _imgSrc = RegExp(r'''<img[^>]+src=['"]([^'"]+)['"]''');

/// Texte sans balises ni entités HTML.
String _plain(String html) => html
    .replaceAll(_tag, ' ')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#x27;', '’')
    .replaceAll('&#39;', '’')
    .replaceAll('&apos;', '’')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Lit un fil RSS 2.0. Séparé pour pouvoir être testé.
List<NewsItem> parseRss(String source) {
  final document = XmlDocument.parse(source);
  final items = <NewsItem>[];
  for (final item in document.findAllElements('item')) {
    String text(String name) => item.getElement(name)?.innerText.trim() ?? '';
    final description = text('description');
    final image =
        item.getElement('enclosure')?.getAttribute('url') ??
        _imgSrc.firstMatch(description)?.group(1);
    final title = _plain(text('title'));
    if (title.isEmpty) continue;
    items.add(
      NewsItem(
        title: title,
        summary: _plain(description),
        link: text('link'),
        image: _nonEmpty(image),
        date: parseRssDate(text('pubDate')),
      ),
    );
  }
  return items;
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _zones = {'GMT': 0, 'UTC': 0, 'EDT': -4, 'EST': -5};
final _rssDate = RegExp(
  r'(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) ?([A-Z]{3}|[+-]\d{4})?',
);

/// Date d'un fil RSS ("Sun, 04 Oct 2026 04:18:05 GMT"), en heure universelle.
DateTime? parseRssDate(String value) {
  final m = _rssDate.firstMatch(value);
  if (m == null) return null;
  final month = _months.indexOf(m.group(2)!) + 1;
  if (month == 0) return null;
  final zone = m.group(7) ?? 'GMT';
  final double offset;
  if (_zones.containsKey(zone)) {
    offset = _zones[zone]!.toDouble();
  } else if (zone.length == 5) {
    final sign = zone.startsWith('-') ? -1 : 1;
    offset =
        sign *
        (int.parse(zone.substring(1, 3)) + int.parse(zone.substring(3)) / 60);
  } else {
    offset = 0;
  }
  return DateTime.utc(
    int.parse(m.group(3)!),
    month,
    int.parse(m.group(1)!),
    int.parse(m.group(4)!),
    int.parse(m.group(5)!),
    int.parse(m.group(6)!),
  ).subtract(Duration(minutes: (offset * 60).round()));
}

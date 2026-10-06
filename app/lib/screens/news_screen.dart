import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/bilingual.dart';
import '../data/news.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/mesh_background.dart';
import '../widgets/section_scaffold.dart';

/// Actualités : les titres du moment par rubrique. L'article complet se lit
/// sur le téléphone du passager, grâce au code QR.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  int _topic = 0;
  int _selected = 0;
  String? _language;
  Future<List<NewsItem>>? _items;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Le fil dépend de la langue : on recharge si le passager en change.
    final language = Localizations.localeOf(context).languageCode;
    if (language != _language) {
      _language = language;
      _load();
    }
  }

  void _load() {
    _selected = 0;
    _items = NewsService.fetch(newsTopics[_topic].feed(_language!));
  }

  void _selectTopic(int i) => setState(() {
    _topic = i;
    _load();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final compact = MediaQuery.sizeOf(context).width < 900;

    return SectionScaffold(
      scene: Scene.news,
      title: l10n.sectionNews,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: newsTopics.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _TopicChip(
                topic: newsTopics[i],
                selected: i == _topic,
                onTap: () => _selectTopic(i),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<NewsItem>>(
              future: _items,
              builder: (context, snapshot) {
                // Pendant un nouvel essai, on montre le chargement, pas
                // l'ancienne erreur.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Brand.gold),
                  );
                }
                if (snapshot.hasError ||
                    (snapshot.connectionState == ConnectionState.done &&
                        (snapshot.data?.isEmpty ?? true))) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.wifiSlash, size: 56, color: p.textMuted),
                        const SizedBox(height: 14),
                        Text(
                          const Bi(
                            'Actualités indisponibles pour le moment.',
                            'News is unavailable right now.',
                          ).of(context),
                          style: AppText.body(17, color: p.textMuted),
                        ),
                        const SizedBox(height: 18),
                        PillButton(
                          label: const Bi('Réessayer', 'Try again').of(context),
                          filled: false,
                          onTap: () => setState(_load),
                          trailing: const Icon(AppIcons.refresh),
                        ),
                      ],
                    ),
                  );
                }
                final items = snapshot.data;
                if (snapshot.connectionState != ConnectionState.done ||
                    items == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Brand.gold),
                  );
                }
                final shown = items.take(20).toList();
                final current = shown[_selected.clamp(0, shown.length - 1)];

                final list = ListView.builder(
                  shrinkWrap: compact,
                  physics: compact
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  itemCount: shown.length,
                  itemBuilder: (context, i) =>
                      _Headline(
                            item: shown[i],
                            selected: !compact && i == _selected,
                            onTap: () {
                              setState(() => _selected = i);
                              if (compact) _openSheet(context, shown[i]);
                            },
                          )
                          .animate()
                          .fadeIn(delay: (40 * i).ms, duration: 400.ms)
                          .slideY(begin: 0.08, delay: (40 * i).ms),
                );

                if (compact) return ListView(children: [list]);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 6, child: list),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 5,
                      child: AnimatedSwitcher(
                        duration: AppMotion.medium,
                        switchInCurve: AppMotion.spring,
                        child: _Article(
                          key: ValueKey(current.link),
                          item: current,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openSheet(BuildContext context, NewsItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.86,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _Article(item: item),
        ),
      ),
    );
  }
}

/// "il y a 2 h" / "2 h ago".
String _ago(BuildContext context, DateTime? date) {
  if (date == null) return '';
  final en = Localizations.localeOf(context).languageCode == 'en';
  final d = DateTime.now().toUtc().difference(date);
  if (d.inMinutes < 1) return en ? 'just now' : 'à l’instant';
  if (d.inMinutes < 60) {
    return en ? '${d.inMinutes} min ago' : 'il y a ${d.inMinutes} min';
  }
  if (d.inHours < 24) {
    return en ? '${d.inHours} h ago' : 'il y a ${d.inHours} h';
  }
  return en ? '${d.inDays} d ago' : 'il y a ${d.inDays} j';
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.topic,
    required this.selected,
    required this.onTap,
  });

  final NewsTopic topic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? Colors.white : p.text;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.spring,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? const Color(0xFF2F7FE0) : p.glass,
          border: Border.all(
            color: selected ? const Color(0xFF2F7FE0) : p.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(topic.icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(
              topic.label.of(context),
              style: AppText.body(15, weight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _Picture extends StatelessWidget {
  const _Picture({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final placeholder = ColoredBox(
      color: p.hairline,
      child: Center(
        child: Icon(AppIcons.newspaper, color: p.textMuted, size: 28),
      ),
    );
    if (url == null) return placeholder;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      // Image inaccessible (réseau, ou refusée par le navigateur) : neutre.
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NewsItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: selected
                ? const Color(0xFF2F7FE0).withValues(alpha: 0.18)
                : p.glass,
            border: Border.all(
              color: selected ? const Color(0xFF3AA6FF) : p.hairline,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 112,
                  height: 72,
                  child: _Picture(url: item.image),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        16,
                        weight: FontWeight.w600,
                        color: p.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ago(context, item.date),
                      style: AppText.body(12, color: p.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nouvelle sélectionnée : photo, titre, résumé et code QR vers l'article.
class _Article extends StatelessWidget {
  const _Article({super.key, required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BezelCard(
      radius: 34,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _Picture(url: item.image),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${newsSource.of(context)}  ·  ${_ago(context, item.date)}'
                        .toUpperCase(),
                    style: AppText.eyebrow(const Color(0xFF3AA6FF)),
                  ),
                  const SizedBox(height: 8),
                  Text(item.title, style: AppText.display(30, color: p.text)),
                  if (item.summary.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.summary,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        16,
                        color: p.textMuted,
                      ).copyWith(height: 1.45),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: item.link,
                          size: 104,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              AppIcons.qrCode,
                              color: p.accentText,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              const Bi(
                                'Lisez la suite sur votre téléphone',
                                'Read the full story on your phone',
                              ).of(context),
                              style: AppText.body(
                                16,
                                weight: FontWeight.w600,
                                color: p.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              const Bi(
                                'Visez le code avec l’appareil photo.',
                                'Point your camera at the code.',
                              ).of(context),
                              style: AppText.body(13, color: p.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/alerts.dart';
import '../data/bilingual.dart';
import '../data/news.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

/// Bandeau d'informations importantes pour les passagers : alertes météo
/// officielles, grand froid ou tempête annoncés, message du chauffeur, puis
/// la dernière nouvelle de la région. Invisible quand il n'y a rien à dire.
///
/// Les messages défilent un par un ; toucher le bandeau les montre tous.
class AlertBanner extends StatefulWidget {
  const AlertBanner({super.key, this.bottomGap = 16});

  /// Espace sous le bandeau quand il est affiché.
  final double bottomGap;

  /// Temps d'affichage de chaque message.
  static const rotation = Duration(seconds: 8);

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner> {
  List<RegionAlert> _alerts = const [];
  RegionAlert? _headline;
  String? _language;
  int _index = 0;
  Timer? _timer;

  List<RegionAlert> get _items => [..._alerts, ?_headline];

  @override
  void initState() {
    super.initState();
    AlertService.fetch().then((alerts) {
      if (mounted) setState(() => _alerts = alerts);
    });
    // Un minuteur, pas une animation : rien n'est redessiné entre deux
    // changements de message.
    _timer = Timer.periodic(AlertBanner.rotation, (_) {
      if (_items.length > 1) setState(() => _index++);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (language == _language) return;
    _language = language;
    _loadHeadline(language);
  }

  Future<void> _loadHeadline(String language) async {
    try {
      final items = await NewsService.fetch(newsTopics[1].feed(language));
      if (!mounted || items.isEmpty || language != _language) return;
      final title = items.first.title;
      setState(
        () => _headline = RegionAlert(
          key: 'news',
          title: Bi(
            'À la une · ${newsTopics[1].label.fr}',
            'Top story · ${newsTopics[1].label.en}',
          ),
          body: Bi(title, title),
          level: AlertLevel.info,
          icon: AppIcons.newspaper,
          source: newsSource,
        ),
      );
    } catch (_) {
      // Pas de nouvelle : le bandeau montre seulement les alertes.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();
    final alert = items[_index % items.length];
    final color = alertColor(alert.level);
    // Écran bas (petite tablette) : bandeau plus mince, pour laisser la place
    // aux cartes du lounge.
    final slim = MediaQuery.sizeOf(context).height < 700;
    final dot = slim ? 30.0 : 40.0;

    return Padding(
      padding: EdgeInsets.only(bottom: slim ? 10 : widget.bottomGap),
      child: Semantics(
        button: true,
        label: '${alert.title.of(context)}. ${alert.body.of(context)}',
        excludeSemantics: true,
        child: Pressable(
          onTap: () => showAlertsSheet(context, items),
          child: LiquidPill(
            radius: 22,
            padding: EdgeInsets.fromLTRB(10, slim ? 5 : 10, 18, slim ? 5 : 10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Row(
                key: ValueKey(alert.key + alert.body.of(context)),
                children: [
                  Container(
                    width: dot,
                    height: dot,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.18),
                      border: Border.all(color: color.withValues(alpha: 0.6)),
                    ),
                    child: Icon(alert.icon, size: dot * 0.55, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${alert.title.of(context)}  ',
                            style: AppText.body(
                              16,
                              weight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          TextSpan(
                            text: alert.body.of(context),
                            style: AppText.body(
                              15,
                              color: context.palette.text,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (items.length > 1) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${_index % items.length + 1}/${items.length}',
                      style: AppText.body(13, color: context.palette.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Couleur d'une alerte selon sa gravité.
Color alertColor(AlertLevel level) => switch (level) {
  AlertLevel.warning => const Color(0xFFFF5A4E),
  AlertLevel.watch => const Color(0xFFFF9F43),
  AlertLevel.advisory => const Color(0xFFFFC94D),
  AlertLevel.statement => const Color(0xFF7FC8FF),
  AlertLevel.info => Brand.gold,
};

/// Toutes les alertes en détail, avec leur source.
Future<void> showAlertsSheet(BuildContext context, List<RegionAlert> alerts) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final p = context.palette;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: LiquidPill(
              radius: 28,
              solid: true,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    const Bi(
                      'À savoir aujourd’hui',
                      'Good to know today',
                    ).of(context),
                    style: AppText.display(30, color: p.text),
                  ),
                  const SizedBox(height: 12),
                  for (final alert in alerts)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            alert.icon,
                            size: 26,
                            color: alertColor(alert.level),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alert.title.of(context),
                                  style: AppText.body(
                                    17,
                                    weight: FontWeight.w600,
                                    color: alertColor(alert.level),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alert.body.of(context),
                                  style: AppText.body(15, color: p.text),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alert.source.of(context),
                                  style: AppText.body(12, color: p.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: PillButton(
                      label: const Bi('Fermer', 'Close').of(context),
                      filled: false,
                      onTap: () => Navigator.of(context).pop(),
                      trailing: const Icon(AppIcons.close),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

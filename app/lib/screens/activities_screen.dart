import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../backend/usage.dart';
import '../data/activities.dart';
import '../data/bilingual.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/mesh_background.dart';
import '../widgets/qr_card.dart';
import '../widgets/section_scaffold.dart';

/// Sorties à venir à Ottawa et à Gatineau. Le détail se garde sur le
/// téléphone du passager, grâce au code QR.
class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final _store = ActivityStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    _store.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activities = _store.list;
    final columns = MediaQuery.sizeOf(context).width < 900 ? 1 : 2;

    return SectionScaffold(
      scene: Scene.news,
      title: const Bi('Sortir', 'Going out').of(context),
      child: activities.isNotEmpty
          ? GridView.builder(
              itemCount: activities.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 124,
              ),
              itemBuilder: (context, i) => _Card(activity: activities[i]),
            )
          : _Empty(store: _store),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.store});

  final ActivityStore store;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (store.loading) {
      return const Center(child: CircularProgressIndicator(color: Brand.gold));
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            store.failed ? AppIcons.wifiSlash : AppIcons.mapPin,
            size: 56,
            color: p.textMuted,
          ),
          const SizedBox(height: 14),
          Text(
            store.failed
                ? const Bi(
                    'Activités indisponibles pour le moment.',
                    'Activities are unavailable right now.',
                  ).of(context)
                : const Bi(
                    'Aucune activité à venir pour le moment.',
                    'No upcoming activities right now.',
                  ).of(context),
            style: AppText.body(17, color: p.textMuted),
          ),
          if (store.failed) ...[
            const SizedBox(height: 18),
            PillButton(
              label: const Bi('Réessayer', 'Try again').of(context),
              filled: false,
              onTap: store.load,
              trailing: const Icon(AppIcons.refresh),
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final p = context.palette;
    final locale = Localizations.localeOf(context).languageCode;
    final date =
        '${DateFormat.MMMEd(locale).format(a.startsAt)} · '
        '${DateFormat.Hm(locale).format(a.startsAt)}';
    final place = [a.venue, a.city].where((t) => t.isNotEmpty).join(', ');
    final title = a.title.of(context);

    void open() {
      Usage.instance.tap('activities.open:${a.id}');
      if (a.link != null) _showQr(context, title, a.link!);
    }

    return Semantics(
      button: a.link != null,
      label: '$title, $date, $place',
      excludeSemantics: true,
      onTap: a.link == null ? null : open,
      child: Pressable(
        onTap: a.link == null ? null : open,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: p.glass,
            border: Border.all(color: p.hairline),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.square(
                  dimension: 100,
                  child: _Picture(url: a.photoUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        13,
                        weight: FontWeight.w600,
                        color: Brand.gold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        17,
                        weight: FontWeight.w600,
                        color: p.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(13, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              if (a.link != null) ...[
                const SizedBox(width: 10),
                Icon(AppIcons.qrCode, size: 26, color: p.textMuted),
                const SizedBox(width: 6),
              ],
            ],
          ),
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
    final fallback = ColoredBox(
      color: p.glass,
      child: Icon(AppIcons.mapPin, size: 34, color: p.textMuted),
    );
    if (url == null) return fallback;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

void _showQr(BuildContext context, String title, String link) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Semantics(
          container: true,
          image: true,
          label: const Bi('Code QR : ', 'QR code: ').of(context) + title,
          excludeSemantics: true,
          child: QrCard(
            data: link,
            icon: AppIcons.mapPin,
            label: title,
            size: 240,
          ),
        ),
      ),
    ),
  );
}

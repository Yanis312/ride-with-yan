import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_localizations.dart';
import '../session/session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/road_logo.dart';

/// Menu principal affiché une fois la langue choisie.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.of(context);

    final sections = [
      _Section(Icons.person_rounded, l10n.sectionAbout, l10n.sectionAboutHint),
      _Section(Icons.play_circle_rounded, l10n.sectionEntertainment, l10n.sectionEntertainmentHint),
      _Section(Icons.how_to_vote_rounded, l10n.sectionPoll, l10n.sectionPollHint),
      _Section(Icons.newspaper_rounded, l10n.sectionNews, l10n.sectionNewsHint),
      _Section(Icons.wb_sunny_rounded, l10n.sectionWeather, l10n.sectionWeatherHint),
      _Section(Icons.shopping_bag_rounded, l10n.sectionStore, l10n.sectionStoreHint),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Appui long sur le logo : geste discret du conducteur
                  // pour revenir à l'accueil entre deux courses.
                  Tooltip(
                    message: l10n.backToWelcome,
                    child: GestureDetector(
                      onLongPress: session.reset,
                      child: const RoadLogo(size: 56),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeGreeting,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          l10n.homeSubtitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: session.switchLanguage,
                    icon: const Icon(Icons.translate_rounded),
                    label: Text(l10n.switchLanguage),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.textMuted),
                      minimumSize: const Size(0, 52),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 32),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 900
                        ? 3
                        : constraints.maxWidth > 560
                            ? 2
                            : 1;
                    return GridView.count(
                      crossAxisCount: columns,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: columns == 1 ? 2.6 : 1.5,
                      children: [
                        for (final section in sections) _SectionTile(section: section),
                      ]
                          .animate(interval: 70.ms)
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.15, curve: Curves.easeOutCubic),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section {
  const _Section(this.icon, this.title, this.hint);

  final IconData icon;
  final String title;
  final String hint;
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('${section.title} : ${l10n.comingSoon}')));
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(section.icon, size: 44, color: AppColors.amber),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    section.hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

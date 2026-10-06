import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/bilingual.dart';
import '../data/poll.dart';
import '../l10n/app_localizations.dart';
import '../session/session_controller.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/mesh_background.dart';
import '../widgets/section_scaffold.dart';

/// Question du jour : le passager touche sa réponse, puis voit ce qu'ont
/// répondu les autres passagers.
class PollScreen extends StatefulWidget {
  const PollScreen({super.key});

  @override
  State<PollScreen> createState() => _PollScreenState();
}

class _PollScreenState extends State<PollScreen> {
  final _store = PollStore.instance;
  late int _index = pollQuestions.indexOf(questionOfTheDay());

  @override
  void initState() {
    super.initState();
    // Totaux à jour à chaque ouverture (la première charge aussi la copie
    // gardée sur la tablette).
    _store.load().then((_) => _store.syncFromBackend());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final passenger = SessionScope.of(context).generation;
    final question = pollQuestions[_index];
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < 760 ? 2 : (question.options.length > 4 ? 3 : 2);

    return SectionScaffold(
      scene: Scene.poll,
      title: l10n.sectionPoll,
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final voted = _store.hasVoted(question, passenger);
          final total = _store.total(question);
          final best = question.options
              .map((o) => _store.count(question, o))
              .reduce((a, b) => a > b ? a : b);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                              question.question.of(context),
                              style: AppText.display(
                                width < 760 ? 34 : 50,
                                style: FontStyle.italic,
                                color: p.text,
                              ),
                            )
                            .animate(key: ValueKey(question.id))
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.2, curve: AppMotion.spring),
                        const SizedBox(height: 6),
                        Text(
                          voted
                              ? Bi(
                                  'Merci ! $total vote${total > 1 ? 's' : ''} jusqu’ici.',
                                  'Thank you! $total vote${total > 1 ? 's' : ''} so far.',
                                ).of(context)
                              : const Bi(
                                  'Touchez votre réponse pour voir les résultats.',
                                  'Tap your answer to see the results.',
                                ).of(context),
                          style: AppText.body(16, color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  PillButton(
                    label: const Bi(
                      'Autre question',
                      'Another question',
                    ).of(context),
                    filled: false,
                    onTap: () => setState(
                      () => _index = (_index + 1) % pollQuestions.length,
                    ),
                    trailing: const Icon(AppIcons.arrowRight),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    const gap = 14.0;
                    final rows = (question.options.length / columns).ceil();
                    final w = (c.maxWidth - gap * (columns - 1)) / columns;
                    final h = ((c.maxHeight - gap * (rows - 1)) / rows).clamp(
                      130.0,
                      420.0,
                    );
                    return SingleChildScrollView(
                      child: Wrap(
                        key: ValueKey(question.id),
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final (i, o) in question.options.indexed)
                            SizedBox(
                                  width: w,
                                  height: h,
                                  child: _OptionCard(
                                    option: o,
                                    share: _store.share(question, o),
                                    showResult: voted,
                                    leading:
                                        voted &&
                                        best > 0 &&
                                        _store.count(question, o) == best,
                                    onTap: voted
                                        ? null
                                        : () => _store.vote(
                                            question,
                                            o,
                                            passenger,
                                          ),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: (60 * i).ms, duration: 500.ms)
                                .scaleXY(
                                  begin: 0.94,
                                  delay: (60 * i).ms,
                                  curve: AppMotion.spring,
                                ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.share,
    required this.showResult,
    required this.leading,
    required this.onTap,
  });

  final PollOption option;
  final double share;
  final bool showResult;
  final bool leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final photo = option.photo;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: leading ? Brand.gold : Colors.white24,
            width: leading ? 2.5 : 1,
          ),
          boxShadow: [
            if (leading)
              BoxShadow(
                color: Brand.gold.withValues(alpha: 0.45),
                blurRadius: 30,
              ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null)
              Image.asset(photo, fit: BoxFit.cover)
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: option.colors,
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xDD000000)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            if (leading)
              const Positioned(
                right: 14,
                top: 14,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Brand.gold,
                  child: Icon(AppIcons.crown, size: 22, color: Brand.ink),
                ),
              ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          option.label.of(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.display(30, color: Colors.white),
                        ),
                      ),
                      if (showResult)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: share),
                          duration: const Duration(milliseconds: 900),
                          curve: AppMotion.emphasized,
                          builder: (context, v, _) => Text(
                            '${(v * 100).round()} %',
                            style: AppText.body(
                              24,
                              weight: FontWeight.w800,
                              color: leading ? Brand.gold : Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (showResult) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: share),
                        duration: const Duration(milliseconds: 900),
                        curve: AppMotion.emphasized,
                        builder: (context, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation(
                            leading ? Brand.gold : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

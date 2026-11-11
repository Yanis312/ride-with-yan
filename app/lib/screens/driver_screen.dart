import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/bilingual.dart';
import '../data/driver.dart';
import '../data/profile.dart';
import '../navigation/sections.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/mesh_background.dart';
import '../widgets/section_scaffold.dart';

/// « Votre chauffeur » : qui est Yanis, les langues qu'il parle, les pays
/// qu'il a visités et ses photos de voyage.
class DriverScreen extends StatelessWidget {
  const DriverScreen({super.key});

  static const title = Bi('Votre chauffeur', 'Your driver');

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    return SectionScaffold(
      scene: Scene.profile,
      section: Section.driver,
      title: title.of(context),
      child: compact
          ? ListView(
              children: const [
                SizedBox(height: 480, child: _Slideshow()),
                SizedBox(height: 20),
                _About(),
              ],
            )
          : const Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: _Slideshow()),
                SizedBox(width: 32),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(child: _About()),
                ),
              ],
            ),
    );
  }
}

/// Photos de voyage qui défilent seules ; on peut aussi glisser.
class _Slideshow extends StatefulWidget {
  const _Slideshow();

  @override
  State<_Slideshow> createState() => _SlideshowState();
}

class _SlideshowState extends State<_Slideshow> {
  final _pages = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pages.hasClients) return;
      final next = (_index + 1) % Driver.photos.length;
      _pages.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: AppMotion.emphasized,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: Driver.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final photo = Driver.photos[i];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Fond flou de la même photo, puis la photo entière.
                  Image.asset(
                    photo.asset,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    color: Colors.black45,
                    colorBlendMode: BlendMode.darken,
                  ),
                  Image.asset(
                    photo.asset,
                    fit: BoxFit.contain,
                    semanticLabel: photo.place.of(context),
                  ),
                ],
              );
            },
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.6, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 18,
            child: IgnorePointer(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      Driver.photos[_index].place.of(context),
                      key: ValueKey(_index),
                      style: AppText.display(30, color: Colors.white),
                    ).animate().fadeIn(duration: 400.ms),
                  ),
                  for (var i = 0; i < Driver.photos.length; i++)
                    AnimatedContainer(
                      duration: AppMotion.medium,
                      margin: const EdgeInsets.only(left: 6),
                      width: i == _index ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _index ? Brand.gold : Colors.white54,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget heading(Bi text) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        text.of(context).toUpperCase(),
        style: AppText.body(
          13,
          weight: FontWeight.w700,
          color: Brand.gold,
        ).copyWith(letterSpacing: 2),
      ),
    );

    Widget chip(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.hairline),
      ),
      child: Text(
        text,
        style: AppText.body(15, weight: FontWeight.w600, color: p.text),
      ),
    );

    return BezelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 84,
                height: 84,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Brand.goldSoft, Brand.gold],
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    Profile.avatar,
                    fit: BoxFit.cover,
                    semanticLabel: Driver.firstName,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      const Bi('Bonjour, je suis', 'Hi, I’m').of(context),
                      style: AppText.body(16, color: p.textMuted),
                    ),
                    Text(
                      Driver.firstName,
                      style: AppText.display(46, color: p.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            Driver.story.of(context),
            style: AppText.body(17, color: p.text).copyWith(height: 1.5),
          ),
          heading(const Bi('Je parle', 'I speak')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final l in Driver.languages) chip(l.of(context))],
          ),
          heading(
            Bi(
              '${Driver.countries.length} pays où j’ai vécu ou voyagé',
              '${Driver.countries.length} countries I’ve lived in or visited',
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (flag, name) in Driver.countries)
                chip('$flag  ${name.of(context)}'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
  }
}

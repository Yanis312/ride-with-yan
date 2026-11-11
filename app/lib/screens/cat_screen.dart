import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/bilingual.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/mesh_background.dart';
import '../widgets/section_scaffold.dart';

/// « Mon chat » : Obama, le chat noir de Yanis.
class CatScreen extends StatelessWidget {
  const CatScreen({super.key});

  static const label = Bi('Mon chat', 'My cat');
  static const name = 'Obama';
  static const born = 2022;

  /// Photos d'Obama, dans assets/cat/. Vide : une illustration les remplace.
  static const photos = ['assets/cat/obama-2.jpg', 'assets/cat/obama-1.jpg'];

  static const story = Bi(
    'Voici Obama, mon chat noir, né en $born. C’est lui le vrai patron à la '
        'maison !',
    'Meet Obama, my black cat, born in $born. He’s the real boss at home!',
  );

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    return SectionScaffold(
      scene: Scene.profile,
      title: label.of(context),
      child: compact
          ? ListView(
              children: const [
                SizedBox(height: 460, child: _Photos()),
                SizedBox(height: 20),
                _Card(),
              ],
            )
          : const Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: _Photos()),
                SizedBox(width: 32),
                Expanded(flex: 5, child: Center(child: _Card())),
              ],
            ),
    );
  }
}

class _Photos extends StatefulWidget {
  const _Photos();

  @override
  State<_Photos> createState() => _PhotosState();
}

class _PhotosState extends State<_Photos> {
  final _pages = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (CatScreen.photos.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!_pages.hasClients) return;
        final next = ((_pages.page ?? 0).round() + 1) % CatScreen.photos.length;
        _pages.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: AppMotion.emphasized,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: CatScreen.photos.isEmpty
          ? ColoredBox(
              color: p.glass,
              child: const Center(
                child: Icon(AppIcons.cat, size: 160, color: Brand.gold),
              ),
            )
          : PageView.builder(
              controller: _pages,
              itemCount: CatScreen.photos.length,
              itemBuilder: (context, i) => Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    CatScreen.photos[i],
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    color: Colors.black45,
                    colorBlendMode: BlendMode.darken,
                  ),
                  Image.asset(
                    CatScreen.photos[i],
                    fit: BoxFit.contain,
                    semanticLabel: CatScreen.name,
                  ),
                ],
              ),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BezelCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.cat, size: 40, color: Brand.gold),
          const SizedBox(height: 8),
          Text(CatScreen.name, style: AppText.display(54, color: p.text)),
          Text(
            Bi(
              'Chat noir · né en ${CatScreen.born}',
              'Black cat · born in ${CatScreen.born}',
            ).of(context),
            style: AppText.body(16, weight: FontWeight.w600, color: Brand.gold),
          ),
          const SizedBox(height: 16),
          Text(
            CatScreen.story.of(context),
            style: AppText.body(18, color: p.text).copyWith(height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
  }
}

/// Bouton « Mon chat », placé à côté du choix de langue.
class CatButton extends StatelessWidget {
  const CatButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = CatScreen.label.of(context);
    if (MediaQuery.sizeOf(context).width < 760) {
      return LiquidIconButton(icon: AppIcons.cat, label: label, onTap: onTap);
    }
    return PillButton(
      label: label,
      filled: false,
      onTap: onTap,
      trailing: const Icon(AppIcons.cat),
    );
  }
}

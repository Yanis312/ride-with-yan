import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/bilingual.dart';
import '../data/store_catalog.dart';
import '../navigation/sections.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'product_art.dart';

/// Vitrine de l'écran de veille, façon page d'accueil d'un site e-commerce :
/// l'article "en vol" sur son grand nom en filigrane, prix, tailles, badge
/// d'authenticité, et une colonne de miniatures qui défile toute seule.
/// Un toucher ouvre la boutique.
class StoreShowcase extends StatefulWidget {
  const StoreShowcase({super.key, required this.t, required this.size});

  /// Boucle 0 → 1 de l'écran de veille (lévitation de l'article).
  final double t;
  final double size;

  /// Temps passé sur chaque article.
  static const perProduct = Duration(milliseconds: 3200);

  @override
  State<StoreShowcase> createState() => _StoreShowcaseState();
}

class _StoreShowcaseState extends State<StoreShowcase> {
  final _products = featuredProducts;
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_products.length > 1) {
      _timer = Timer.periodic(StoreShowcase.perProduct, (_) {
        if (mounted) setState(() => _index = (_index + 1) % _products.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty) return const SizedBox.shrink();
    final product = _products[_index];
    final s = widget.size;
    final bob = math.sin(widget.t * 4 * math.pi);
    // Sur téléphone, la vitrine garde l'essentiel : article, prix, tailles.
    final small = s < 360;

    return GestureDetector(
      onTap: () => openSection(context, Section.store),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 900),
        curve: AppMotion.spring,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: RadialGradient(
            center: const Alignment(-0.2, -0.35),
            radius: 1.2,
            colors: product.colors,
          ),
          boxShadow: [
            BoxShadow(
              color: product.colors.first.withValues(alpha: 0.35),
              blurRadius: 60,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Grand mot en filigrane derrière l'article.
            Positioned(
              left: 0,
              right: 0,
              top: s * 0.12,
              height: s * 0.42,
              child: _swap(
                product,
                FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _bigWord(product),
                      maxLines: 1,
                      style: AppText.display(
                        200,
                        color: _onStage(product).withValues(alpha: 0.13),
                      ).copyWith(fontWeight: FontWeight.w600, height: 1),
                    ),
                  ),
                ),
              ),
            ),
            // Ombre au sol : se resserre quand l'article monte.
            Positioned(
              left: s * (0.2 + 0.03 * bob),
              right: s * (0.34 + 0.03 * bob),
              top: s * 0.58,
              height: s * 0.05,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(s, s * 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45 - 0.1 * bob),
                      blurRadius: s * 0.04,
                    ),
                  ],
                ),
              ),
            ),
            // L'article, qui entre par la droite et flotte.
            Positioned(
              left: s * 0.07,
              right: s * (small ? 0.07 : 0.2),
              top: s * 0.12,
              height: s * 0.46,
              child: Transform.translate(
                offset: Offset(0, -s * 0.02 * (bob + 1)),
                child: _swap(
                  product,
                  Transform.rotate(
                    angle: product.art?.kind == ArtKind.sneaker
                        ? productTilt
                        : 0,
                    child: ProductVisual(product: product, shadow: false),
                  ),
                  slide: true,
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              right: 16,
              child: Row(
                children: [
                  if (!small)
                    _Pill(
                      label: const Bi('Nouveautés', 'New in').of(context),
                      icon: AppIcons.sparkle,
                      gold: true,
                    ),
                  const Spacer(),
                  _Pill(
                    label: const Bi(
                      'Neuf · Authentique',
                      'New · Authentic',
                    ).of(context),
                    icon: AppIcons.sealCheck,
                  ),
                ],
              ),
            ),
            // Miniatures à droite, l'article affiché est cerclé d'or.
            if (!small)
              Positioned(
                right: 12,
                top: s * 0.15,
                child: Column(
                  children: [
                    for (final (i, p) in _products.indexed)
                      AnimatedContainer(
                        duration: AppMotion.medium,
                        curve: AppMotion.spring,
                        width: s * 0.1,
                        height: s * 0.1,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(colors: p.colors),
                          border: Border.all(
                            color: i == _index ? Brand.gold : Colors.white24,
                            width: i == _index ? 2 : 1,
                          ),
                        ),
                        child: ProductVisual(product: p, shadow: false),
                      ),
                  ],
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: _swap(product, _InfoCard(product: product, size: s)),
            ),
          ],
        ),
      ),
    );
  }

  /// Remplace un élément quand l'article change ; l'article lui-même glisse.
  Widget _swap(Product product, Widget child, {bool slide = false}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 750),
      reverseDuration: const Duration(milliseconds: 350),
      switchInCurve: AppMotion.emphasized,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, a) {
        Widget out = FadeTransition(opacity: a, child: child);
        if (slide) {
          out = SlideTransition(
            position: Tween(
              begin: const Offset(0.35, 0),
              end: Offset.zero,
            ).animate(a),
            child: ScaleTransition(
              scale: Tween(begin: 0.8, end: 1.0).animate(a),
              child: out,
            ),
          );
        }
        return out;
      },
      child: KeyedSubtree(key: ValueKey(product.id), child: child),
    );
  }

  static String _bigWord(Product p) => switch (p.art?.kind) {
    ArtKind.sneaker => 'AF1',
    ArtKind.jersey => 'KIT',
    null => p.category.label.en.toUpperCase(),
  };
}

/// Couleur lisible posée sur le fond de la vitrine.
Color _onStage(Product p) =>
    p.colors.first.computeLuminance() > 0.45 ? Brand.ink : Colors.white;

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, this.gold = false});

  final String label;
  final IconData icon;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final fg = gold ? Brand.ink : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: gold ? Brand.gold : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(label, style: AppText.eyebrow(fg).copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

/// Carte d'infos en bas : marque, nom, prix et tailles disponibles.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.product, required this.size});

  final Product product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    final price = NumberFormat.currency(
      locale: en ? 'en_CA' : 'fr_CA',
      symbol: r'$',
      decimalDigits: 0,
    ).format(product.price);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (product.brand ?? product.category.label.of(context))
                          .toUpperCase(),
                      style: AppText.eyebrow(Brand.goldSoft),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.name.of(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display(
                        (size * 0.065).clamp(18.0, 32.0),
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      product.blurb.of(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE08A), Brand.gold],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Brand.gold.withValues(alpha: 0.5),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Text(
                  price,
                  style: AppText.body(
                    (size * 0.045).clamp(15.0, 22.0),
                    weight: FontWeight.w800,
                    color: Brand.ink,
                  ),
                ),
              ),
            ],
          ),
          if (product.hasSizes) ...[
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  for (final e in product.sizes.entries.take(6))
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: e.value > 0
                                ? Colors.white54
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          e.key,
                          style:
                              AppText.body(
                                11,
                                weight: FontWeight.w600,
                                color: e.value > 0
                                    ? Colors.white
                                    : Colors.white30,
                              ).copyWith(
                                decoration: e.value > 0
                                    ? null
                                    : TextDecoration.lineThrough,
                                decorationColor: Colors.white30,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

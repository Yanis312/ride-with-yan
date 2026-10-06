import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../backend/remote_config.dart';
import '../data/bilingual.dart';
import '../data/store_catalog.dart';
import '../navigation/sections.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'product_art.dart';

/// Vitrine de l'écran de veille, façon page d'accueil d'un site e-commerce :
/// quatre articles à la fois, avec leur nom et leur prix, puis les quatre
/// suivants. Tout le catalogue passe pendant la diapo. Un toucher ouvre la
/// boutique.
class StoreShowcase extends StatefulWidget {
  const StoreShowcase({super.key, required this.t, required this.size});

  /// Boucle 0 → 1 de l'écran de veille (gardée pour la même signature que
  /// les autres illustrations).
  final double t;
  final double size;

  /// Durée totale de la diapo : chaque page en reçoit une part égale.
  static const total = Duration(milliseconds: 15000);
  static const perPage = 4;

  @override
  State<StoreShowcase> createState() => _StoreShowcaseState();
}

class _StoreShowcaseState extends State<StoreShowcase> {
  List<Product> _products = featuredProducts;
  int _page = 0;
  Timer? _timer;

  int get _pages => (_products.length / StoreShowcase.perPage).ceil();

  @override
  void initState() {
    super.initState();
    RemoteConfig.instance.addListener(_onConfig);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (_pages > 1) {
      _timer = Timer.periodic(StoreShowcase.total ~/ _pages, (_) {
        if (mounted) setState(() => _page = (_page + 1) % _pages);
      });
    }
  }

  /// Catalogue modifié depuis l'administration pendant la diapo.
  void _onConfig() {
    if (!mounted) return;
    setState(() {
      _products = featuredProducts;
      _page = _pages == 0 ? 0 : _page % _pages;
    });
    _schedule();
  }

  @override
  void dispose() {
    RemoteConfig.instance.removeListener(_onConfig);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty) return const SizedBox.shrink();
    final s = widget.size;
    final small = s < 360;
    final shown = _products
        .skip(_page * StoreShowcase.perPage)
        .take(StoreShowcase.perPage)
        .toList();
    final gap = small ? 8.0 : 12.0;

    return GestureDetector(
      onTap: () => openSection(context, Section.store),
      child: Container(
        padding: EdgeInsets.all(small ? 10 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF23201A), Color(0xFF0A0A0C)],
          ),
          border: Border.all(color: Brand.gold.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(color: Brand.gold.withValues(alpha: 0.3), blurRadius: 60),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Pill(
                  label: const Bi('Nouveautés', 'New in').of(context),
                  icon: AppIcons.sparkle,
                ),
                const Spacer(),
                // Points de pagination : où on en est dans le catalogue.
                for (var i = 0; i < _pages; i++)
                  AnimatedContainer(
                    duration: AppMotion.medium,
                    curve: AppMotion.spring,
                    width: i == _page ? 20 : 7,
                    height: 7,
                    margin: const EdgeInsets.only(left: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: i == _page ? Brand.gold : Colors.white30,
                    ),
                  ),
              ],
            ),
            SizedBox(height: gap),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = (c.maxWidth - gap) / 2;
                  final h = (c.maxHeight - gap) / 2;
                  return Stack(
                    children: [
                      for (final (i, product) in shown.indexed)
                        Positioned(
                          left: (i % 2) * (w + gap),
                          top: (i ~/ 2) * (h + gap),
                          width: w,
                          height: h,
                          // La clé change à chaque page : chaque carte
                          // rejoue son entrée, l'une après l'autre.
                          child:
                              _Tile(
                                    key: ValueKey('$_page-${product.id}'),
                                    product: product,
                                    small: small,
                                  )
                                  .animate()
                                  .fadeIn(
                                    delay: (90 * i).ms,
                                    duration: 450.ms,
                                    curve: AppMotion.spring,
                                  )
                                  .slideX(
                                    begin: 0.25,
                                    delay: (90 * i).ms,
                                    duration: 600.ms,
                                    curve: AppMotion.emphasized,
                                  ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Brand.gold,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Brand.ink),
          const SizedBox(width: 6),
          Text(label, style: AppText.eyebrow(Brand.ink).copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

/// Une carte article : la photo, le nom et le prix en pastille dorée.
class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.product, required this.small});

  final Product product;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    final price = NumberFormat.currency(
      locale: en ? 'en_CA' : 'fr_CA',
      symbol: r'$',
      decimalDigits: 0,
    ).format(product.price);

    return ClipRRect(
      borderRadius: BorderRadius.circular(small ? 16 : 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.2, -0.4),
            radius: 1.2,
            colors: product.colors,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProductFigure(
              product: product,
              padding: EdgeInsets.fromLTRB(10, 10, 10, small ? 30 : 44),
              shadow: false,
            ),
            // Dégradé sombre en bas : le nom reste lisible sur la photo.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xD9000000)],
                  stops: [0.55, 1],
                ),
              ),
            ),
            Positioned(
              left: small ? 8 : 12,
              right: small ? 6 : 10,
              bottom: small ? 6 : 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      product.name.of(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        small ? 11 : 14,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ).copyWith(height: 1.15),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: small ? 8 : 11,
                      vertical: small ? 3 : 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE08A), Brand.gold],
                      ),
                    ),
                    child: Text(
                      price,
                      style: AppText.body(
                        small ? 11 : 14,
                        weight: FontWeight.w800,
                        color: Brand.ink,
                      ),
                    ),
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

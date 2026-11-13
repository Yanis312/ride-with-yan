import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../backend/remote_config.dart';
import '../config.dart';
import '../data/bilingual.dart';
import '../data/orders.dart';
import '../data/store_catalog.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/product_art.dart';

/// Adresse publique de la boutique sur téléphone (le QR code de la tablette).
const onlineStoreUrl =
    'https://ride-with-yan.yanisgaroui1.workers.dev/?boutique';

/// Message WhatsApp pour un article commandé depuis le téléphone, avec le
/// lien de sa photo (WhatsApp en montre l'aperçu).
String productOrderMessage(
  Product product, {
  String? size,
  required bool english,
  String origin = 'https://ride-with-yan.yanisgaroui1.workers.dev',
}) {
  final photo = product.photos.isEmpty
      ? null
      : product.photos.first.startsWith('http')
      ? product.photos.first
      // Sur le web, Flutter sert les fichiers de l'app sous /assets/.
      : '$origin/assets/${product.photos.first}';
  final name = english ? product.name.en : product.name.fr;
  final category = english
      ? product.category.label.en
      : product.category.label.fr;
  final price = orderAmount(product.price, english: english);
  return [
    english
        ? 'Hi Yanis, I would like to order:'
        : 'Bonjour Yanis, je voudrais commander :',
    '- $name ($category)'
        '${size == null ? '' : (english ? ', size $size' : ', taille $size')}'
        ' : $price',
    if (photo != null) '${english ? 'Photo' : 'Photo'} : $photo',
    '',
    english ? 'My delivery address:' : 'Mon adresse de livraison :',
  ].join('\n');
}

/// Boutique seule, pensée pour le téléphone du client : on l'ouvre en
/// scannant le QR code de la tablette (adresse terminée par ?boutique).
class OnlineStoreApp extends StatelessWidget {
  const OnlineStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ride with Yan · Boutique',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.dark),
      home: const OnlineStoreScreen(),
    );
  }
}

class OnlineStoreScreen extends StatefulWidget {
  const OnlineStoreScreen({super.key});

  @override
  State<OnlineStoreScreen> createState() => _OnlineStoreScreenState();
}

class _OnlineStoreScreenState extends State<OnlineStoreScreen> {
  late bool _english =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode != 'fr';
  Shopper _shopper = Shopper.women;
  ProductCategory? _category;

  String t(Bi text) => _english ? text.en : text.fr;

  void _open(Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductSheet(product: product, english: _english),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: Brand.ink,
      body: ListenableBuilder(
        listenable: RemoteConfig.instance,
        builder: (context, _) {
          final shelf = catalogFor(_shopper);
          final categories = [
            for (final c in ProductCategory.values)
              if (shelf.any((x) => x.category == c)) c,
          ];
          final products = [
            for (final x in shelf)
              if (_category == null || x.category == _category) x,
          ];
          return Stack(
            children: [
              const _Glow(),
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'RIDE WITH YAN',
                                  style: AppText.eyebrow(Brand.gold),
                                ),
                                const Spacer(),
                                _LanguageToggle(
                                  english: _english,
                                  onChanged: (v) =>
                                      setState(() => _english = v),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Text(
                                  t(const Bi('La boutique', 'The shop')),
                                  style: AppText.display(56, color: p.text),
                                )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .slideY(
                                  begin: 0.15,
                                  curve: AppMotion.emphasized,
                                ),
                            const SizedBox(height: 10),
                            Text(
                              t(storePitch),
                              style: AppText.body(15, color: p.textMuted),
                            ),
                            const SizedBox(height: 22),
                            _Segmented(
                              english: _english,
                              value: _shopper,
                              onChanged: (s) => setState(() {
                                _shopper = s;
                                _category = null;
                              }),
                            ),
                            const SizedBox(height: 14),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _Chip(
                                    label: t(const Bi('Tout', 'All')),
                                    selected: _category == null,
                                    onTap: () =>
                                        setState(() => _category = null),
                                  ),
                                  for (final c in categories)
                                    _Chip(
                                      label: t(c.label),
                                      selected: _category == c,
                                      onTap: () =>
                                          setState(() => _category = c),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    sliver: SliverLayoutBuilder(
                      builder: (context, c) {
                        final width = c.crossAxisExtent.clamp(0, 1100);
                        final columns = width > 820
                            ? 4
                            : width > 560
                            ? 3
                            : 2;
                        return SliverGrid.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.68,
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, i) => _ProductCard(
                            product: products[i],
                            english: _english,
                            onTap: () => _open(products[i]),
                          ).animate().fadeIn(delay: (40 * (i % 8)).ms),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _Center(child: _Conditions(english: _english)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Garde le contenu lisible sur un grand écran.
class _Center extends StatelessWidget {
  const _Center({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: child,
    ),
  );
}

/// Halo doré en haut de page.
class _Glow extends StatelessWidget {
  const _Glow();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      height: 420,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.6, -1.1),
          radius: 1.1,
          colors: [Brand.gold.withValues(alpha: 0.22), Colors.transparent],
        ),
      ),
    ),
  );
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.english, required this.onChanged});

  final bool english;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(String label, bool value) => GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: english == value ? Brand.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: AppText.body(
            12,
            weight: FontWeight.w700,
            color: english == value ? Brand.ink : Colors.white70,
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [option('EN', true), option('FR', false)],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.english,
    required this.value,
    required this.onChanged,
  });

  final bool english;
  final Shopper value;
  final ValueChanged<Shopper> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          for (final s in [Shopper.women, Shopper.men])
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(s),
                child: AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.spring,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: value == s
                        ? const LinearGradient(
                            colors: [Brand.goldSoft, Brand.gold],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    english ? s.label.en : s.label.fr,
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      15,
                      weight: FontWeight.w700,
                      color: value == s ? Brand.ink : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          color: selected ? Colors.white : Colors.transparent,
          border: Border.all(color: selected ? Colors.white : Colors.white24),
        ),
        child: Text(
          label,
          style: AppText.body(
            13,
            weight: FontWeight.w600,
            color: selected ? Brand.ink : Colors.white,
          ),
        ),
      ),
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.english,
    required this.onTap,
  });

  final Product product;
  final bool english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: english ? product.name.en : product.name.fr,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: product.colors,
                    ),
                  ),
                  child: ProductFigure(
                    product: product,
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      english ? product.name.en : product.name.fr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        13.5,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ).copyWith(height: 1.25),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      orderAmount(product.price, english: english),
                      style: AppText.body(
                        15,
                        weight: FontWeight.w700,
                        color: Brand.gold,
                      ),
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

class _ProductSheet extends StatefulWidget {
  const _ProductSheet({required this.product, required this.english});

  final Product product;
  final bool english;

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  String? _size;
  int _page = 0;

  String t(Bi text) => widget.english ? text.en : text.fr;

  Future<void> _order() async {
    final message = productOrderMessage(
      widget.product,
      size: _size,
      english: widget.english,
      origin: Uri.base.origin.startsWith('http')
          ? Uri.base.origin
          : 'https://ride-with-yan.yanisgaroui1.workers.dev',
    );
    final uri = Uri.parse(
      'https://wa.me/${AppConfig.whatsAppNumber}'
      '?text=${Uri.encodeComponent(message)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final photos = product.photos;
    final needsSize = product.hasSizes && _size == null;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111217),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Stack(
          children: [
            ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(colors: product.colors),
                    ),
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: photos.isEmpty ? 1 : photos.length,
                          onPageChanged: (i) => setState(() => _page = i),
                          itemBuilder: (context, i) => ProductFigure(
                            product: product,
                            photo: i,
                            whole: true,
                            padding: const EdgeInsets.all(24),
                          ),
                        ),
                        if (photos.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < photos.length; i++)
                                  AnimatedContainer(
                                    duration: AppMotion.fast,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    width: i == _page ? 18 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: i == _page
                                          ? Brand.gold
                                          : Colors.white54,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t(product.category.label).toUpperCase(),
                        style: AppText.eyebrow(Brand.gold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t(product.name),
                        style: AppText.display(34, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t(product.blurb),
                        style: AppText.body(14, color: Colors.white60),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        orderAmount(product.price, english: widget.english),
                        style: AppText.body(
                          26,
                          weight: FontWeight.w700,
                          color: Brand.gold,
                        ),
                      ),
                      if (product.hasSizes) ...[
                        const SizedBox(height: 20),
                        Text(
                          t(const Bi('Votre taille', 'Your size')),
                          style: AppText.body(
                            14,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in product.sizes.keys)
                              _Chip(
                                label: s,
                                selected: _size == s,
                                onTap: () => setState(() => _size = s),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      _Conditions(english: widget.english, compact: true),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00111217), Color(0xFF111217)],
                    stops: [0, 0.45],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: _WhatsAppButton(
                    label: needsSize
                        ? t(const Bi('Choisissez une taille', 'Choose a size'))
                        : t(
                            const Bi(
                              'Commander sur WhatsApp',
                              'Order on WhatsApp',
                            ),
                          ),
                    onTap: needsSize ? null : _order,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsAppButton extends StatelessWidget {
  const _WhatsAppButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: enabled ? const Color(0xFF25D366) : const Color(0xFF2A2B32),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF25D366).withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AppIcons.whatsapp,
                color: enabled ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppText.body(
                  16,
                  weight: FontWeight.w700,
                  color: enabled ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Les conditions de commande, en liste.
class _Conditions extends StatelessWidget {
  const _Conditions({required this.english, this.compact = false});

  final bool english;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: compact ? null : const EdgeInsets.fromLTRB(16, 12, 16, 40),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            english ? 'HOW TO ORDER' : 'COMMENT COMMANDER',
            style: AppText.eyebrow(Brand.gold),
          ),
          const SizedBox(height: 12),
          for (final c in [
            const Bi(
              'Choisissez l’article et votre taille',
              'Pick the item and your size',
            ),
            const Bi(
              'Commandez sur WhatsApp en un toucher',
              'Order on WhatsApp in one tap',
            ),
            ...orderConditions,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      AppIcons.checkCircle,
                      size: 18,
                      color: Brand.gold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      english ? c.en : c.fr,
                      style: AppText.body(14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            english ? resellerNotice.en : resellerNotice.fr,
            style: AppText.body(11.5, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

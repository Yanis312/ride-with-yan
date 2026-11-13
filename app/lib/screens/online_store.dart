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
import '../widgets/glass.dart';
import '../widgets/mesh_background.dart';
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
    if (photo != null) 'Photo : $photo',
    '',
    english ? 'My delivery address:' : 'Mon adresse de livraison :',
  ].join('\n');
}

/// Boutique seule, pensée pour le téléphone du client : on l'ouvre en
/// scannant le QR code de la tablette (adresse terminée par ?boutique).
/// Claire par défaut, à toute heure ; le passager peut passer en mode nuit.
class OnlineStoreApp extends StatefulWidget {
  const OnlineStoreApp({super.key});

  @override
  State<OnlineStoreApp> createState() => _OnlineStoreAppState();
}

class _OnlineStoreAppState extends State<OnlineStoreApp> {
  bool _dark = false;
  late bool _english =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode != 'fr';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ride with Yan · Boutique',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: const Duration(milliseconds: 600),
      themeAnimationCurve: AppMotion.spring,
      home: OnlineStoreScreen(
        english: _english,
        dark: _dark,
        onEnglish: (v) => setState(() => _english = v),
        onDark: (v) => setState(() => _dark = v),
      ),
    );
  }
}

class OnlineStoreScreen extends StatefulWidget {
  const OnlineStoreScreen({
    super.key,
    this.english = true,
    this.dark = false,
    this.onEnglish,
    this.onDark,
  });

  final bool english;
  final bool dark;
  final ValueChanged<bool>? onEnglish;
  final ValueChanged<bool>? onDark;

  @override
  State<OnlineStoreScreen> createState() => _OnlineStoreScreenState();
}

class _OnlineStoreScreenState extends State<OnlineStoreScreen> {
  Shopper _shopper = Shopper.women;
  ProductCategory? _category;

  bool get _english => widget.english;
  String t(Bi text) => _english ? text.en : text.fr;

  void _open(Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => _ProductSheet(product: product, english: _english),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: MeshBackground(
        scene: Scene.store,
        child: ListenableBuilder(
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
            return SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'RIDE WITH YAN',
                                    style: AppText.eyebrow(p.accentText),
                                  ),
                                ),
                                _LanguageToggle(
                                  english: _english,
                                  onChanged: (v) => widget.onEnglish?.call(v),
                                ),
                                const SizedBox(width: 8),
                                LiquidIconButton(
                                  size: 42,
                                  icon: widget.dark
                                      ? AppIcons.sun
                                      : AppIcons.moon,
                                  label: t(
                                    widget.dark
                                        ? const Bi('Mode jour', 'Day mode')
                                        : const Bi('Mode nuit', 'Night mode'),
                                  ),
                                  onTap: () =>
                                      widget.onDark?.call(!widget.dark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Text(
                                  t(const Bi('La boutique', 'The shop')),
                                  style: AppText.display(52, color: p.text),
                                )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .slideY(
                                  begin: 0.2,
                                  curve: AppMotion.emphasized,
                                  duration: 700.ms,
                                ),
                            const SizedBox(height: 8),
                            Text(
                              t(storePitch),
                              style: AppText.body(14.5, color: p.textMuted),
                            ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
                            const SizedBox(height: 20),
                            _Segmented(
                              english: _english,
                              value: _shopper,
                              onChanged: (s) => setState(() {
                                _shopper = s;
                                _category = null;
                              }),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              child: Row(
                                children: [
                                  _Chip(
                                    label: t(const Bi('Tout', 'All')),
                                    icon: AppIcons.storefront,
                                    selected: _category == null,
                                    onTap: () =>
                                        setState(() => _category = null),
                                  ),
                                  for (final c in categories)
                                    _Chip(
                                      label: t(c.label),
                                      icon: c.icon,
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
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    sliver: SliverLayoutBuilder(
                      builder: (context, c) {
                        final width = c.crossAxisExtent;
                        final columns = width > 900
                            ? 5
                            : width > 680
                            ? 4
                            : width > 480
                            ? 3
                            : 2;
                        return SliverGrid.builder(
                          key: ValueKey((_shopper, _category)),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 250,
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, i) =>
                              _ProductCard(
                                    product: products[i],
                                    english: _english,
                                    onTap: () => _open(products[i]),
                                  )
                                  .animate()
                                  .fadeIn(
                                    delay: (45 * (i % 8)).ms,
                                    duration: 420.ms,
                                  )
                                  .slideY(
                                    begin: 0.08,
                                    delay: (45 * (i % 8)).ms,
                                    duration: 480.ms,
                                    curve: AppMotion.spring,
                                  ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
                        child: _Conditions(english: _english),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.english, required this.onChanged});

  final bool english;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget option(String label, bool value) => Pressable(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.spring,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: english == value
              ? const LinearGradient(colors: [Brand.goldSoft, Brand.gold])
              : null,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: AppText.body(
            12,
            weight: FontWeight.w700,
            color: english == value ? Brand.ink : p.textMuted,
          ),
        ),
      ),
    );
    return LiquidPill(
      padding: const EdgeInsets.all(3),
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
    final p = context.palette;
    return LiquidPill(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final s in [Shopper.women, Shopper.men])
            Expanded(
              child: Pressable(
                onTap: () => onChanged(s),
                child: AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.spring,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    gradient: value == s
                        ? const LinearGradient(
                            colors: [Brand.goldSoft, Brand.gold],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        s.icon,
                        size: 17,
                        color: value == s ? Brand.ink : p.text,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        english ? s.label.en : s.label.fr,
                        style: AppText.body(
                          15,
                          weight: FontWeight.w600,
                          color: value == s ? Brand.ink : p.text,
                        ),
                      ),
                    ],
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
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? Brand.ink : p.text;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppText.body(13, weight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          child: selected
              ? DecoratedBox(
                  key: const ValueKey(true),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Brand.goldSoft, Brand.gold],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: content,
                )
              : LiquidPill(key: const ValueKey(false), child: content),
        ),
      ),
    );
  }
}

/// Carte d'un article, du même style que la boutique de la tablette.
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
    final p = context.palette;
    final name = english ? product.name.en : product.name.fr;
    return Semantics(
      button: true,
      label: name,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: BezelCard(
          radius: 24,
          padding: const EdgeInsets.all(7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Stage(
                  product: product,
                  radius: 17,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: ProductFigure(
                      product: product,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 4, 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (english
                              ? product.category.label.en
                              : product.category.label.fr)
                          .toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.eyebrow(p.accentText)
                          .copyWith(fontSize: 9.5, letterSpacing: 1.8),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display(19, color: p.text),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          orderAmount(product.price, english: english),
                          style: AppText.body(
                            15,
                            weight: FontWeight.w700,
                            color: p.text,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Brand.goldSoft, Brand.gold],
                            ),
                          ),
                          child: const Icon(
                            AppIcons.arrowRight,
                            size: 15,
                            color: Brand.ink,
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
      ),
    );
  }
}

/// Fond de vitrine d'un article : dégradé radial, comme sur la tablette.
class _Stage extends StatelessWidget {
  const _Stage({required this.product, required this.radius, this.child});

  final Product product;
  final double radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: RadialGradient(
        center: const Alignment(-0.2, -0.45),
        radius: 1.15,
        colors: product.colors,
      ),
    ),
    child: child,
  );
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
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sheet = dark ? const Color(0xFF111217) : const Color(0xFFF7F8FA);
    final product = widget.product;
    final photos = product.photos;
    final needsSize = product.hasSizes && _size == null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: sheet,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Stack(
          children: [
            ListView(
              controller: scroll,
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.hairline,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: AspectRatio(
                          aspectRatio: 1.35,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _Stage(
                              product: product,
                              radius: 24,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  children: [
                                    PageView.builder(
                                      itemCount: photos.isEmpty
                                          ? 1
                                          : photos.length,
                                      onPageChanged: (i) =>
                                          setState(() => _page = i),
                                      itemBuilder: (context, i) =>
                                          ProductFigure(
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            for (
                                              var i = 0;
                                              i < photos.length;
                                              i++
                                            )
                                              AnimatedContainer(
                                                duration: AppMotion.fast,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 3,
                                                    ),
                                                width: i == _page ? 18 : 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: i == _page
                                                      ? Brand.gold
                                                      : Colors.white70,
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scaleXY(
                      begin: 0.96,
                      curve: AppMotion.spring,
                      duration: 500.ms,
                    ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t(product.category.label).toUpperCase(),
                        style: AppText.eyebrow(p.accentText),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t(product.name),
                        style: AppText.display(32, color: p.text),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t(product.blurb),
                        style: AppText.body(14, color: p.textMuted),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        orderAmount(product.price, english: widget.english),
                        style: AppText.body(
                          24,
                          weight: FontWeight.w700,
                          color: p.text,
                        ),
                      ),
                      if (product.hasSizes) ...[
                        const SizedBox(height: 18),
                        Text(
                          t(const Bi('Votre taille', 'Your size')),
                          style: AppText.body(
                            14,
                            weight: FontWeight.w600,
                            color: p.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 0,
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
                      const SizedBox(height: 22),
                      _Conditions(english: widget.english),
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [sheet.withValues(alpha: 0), sheet],
                    stops: const [0, 0.45],
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
    final p = context.palette;
    final enabled = onTap != null;
    final fg = enabled ? Colors.white : p.textMuted;
    final button = AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.spring,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: enabled
            ? const LinearGradient(
                colors: [Color(0xFF2BD96B), Color(0xFF16A34A)],
              )
            : null,
        border: enabled ? null : Border.all(color: p.hairline),
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
          Icon(AppIcons.whatsapp, color: fg),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppText.body(16, weight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: enabled
            ? button
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 2200.ms,
                    delay: 1400.ms,
                    color: Colors.white38,
                  )
            : LiquidPill(child: button),
      ),
    );
  }
}

/// Les conditions de commande, en liste.
class _Conditions extends StatelessWidget {
  const _Conditions({required this.english});

  final bool english;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BezelCard(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            english ? 'HOW TO ORDER' : 'COMMENT COMMANDER',
            style: AppText.eyebrow(p.accentText),
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
                      style: AppText.body(14, color: p.text),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            english ? resellerNotice.en : resellerNotice.fr,
            style: AppText.body(11.5, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

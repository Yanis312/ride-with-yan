import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'online_store.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../backend/remote_config.dart';
import '../config.dart';
import '../data/bilingual.dart';
import '../data/orders.dart';
import '../data/store_catalog.dart';
import '../l10n/app_localizations.dart';
import '../navigation/sections.dart';
import '../session/session_controller.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/privacy_sheet.dart';
import '../widgets/mesh_background.dart';
import '../widgets/product_art.dart';
import '../widgets/qr_card.dart';
import '../widgets/section_scaffold.dart';
import '../backend/usage.dart';

String _money(BuildContext context, double amount) => NumberFormat.currency(
  locale: Localizations.localeOf(context).languageCode == 'en'
      ? 'en_CA'
      : 'fr_CA',
  symbol: r'$',
  decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
).format(amount);

/// Boutique à bord, en deux rayons (hommes, femmes) : Air Force 1, Dunk,
/// Vans et The North Face neufs, livrés chez le client. Le panier finit sur
/// WhatsApp : le passager envoie sa commande et son adresse, puis paie un
/// acompte de 50 % par Interac et le reste à la livraison.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, this.shopper = Shopper.men});

  /// Rayon ouvert au départ (celui de la vitrine touchée sur l'écran de veille).
  final Shopper shopper;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late Shopper _shopper = widget.shopper;

  /// Catégorie affichée ; null = tout.
  ProductCategory? _category;

  @override
  void initState() {
    super.initState();
    RemoteConfig.instance.addListener(_onConfig);
  }

  void _onConfig() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    RemoteConfig.instance.removeListener(_onConfig);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cart = SessionScope.of(context).cart;
    final compact = MediaQuery.sizeOf(context).width < 900;
    final shelf = catalogFor(_shopper);
    final products = [
      for (final p in shelf)
        if (_category == null || p.category == _category) p,
    ];

    final tabs = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShopperSwitch(
          selected: _shopper,
          onSelected: (s) => setState(() {
            _shopper = s;
            // Une catégorie absente de l'autre rayon ne doit pas le vider.
            if (!catalogFor(s).any((p) => p.category == _category)) {
              _category = null;
            }
          }),
        ),
        const SizedBox(height: 14),
        _CategoryTabs(
          categories: [
            for (final c in ProductCategory.values)
              if (shelf.any((p) => p.category == c)) c,
          ],
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
      ],
    );
    final grid = _ProductGrid(
      key: ValueKey((_shopper, _category)),
      products: products,
      cart: cart,
      // Trois colonnes seulement quand il y a vraiment la place.
      columns: MediaQuery.sizeOf(context).width < 1150 ? 2 : 3,
    );
    final panel = _CartPanel(cart: cart);

    return SectionScaffold(
      scene: Scene.store,
      section: Section.store,
      title: l10n.storeTitle,
      trailing: _CartBadge(cart: cart),
      child: compact
          ? ListView(
              children: [
                _Subtitle(),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: _PhoneStoreButton(),
                ),
                const SizedBox(height: 14),
                tabs,
                const SizedBox(height: 16),
                grid,
                const SizedBox(height: 14),
                const _Notice(),
                const SizedBox(height: 20),
                SizedBox(height: 560, child: panel),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Subtitle(),
                      const SizedBox(height: 14),
                      tabs,
                      const SizedBox(height: 18),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              grid,
                              const SizedBox(height: 16),
                              const _Notice(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _PhoneStoreButton(),
                      const SizedBox(height: 14),
                      Expanded(child: panel),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    storePitch.of(context),
    style: AppText.body(17, color: context.palette.textMuted),
  );
}

/// Mention "revendeur indépendant, non affilié", discrète mais toujours visible.
class _Notice extends StatelessWidget {
  const _Notice();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(AppIcons.sealCheck, size: 16, color: p.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resellerNotice.of(context),
                style: AppText.body(12, color: p.textMuted),
              ),
              const PrivacyLink(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Les deux rayons, en grand, tout en haut : le passager sait toujours dans
/// quelle boutique il se trouve.
class _ShopperSwitch extends StatelessWidget {
  const _ShopperSwitch({required this.selected, required this.onSelected});

  final Shopper selected;
  final ValueChanged<Shopper> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: p.glass,
        border: Border.all(color: p.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in Shopper.values)
            Semantics(
              button: true,
              selected: s == selected,
              child: Pressable(
                onTap: () => onSelected(s),
                child: AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.spring,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: s == selected ? Brand.gold : Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        s.icon,
                        size: 20,
                        color: s == selected ? Brand.ink : p.text,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s.label.of(context),
                        style: AppText.body(
                          19,
                          weight: FontWeight.w700,
                          color: s == selected ? Brand.ink : p.text,
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

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<ProductCategory> categories;
  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Tab(
          label: const Bi('Tout', 'All').of(context),
          icon: AppIcons.storefront,
          selected: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final c in categories)
          _Tab(
            label: c.label.of(context),
            icon: c.icon,
            selected: selected == c,
            onTap: () => onSelected(c),
          ),
        const _WhatsAppButton(),
      ],
    );
  }
}

/// "Me contacter sur WhatsApp" : ouvre le code QR de Yanis.
class _WhatsAppButton extends StatelessWidget {
  const _WhatsAppButton();

  static const _green = Color(0xFF128C4A);

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return Semantics(
      button: true,
      child: Pressable(
        onTap: () {
          // Le passager sort son téléphone : la session patiente.
          Usage.instance.tap('store.whatsapp');
          session.setPaying(true);
          showStoreContactSheet(context)
              .whenComplete(() => session.setPaying(false));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: _green,
            boxShadow: [
              BoxShadow(color: _green.withValues(alpha: 0.45), blurRadius: 18),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.whatsapp, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                const Bi(
                  'Me contacter sur WhatsApp',
                  'Contact me on WhatsApp',
                ).of(context),
                style: AppText.body(
                  15,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? Brand.ink : p.text;
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.spring,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? Brand.gold : p.glass,
            border: Border.all(color: selected ? Brand.gold : p.hairline),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: Brand.gold.withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppText.body(15, weight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton qui brille : « Scannez pour voir ma boutique sur votre
/// téléphone ». Ouvre un grand QR code vers la boutique en ligne.
class _PhoneStoreButton extends StatelessWidget {
  const _PhoneStoreButton();

  static const _label = Bi(
    'Scannez pour voir ma boutique sur votre téléphone',
    'Scan to see my shop on your phone',
  );

  void _open(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).closeButtonLabel,
      barrierColor: Colors.black87,
      transitionDuration: AppMotion.medium,
      pageBuilder: (context, _, _) => Theme(
        data: buildAppTheme(Brightness.dark),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    const Bi(
                      'Ma boutique sur votre téléphone',
                      'My shop on your phone',
                    ).of(context),
                    textAlign: TextAlign.center,
                    style: AppText.display(44, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    const Bi(
                      'Scannez avec l’appareil photo, prenez le temps de '
                          'choisir, commandez sur WhatsApp.',
                      'Scan with your camera, take your time, order on '
                          'WhatsApp.',
                    ).of(context),
                    textAlign: TextAlign.center,
                    style: AppText.body(17, color: Colors.white70),
                  ),
                  const SizedBox(height: 28),
                  QrCard(
                    data: onlineStoreUrl,
                    icon: AppIcons.storefront,
                    label: const Bi(
                      'Touchez pour fermer',
                      'Tap to close',
                    ).of(context),
                    size: 260,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: AppMotion.spring),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = _label.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: () => _open(context),
        child:
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3A2A06), Color(0xFF1A1205)],
                    ),
                    border: Border.all(color: Brand.gold, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: Brand.gold.withValues(alpha: 0.45),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(AppIcons.qrCode, size: 20, color: Brand.gold),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: AppText.body(
                            15,
                            weight: FontWeight.w600,
                            color: const Color(0xFFFFE08A),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                  duration: 2400.ms,
                  delay: 1200.ms,
                  color: const Color(0xFFFFF4C2),
                ),
      ),
    );
  }
}

class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => cart.isEmpty
          ? const SizedBox.shrink()
          : AnimatedScale(
              scale: cart.isEmpty ? 0 : 1,
              duration: AppMotion.medium,
              curve: AppMotion.spring,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [Brand.goldSoft, Brand.gold],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      AppIcons.shoppingBag,
                      size: 20,
                      color: Brand.ink,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${cart.count}',
                      style: AppText.body(
                        16,
                        weight: FontWeight.w600,
                        color: Brand.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    super.key,
    required this.products,
    required this.cart,
    required this.columns,
  });

  final List<Product> products;
  final Cart cart;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 18.0;
        final width = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (i, product) in products.indexed)
              SizedBox(
                    width: width,
                    child: _ProductCard(product: product, cart: cart),
                  )
                  // Glissement seul, et seulement pour les cartes visibles à
                  // l'ouverture : pas de couche de transparence par carte.
                  .animate()
                  .slideY(
                    begin: i < 6 ? 0.06 : 0,
                    delay: (40 * (i < 6 ? i : 0)).ms,
                    duration: 380.ms,
                    curve: AppMotion.spring,
                  ),
          ],
        );
      },
    );
  }
}

/// Fond de vitrine d'un article : dégradé radial et lumière douce.
class _Stage extends StatelessWidget {
  const _Stage({required this.product, required this.radius, this.child});

  final Product product;
  final double radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
}

/// Petite pastille sombre posée sur une photo (badge, stock).
class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppText.eyebrow(Colors.white).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

const _newTag = Bi('Neuf', 'New');

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.cart});

  final Product product;
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final sizes = product.availableSizes;
    final soldOut = product.stockOf() == 0;
    final open = product.hasSizes
        ? () {
            Usage.instance.tap('store.view:${product.id}');
            showProductSheet(context, product, cart);
          }
        : null;

    return Pressable(
      onTap: open,
      child: BezelCard(
        radius: 30,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: _Stage(
                product: product,
                radius: 22,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: ProductFigure(
                          product: product,
                          padding: const EdgeInsets.fromLTRB(18, 34, 18, 14),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: _Tag(
                        label: _newTag.of(context),
                        icon: AppIcons.sealCheck,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: _Tag(
                        label: soldOut
                            ? (product.preorder
                                      ? const Bi('Sur commande', 'On order')
                                      : const Bi('Épuisé', 'Sold out'))
                                  .of(context)
                            : l10n.stockLeft(product.stockOf()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (product.brand ?? product.category.label.of(context))
                        .toUpperCase(),
                    style: AppText.eyebrow(p.accentText),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.name.of(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(24, color: p.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.hasSizes && sizes.isNotEmpty
                        ? '${product.blurb.of(context)} · ${sizes.first}–${sizes.last}'
                        : product.blurb.of(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(13, color: p.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        _money(context, product.price),
                        style: AppText.body(
                          20,
                          weight: FontWeight.w700,
                          color: p.text,
                        ),
                      ),
                      const Spacer(),
                      if (product.hasSizes)
                        Semantics(
                          button: true,
                          label: const Bi('Voir', 'View').of(context),
                          child: _RoundTap(
                            icon: AppIcons.arrowRight,
                            onTap: open!,
                            gold: true,
                            size: 52,
                          ),
                        )
                      else
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: ListenableBuilder(
                              listenable: cart,
                              builder: (context, _) =>
                                  _Stepper(product: product, cart: cart),
                            ),
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
    );
  }
}

/// Bouton "Ajouter", qui devient un compteur - / + une fois l'article choisi.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.product, required this.cart});

  final Product product;
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final q = cart.quantityOf(product);
    final l10n = AppLocalizations.of(context);
    final p = context.palette;

    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.spring,
      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
      child: q == 0
          ? Semantics(
              key: const ValueKey('add'),
              button: true,
              label: l10n.addToCart,
              child: _RoundTap(
                icon: AppIcons.plus,
                onTap: () => cart.add(product),
                gold: true,
                size: 52,
              ),
            )
          : Container(
              key: const ValueKey('qty'),
              decoration: BoxDecoration(
                color: p.glass,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: p.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RoundTap(
                    icon: q == 1 ? AppIcons.trash : AppIcons.minus,
                    onTap: () => cart.remove(product),
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$q',
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        17,
                        weight: FontWeight.w600,
                        color: p.text,
                      ),
                    ),
                  ),
                  _RoundTap(
                    icon: AppIcons.plus,
                    onTap: () => cart.add(product),
                    gold: true,
                  ),
                ],
              ),
            ),
    );
  }
}

class _RoundTap extends StatelessWidget {
  const _RoundTap({
    required this.icon,
    required this.onTap,
    this.gold = false,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool gold;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gold ? Brand.gold : context.palette.hairline,
        ),
        child: Icon(
          icon,
          size: 18,
          color: gold ? Brand.ink : context.palette.text,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fiche article : galerie, tailles, ajout au panier.

/// Ouvre la fiche d'un article, façon page produit d'un site e-commerce.
Future<void> showProductSheet(
  BuildContext context,
  Product product,
  Cart cart,
) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: product.name.of(context),
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: AppMotion.medium,
    pageBuilder: (context, _, _) => _ProductSheet(product: product, cart: cart),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.spring,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ProductSheet extends StatefulWidget {
  const _ProductSheet({required this.product, required this.cart});

  final Product product;
  final Cart cart;

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  String? _size;
  bool _askSize = false;
  int _page = 0;

  Product get product => widget.product;

  void _add() {
    final size = _size;
    if (size == null) {
      setState(() => _askSize = true);
      return;
    }
    // À bord ou sur commande : dans les deux cas l'article va au panier, et
    // le panier demande ensuite les coordonnées du client.
    widget.cart.add(product, size);
    Usage.instance.tap('store.add:${product.id}');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final wide = screen.width >= 760;

    final gallery = _Gallery(
      product: product,
      page: _page,
      onPage: (i) => setState(() => _page = i),
    );
    final info = _SheetInfo(
      product: product,
      cart: widget.cart,
      size: _size,
      askSize: _askSize,
      onSize: (s) => setState(() {
        _size = s;
        _askSize = false;
      }),
      onAdd: _add,
    );

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 1000,
              maxHeight: wide ? 640 : screen.height,
            ),
            child: Material(
              // Fond plein sous le verre : la boutique ne transparaît pas.
              color: context.isDark
                  ? const Color(0xFF121317)
                  : const Color(0xFFF3F4F7),
              borderRadius: BorderRadius.circular(38),
              child: BezelCard(
                radius: 38,
                padding: const EdgeInsets.all(16),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 11, child: gallery),
                          const SizedBox(width: 28),
                          Expanded(flex: 9, child: info),
                        ],
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          SizedBox(height: 300, child: gallery),
                          const SizedBox(height: 20),
                          info,
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Galerie : photos détourées (ou illustration) sur un grand mot en filigrane.
class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.product,
    required this.page,
    required this.onPage,
  });

  final Product product;
  final int page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final count = math.max(1, product.photos.length);
    final word = (product.art?.number ?? product.category.label.en)
        .toUpperCase();

    return _Stage(
      product: product,
      radius: 28,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      word,
                      maxLines: 1,
                      style: AppText.display(
                        220,
                        color: Colors.white.withValues(alpha: 0.09),
                      ).copyWith(fontWeight: FontWeight.w600, height: 1),
                    ),
                  ),
                ),
              ),
            ),
            PageView.builder(
              itemCount: count,
              onPageChanged: onPage,
              itemBuilder: (context, i) => ProductFigure(
                product: product,
                photo: i,
                padding: const EdgeInsets.fromLTRB(36, 56, 36, 48),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: _Tag(label: _newTag.of(context), icon: AppIcons.sealCheck),
            ),
            if (count > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < count; i++)
                      AnimatedContainer(
                        duration: AppMotion.medium,
                        curve: AppMotion.spring,
                        width: i == page ? 22 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: i == page ? Brand.gold : Colors.white38,
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

class _SheetInfo extends StatelessWidget {
  const _SheetInfo({
    required this.product,
    required this.cart,
    required this.size,
    required this.askSize,
    required this.onSize,
    required this.onAdd,
  });

  final Product product;
  final Cart cart;
  final String? size;
  final bool askSize;
  final ValueChanged<String> onSize;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = size;
    final onBoard =
        selected != null &&
        product.stockOf(selected) - cart.quantityOf(product, selected) > 0;
    final verb = onBoard
        ? const Bi('Ajouter', 'Add')
        : const Bi('Commander', 'Order');
    final addLabel = selected == null
        ? const Bi('Choisir une taille', 'Select a size').of(context)
        : '${verb.of(context)} · ${_money(context, product.price)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (product.brand ?? product.category.label.of(context))
                      .toUpperCase(),
                  style: AppText.eyebrow(p.accentText),
                ),
              ),
              LiquidIconButton(
                icon: AppIcons.close,
                label: const Bi('Fermer', 'Close').of(context),
                size: 44,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            product.name.of(context),
            style: AppText.display(42, color: p.text),
          ),
          const SizedBox(height: 4),
          Text(
            product.blurb.of(context),
            style: AppText.body(16, color: p.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            _money(context, product.price),
            style: AppText.display(40, color: p.text),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Icon(
                AppIcons.ruler,
                size: 18,
                color: askSize ? const Color(0xFFFF6B6B) : p.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                const Bi('Taille', 'Size').of(context),
                style: AppText.body(
                  15,
                  weight: FontWeight.w600,
                  color: askSize ? const Color(0xFFFF6B6B) : p.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListenableBuilder(
            listenable: cart,
            builder: (context, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in product.sizes.entries)
                  _SizeChip(
                    label: e.key,
                    // Ce qui est déjà au panier n'est plus disponible.
                    // Un article commandable se choisit dans toutes les tailles.
                    available:
                        product.preorder ||
                        e.value - cart.quantityOf(product, e.key) > 0,
                    selected: e.key == selected,
                    onTap: () => onSize(e.key),
                  ),
              ],
            ),
          ),
          if (product.preorder) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.package, size: 18, color: p.accentText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    orderNotice.of(context),
                    style: AppText.body(13, color: p.textMuted),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          GlowButton(label: addLabel, icon: AppIcons.shoppingBag, onTap: onAdd),
          const SizedBox(height: 24),
          for (final d in product.details)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(AppIcons.check, size: 18, color: Brand.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      d.of(context),
                      style: AppText.body(14, color: p.text),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const _Notice(),
        ],
      ),
    );
  }
}

/// Une question sur la boutique : le passager écrit à Yanis sur WhatsApp.
Future<void> showStoreContactSheet(BuildContext context) {
  final title = const Bi(
    'Écrivez-moi sur WhatsApp',
    'Message me on WhatsApp',
  ).of(context);
  return _showWhatsAppSheet(
    context,
    eyebrow: const Bi('UNE QUESTION ?', 'ANY QUESTION?'),
    title: title,
    body: const Bi(
      'Une taille, une couleur, un autre modèle ? Je vous réponds vite.',
      'A size, a colour, another model? I reply quickly.',
    ),
    message: const Bi(
      'Bonjour Yanis, j’ai une question sur ta boutique.',
      'Hi Yanis, I have a question about your store.',
    ),
  );
}

/// Feuille avec le code QR WhatsApp de Yanis et un message déjà rempli.
/// La tablette n'envoie rien elle-même : le passager vise le code avec son
/// téléphone.
Future<void> _showWhatsAppSheet(
  BuildContext context, {
  required Bi eyebrow,
  required String title,
  Bi? body,
  List<Bi> steps = const [],
  required Bi message,
  double qrSize = 180,
}) {
  final link = AppConfig.whatsAppLink == null
      ? null
      : '${AppConfig.whatsAppLink}'
            '?text=${Uri.encodeComponent(message.of(context))}';

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: AppMotion.medium,
    transitionBuilder: (context, a, _, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
        scale: Tween(
          begin: 0.94,
          end: 1.0,
        ).animate(CurvedAnimation(parent: a, curve: AppMotion.spring)),
        child: child,
      ),
    ),
    pageBuilder: (context, _, _) {
      final p = context.palette;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Material(
              color: context.isDark
                  ? const Color(0xFF121317)
                  : const Color(0xFFF3F4F7),
              borderRadius: BorderRadius.circular(38),
              child: BezelCard(
                radius: 38,
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        eyebrow.of(context),
                        style: AppText.eyebrow(p.accentText),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppText.display(34, color: p.text),
                      ),
                      if (body != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          body.of(context),
                          textAlign: TextAlign.center,
                          style: AppText.body(16, color: p.textMuted),
                        ),
                      ],
                      // Une commande : trois étapes courtes, numérotées, à
                      // lire d'un coup d'œil.
                      for (final (i, step) in steps.indexed)
                        _Step(number: i + 1, text: step.of(context)),
                      const SizedBox(height: 22),
                      if (link != null)
                        QrCard(
                          data: link,
                          icon: AppIcons.whatsapp,
                          label: 'WhatsApp',
                          color: const Color(0xFF128C4A),
                          size: qrSize,
                        ),
                      if (steps.isEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          const Bi(
                            'Visez le code avec votre téléphone : le message '
                                'est déjà écrit, il ne reste qu’à l’envoyer.',
                            'Point your phone at the code: the message is '
                                'already written, just send it.',
                          ).of(context),
                          textAlign: TextAlign.center,
                          style: AppText.body(14, color: p.textMuted),
                        ),
                      ],
                      const SizedBox(height: 18),
                      PillButton(
                        label: const Bi('Fermer', 'Close').of(context),
                        filled: false,
                        onTap: () => Navigator.of(context).pop(),
                        trailing: const Icon(AppIcons.close),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.available,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool available;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected
        ? Brand.ink
        : (available ? p.text : p.textMuted.withValues(alpha: 0.5));
    return Semantics(
      button: true,
      enabled: available,
      selected: selected,
      child: Pressable(
        onTap: available ? onTap : null,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          width: 76,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected ? Brand.gold : p.glass,
            border: Border.all(
              color: selected ? Brand.gold : p.hairline,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: AppText.body(15, weight: FontWeight.w600, color: fg)
                .copyWith(
                  decoration: available ? null : TextDecoration.lineThrough,
                ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panier et paiement.

/// Panier : les articles choisis, le total, l'acompte et le reste à payer.
/// « Commander sur WhatsApp » ouvre le code QR avec la commande déjà écrite.
class _CartPanel extends StatelessWidget {
  const _CartPanel({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return BezelCard(
      radius: 34,
      padding: const EdgeInsets.all(24),
      child: ListenableBuilder(
        listenable: cart,
        builder: (context, _) => _CartView(
          cart: cart,
          onCheckout: () {
            Usage.instance.tap('store.checkout');
            // Le passager sort son téléphone : la session patiente.
            final session = SessionScope.of(context);
            session.setPaying(true);
            showOrderSheet(
              context,
              cart,
            ).whenComplete(() => session.setPaying(false));
          },
        ),
      ),
    );
  }
}

/// La commande part sur WhatsApp : le passager vise le code avec son
/// téléphone, ajoute son adresse et envoie. Yanis lui répond avec le numéro
/// pour l'acompte Interac.
Future<void> showOrderSheet(BuildContext context, Cart cart) {
  final deposit = _money(context, cart.deposit);
  return _showWhatsAppSheet(
    context,
    eyebrow: const Bi('VOTRE COMMANDE', 'YOUR ORDER'),
    title: const Bi('Commandez en 3 étapes', 'Order in 3 steps').of(context),
    steps: [
      const Bi('Scannez le code', 'Scan the code'),
      const Bi('Ajoutez votre adresse et envoyez', 'Add your address and send'),
      Bi(
        'Payez $deposit par Interac, le reste à la livraison',
        'Pay $deposit by Interac, the rest on delivery',
      ),
    ],
    message: Bi(
      orderMessage(cart, english: false),
      orderMessage(cart, english: true),
    ),
    qrSize: 300,
  );
}

/// Une étape de la commande : un grand numéro doré et quelques mots.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Brand.gold,
            ),
            child: Text(
              '$number',
              style: AppText.body(
                17,
                weight: FontWeight.w800,
                color: Brand.ink,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppText.body(
                18,
                weight: FontWeight.w600,
                color: context.palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView({required this.cart, required this.onCheckout});

  final Cart cart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;

    Widget amountRow(String label, double amount, {bool strong = false}) => Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppText.body(strong ? 18 : 14, color: p.textMuted),
          ),
        ),
        Text(
          _money(context, amount),
          style: strong
              ? AppText.display(36, color: p.text)
              : AppText.body(16, weight: FontWeight.w600, color: p.text),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.cartTitle, style: AppText.display(34, color: p.text)),
        const SizedBox(height: 18),
        if (cart.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.shoppingBag, size: 56, color: p.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    l10n.cartEmpty,
                    style: AppText.body(16, color: p.textMuted),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Expanded(
            child: ListView(
              children: [
                for (final line in cart.lines)
                  _CartLineRow(line: line, cart: cart),
              ],
            ),
          ),
          Divider(color: p.hairline),
          const SizedBox(height: 8),
          amountRow(l10n.total, cart.total, strong: true),
          const SizedBox(height: 4),
          amountRow(
            const Bi(
              'Acompte à la commande (50 %, Interac)',
              'Deposit when ordering (50%, Interac)',
            ).of(context),
            cart.deposit,
          ),
          amountRow(
            const Bi(
              'À la livraison (20 à 30 jours)',
              'On delivery (20 to 30 days)',
            ).of(context),
            cart.balance,
          ),
          const SizedBox(height: 16),
          GlowButton(
            label: const Bi(
              'Commander sur WhatsApp',
              'Order on WhatsApp',
            ).of(context),
            icon: AppIcons.whatsapp,
            onTap: onCheckout,
          ),
          const SizedBox(height: 10),
          Text(
            const Bi(
              'Pas satisfait à la livraison : remboursé.',
              'Not satisfied on delivery: refunded.',
            ).of(context),
            textAlign: TextAlign.center,
            style: AppText.body(13, color: p.textMuted),
          ),
        ],
      ],
    );
  }
}

class _CartLineRow extends StatelessWidget {
  const _CartLineRow({required this.line, required this.cart});

  final CartLine line;
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final product = line.product;
    final size = line.size;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 52,
            child: _Stage(
              product: product,
              radius: 14,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: ProductVisual(product: product, shadow: false),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${line.quantity} × ${product.name.of(context)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    15,
                    weight: FontWeight.w500,
                    color: p.text,
                  ),
                ),
                if (size != null)
                  Text(
                    '${product.blurb.of(context).split(' · ').first} · $size',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(13, color: p.textMuted),
                  ),
              ],
            ),
          ),
          Text(
            _money(context, line.subtotal),
            style: AppText.body(15, weight: FontWeight.w600, color: p.text),
          ),
          _RoundTap(
            icon: line.quantity == 1 ? AppIcons.trash : AppIcons.minus,
            onTap: () => cart.remove(product, size),
            size: 44,
          ),
        ],
      ),
    );
  }
}

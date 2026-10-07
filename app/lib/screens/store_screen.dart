import 'dart:math' as math;

import 'package:flutter/material.dart';
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
import '../widgets/mesh_background.dart';
import '../widgets/product_art.dart';
import '../widgets/qr_card.dart';
import '../widgets/section_scaffold.dart';

String _money(BuildContext context, double amount) => NumberFormat.currency(
  locale: Localizations.localeOf(context).languageCode == 'en'
      ? 'en_CA'
      : 'fr_CA',
  symbol: r'$',
  decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
).format(amount);

/// Boutique à bord : sneakers et maillots revendus (neufs, authentiques),
/// petits essentiels, panier et paiement par virement Interac (confirmé à la
/// main par Yanis, pas d'API Interac pour les particuliers).
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
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
    final products = [
      for (final p in catalog)
        if (_category == null || p.category == _category) p,
    ];

    final tabs = _CategoryTabs(
      selected: _category,
      onSelected: (c) => setState(() => _category = c),
    );
    final grid = _ProductGrid(
      key: ValueKey(_category),
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
                Expanded(flex: 4, child: panel),
              ],
            ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    AppLocalizations.of(context).storeSubtitle,
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
          child: Text(
            resellerNotice.of(context),
            style: AppText.body(12, color: p.textMuted),
          ),
        ),
      ],
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selected, required this.onSelected});

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
        for (final c in ProductCategory.values)
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
        ? () => showProductSheet(context, product, cart)
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
                    if (product.isResale)
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
            if (product.isResale)
              Positioned(
                left: 16,
                top: 16,
                child: _Tag(
                  label: _newTag.of(context),
                  icon: AppIcons.sealCheck,
                ),
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
                    preorderNotice.of(context),
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
  required Bi body,
  required Bi message,
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
                      const SizedBox(height: 10),
                      Text(
                        body.of(context),
                        textAlign: TextAlign.center,
                        style: AppText.body(16, color: p.textMuted),
                      ),
                      const SizedBox(height: 22),
                      if (link != null)
                        QrCard(
                          data: link,
                          icon: AppIcons.whatsapp,
                          label: 'WhatsApp',
                          color: const Color(0xFF128C4A),
                        ),
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

enum _Step { cart, details, pay, done }

class _CartPanel extends StatefulWidget {
  const _CartPanel({required this.cart});

  final Cart cart;

  @override
  State<_CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<_CartPanel> {
  _Step _step = _Step.cart;
  String _reference = '';
  double _paidTotal = 0;
  PlacedOrder? _order;
  bool _onOrderOnly = false;
  bool _clearing = false;

  SessionController? _session;

  @override
  void initState() {
    super.initState();
    widget.cart.addListener(_onCartChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session = SessionScope.of(context);
  }

  @override
  void dispose() {
    widget.cart.removeListener(_onCartChanged);
    _session?.setPaying(false);
    super.dispose();
  }

  void _setStep(_Step step) {
    setState(() => _step = step);
    // Pendant la saisie et le virement, le passager est sur le clavier ou
    // sur son téléphone : la session ne doit pas se terminer au bout de
    // 90 secondes.
    _session?.setPaying(step == _Step.details || step == _Step.pay);
  }

  /// Le panier a changé pendant la commande : les montants seraient faux,
  /// on revient au panier.
  void _onCartChanged() {
    if (!mounted || _clearing) return;
    if (_step == _Step.details || _step == _Step.pay) _setStep(_Step.cart);
  }

  /// La commande est enregistrée : on passe au virement s'il y a quelque
  /// chose à payer tout de suite, sinon c'est terminé.
  void _onPlaced(PlacedOrder order) {
    _order = order;
    _reference = order.reference;
    _paidTotal = widget.cart.payNow;
    _onOrderOnly = _paidTotal == 0;
    if (_onOrderOnly) {
      _finish();
    } else {
      _setStep(_Step.pay);
    }
  }

  void _confirmSent() {
    final order = _order;
    if (order != null) OrderService.claimTransfer(order);
    _finish();
  }

  void _finish() {
    _setStep(_Step.done);
    _clearing = true;
    widget.cart.clear();
    _clearing = false;
  }

  @override
  Widget build(BuildContext context) {
    return BezelCard(
      radius: 34,
      padding: const EdgeInsets.all(24),
      child: ListenableBuilder(
        listenable: widget.cart,
        builder: (context, _) => AnimatedSwitcher(
          duration: AppMotion.medium,
          switchInCurve: AppMotion.spring,
          transitionBuilder: (child, a) =>
              FadeTransition(opacity: a, child: child),
          child: switch (_step) {
            _Step.cart => _CartView(
              key: const ValueKey('cart'),
              cart: widget.cart,
              onCheckout: () => _setStep(_Step.details),
            ),
            _Step.details => _DetailsView(
              key: const ValueKey('details'),
              cart: widget.cart,
              onBack: () => _setStep(_Step.cart),
              onPlaced: _onPlaced,
            ),
            _Step.pay => _PayView(
              key: const ValueKey('pay'),
              total: _paidTotal,
              reference: _reference,
              onBack: () => _setStep(_Step.cart),
              onSent: _confirmSent,
            ),
            _Step.done => _DoneView(
              key: const ValueKey('done'),
              onOrderOnly: _onOrderOnly,
              onNewOrder: () => _setStep(_Step.cart),
            ),
          },
        ),
      ),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView({super.key, required this.cart, required this.onCheckout});

  final Cart cart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  cart.hasOnOrder
                      ? const Bi('À payer maintenant', 'To pay now').of(context)
                      : l10n.total,
                  style: AppText.body(18, color: p.textMuted),
                ),
              ),
              Text(
                _money(context, cart.payNow),
                style: AppText.display(36, color: p.text),
              ),
            ],
          ),
          if (cart.hasOnOrder) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    const Bi(
                      'À la livraison (20 à 30 jours)',
                      'On delivery (20 to 30 days)',
                    ).of(context),
                    style: AppText.body(14, color: p.textMuted),
                  ),
                ),
                Text(
                  _money(context, cart.payLater),
                  style: AppText.body(
                    16,
                    weight: FontWeight.w600,
                    color: p.text,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          GlowButton(
            label: const Bi('Commander', 'Order').of(context),
            icon: AppIcons.arrowRight,
            onTap: onCheckout,
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
                if (line.onOrder)
                  Text(
                    '${size ?? ''} · ${const Bi('sur commande', 'on order').of(context)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(13, color: p.accentText),
                  )
                else if (size != null)
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

/// Coordonnées du client, demandées avant le paiement. La commande est
/// enregistrée ici ; Yanis reçoit une alerte sur son téléphone.
class _DetailsView extends StatefulWidget {
  const _DetailsView({
    super.key,
    required this.cart,
    required this.onBack,
    required this.onPlaced,
  });

  final Cart cart;
  final VoidCallback onBack;
  final ValueChanged<PlacedOrder> onPlaced;

  @override
  State<_DetailsView> createState() => _DetailsViewState();
}

class _DetailsViewState extends State<_DetailsView> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _sending = false;
  bool _showErrors = false;
  bool _failed = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  bool get _needsAddress => widget.cart.hasOnOrder;
  bool get _nameOk => _name.text.trim().isNotEmpty;
  bool get _phoneOk => isValidPhone(_phone.text);
  bool get _addressOk => !_needsAddress || _address.text.trim().length >= 8;

  Future<void> _submit() async {
    if (_sending) return;
    if (!(_nameOk && _phoneOk && _addressOk)) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _sending = true;
      _failed = false;
    });
    try {
      final order = await OrderService.place(
        customer: CustomerDetails(
          name: _name.text,
          phone: _phone.text,
          address: _address.text,
        ),
        cart: widget.cart,
        language: Localizations.localeOf(context).languageCode,
      );
      if (mounted) widget.onPlaced(order);
    } catch (_) {
      // Pas de réseau : on le dit, et on propose WhatsApp à la place.
      if (mounted) {
        setState(() {
          _sending = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    InputDecoration field(String label, {String? error, String? hint}) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: _showErrors ? error : null,
          filled: true,
          fillColor: p.glass,
          labelStyle: AppText.body(15, color: p.textMuted),
          hintStyle: AppText.body(15, color: p.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: p.hairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: p.hairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Brand.gold, width: 1.5),
          ),
        );
    final text = AppText.body(17, weight: FontWeight.w500, color: p.text);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              LiquidIconButton(
                icon: AppIcons.arrowLeft,
                size: 40,
                onTap: widget.onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    const Bi('Vos coordonnées', 'Your details').of(context),
                    style: AppText.display(32, color: p.text),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            style: text,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: 80,
            buildCounter: _noCounter,
            decoration: field(
              const Bi('Votre nom', 'Your name').of(context),
              error: _nameOk
                  ? null
                  : const Bi(
                      'Indiquez votre nom',
                      'Enter your name',
                    ).of(context),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            style: text,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            maxLength: 24,
            buildCounter: _noCounter,
            decoration: field(
              const Bi('Téléphone (WhatsApp)', 'Phone (WhatsApp)').of(context),
              hint: '514 555-0199',
              error: _phoneOk
                  ? null
                  : const Bi(
                      'Numéro à 10 chiffres',
                      '10-digit phone number',
                    ).of(context),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            style: text,
            keyboardType: TextInputType.streetAddress,
            textCapitalization: TextCapitalization.words,
            minLines: 2,
            maxLines: 3,
            maxLength: 300,
            buildCounter: _noCounter,
            decoration: field(
              _needsAddress
                  ? const Bi(
                      'Adresse de livraison',
                      'Delivery address',
                    ).of(context)
                  : const Bi(
                      'Adresse de livraison (facultatif)',
                      'Delivery address (optional)',
                    ).of(context),
              error: _addressOk
                  ? null
                  : const Bi(
                      'Nécessaire pour vous livrer',
                      'Needed to deliver to you',
                    ).of(context),
            ),
          ),
          if (_needsAddress) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.package, size: 18, color: p.accentText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    const Bi(
                      'Les articles sur commande sont livrés chez vous en '
                          '20 à 30 jours. Je vous contacte sur WhatsApp, et '
                          'vous payez à la réception.',
                      'Items on order are delivered to your door in 20 to '
                          '30 days. I will message you on WhatsApp, and you '
                          'pay when they arrive.',
                    ).of(context),
                    style: AppText.body(13, color: p.textMuted),
                  ),
                ),
              ],
            ),
          ],
          if (_failed) ...[
            const SizedBox(height: 12),
            Text(
              const Bi(
                'Pas de réseau pour le moment. Réessayez, ou écrivez-moi sur '
                    'WhatsApp avec le bouton vert.',
                'No network right now. Try again, or message me on WhatsApp '
                    'with the green button.',
              ).of(context),
              style: AppText.body(14, color: const Color(0xFFFF6B6B)),
            ),
          ],
          const SizedBox(height: 16),
          GlowButton(
            label: _sending
                ? const Bi('Envoi…', 'Sending…').of(context)
                : const Bi(
                    'Valider la commande',
                    'Confirm the order',
                  ).of(context),
            icon: AppIcons.check,
            onTap: _submit,
          ),
          const SizedBox(height: 12),
          // Loi 25 : on dit simplement à quoi servent les coordonnées.
          Text(
            const Bi(
              'Vos coordonnées servent uniquement à traiter cette commande '
                  'et à vous contacter à son sujet.',
              'Your details are used only to process this order and to '
                  'contact you about it.',
            ).of(context),
            style: AppText.body(12, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Pas de compteur de caractères sous les champs.
Widget? _noCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) => null;

class _PayView extends StatelessWidget {
  const _PayView({
    super.key,
    required this.total,
    required this.reference,
    required this.onBack,
    required this.onSent,
  });

  final double total;
  final String reference;
  final VoidCallback onBack;
  final VoidCallback onSent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final email = AppConfig.interacEmail.isEmpty
        ? l10n.toConfigure
        : AppConfig.interacEmail;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              LiquidIconButton(
                icon: AppIcons.arrowLeft,
                size: 40,
                onTap: onBack,
              ),
              const SizedBox(width: 12),
              Text('Interac', style: AppText.display(34, color: p.text)),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.interacSend(_money(context, total)),
            style: AppText.body(16, color: p.textMuted),
          ),
          const SizedBox(height: 6),
          SelectableText(
            email,
            style: AppText.body(20, weight: FontWeight.w600, color: p.text),
          ),
          const SizedBox(height: 18),
          Text(l10n.interacCode, style: AppText.body(16, color: p.textMuted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Brand.gold, width: 1.5),
              color: Brand.gold.withValues(alpha: 0.12),
            ),
            child: Text(
              reference,
              style: AppText.display(
                38,
                color: p.text,
              ).copyWith(letterSpacing: 4),
            ),
          ),
          const SizedBox(height: 20),
          GlowButton(
            label: l10n.interacDone,
            icon: AppIcons.check,
            onTap: onSent,
          ),
          const SizedBox(height: 22),
          Text(
            l10n.whatsappAsk,
            textAlign: TextAlign.center,
            style: AppText.body(14, color: p.textMuted),
          ),
          const SizedBox(height: 12),
          Center(
            child: QrCard(
              data: AppConfig.whatsAppLink,
              icon: AppIcons.whatsapp,
              label: 'WhatsApp',
              color: const Color(0xFF128C4A),
              size: 120,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({
    super.key,
    required this.onNewOrder,
    required this.onOrderOnly,
  });

  final VoidCallback onNewOrder;

  /// Rien à payer tout de suite : la commande sera livrée et payée plus tard.
  final bool onOrderOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Brand.gold,
            ),
            child: const Icon(AppIcons.check, size: 44, color: Brand.ink),
          ).animate().scale(
            begin: const Offset(0.4, 0.4),
            duration: 700.ms,
            curve: Curves.elasticOut,
          ),
          const SizedBox(height: 22),
          Text(
            onOrderOnly
                ? const Bi(
                    'Commande reçue ! Je vous contacte sur WhatsApp pour la livraison.',
                    'Order received! I will message you on WhatsApp about delivery.',
                  ).of(context)
                : l10n.orderThanks,
            textAlign: TextAlign.center,
            style: AppText.display(28, color: p.text),
          ),
          const SizedBox(height: 22),
          PillButton(
            label: l10n.newOrder,
            filled: false,
            onTap: onNewOrder,
            trailing: const Icon(AppIcons.plus),
          ),
        ],
      ),
    );
  }
}

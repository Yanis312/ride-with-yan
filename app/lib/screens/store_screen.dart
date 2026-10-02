import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../config.dart';
import '../data/store_catalog.dart';
import '../l10n/app_localizations.dart';
import '../navigation/sections.dart';
import '../session/session_controller.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/mesh_background.dart';
import '../widgets/qr_card.dart';
import '../widgets/section_scaffold.dart';

String _money(BuildContext context, double amount) => NumberFormat.currency(
  locale: Localizations.localeOf(context).languageCode == 'en'
      ? 'en_CA'
      : 'fr_CA',
  symbol: r'$',
).format(amount);

/// Boutique à bord : catalogue, panier et paiement par virement Interac
/// (confirmé à la main par Yanis, pas d'API Interac pour les particuliers).
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cart = SessionScope.of(context).cart;
    final compact = MediaQuery.sizeOf(context).width < 900;

    final grid = _ProductGrid(cart: cart, columns: compact ? 2 : 3);
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
                const SizedBox(height: 16),
                grid,
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
                      const SizedBox(height: 18),
                      Expanded(child: SingleChildScrollView(child: grid)),
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

class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => AnimatedScale(
        scale: cart.isEmpty ? 0 : 1,
        duration: AppMotion.medium,
        curve: AppMotion.spring,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [Brand.goldSoft, Brand.gold],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.shoppingBag, size: 20, color: Brand.ink),
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
  const _ProductGrid({required this.cart, required this.columns});

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
            for (final (i, product) in catalog.indexed)
              SizedBox(
                    width: width,
                    child: _ProductCard(product: product, cart: cart),
                  )
                  .animate()
                  .fadeIn(
                    delay: (60 * i).ms,
                    duration: 600.ms,
                    curve: AppMotion.spring,
                  )
                  .slideY(
                    begin: 0.1,
                    delay: (60 * i).ms,
                    curve: AppMotion.spring,
                  ),
          ],
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.cart});

  final Product product;
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);

    return BezelCard(
      radius: 30,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visuel de l'article : dégradé et grande icône, en attendant les photos.
          AspectRatio(
            aspectRatio: 1.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.5),
                  radius: 1.2,
                  colors: product.colors,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      product.icon,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        l10n.stockLeft(product.stock),
                        style: AppText.body(
                          12,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            product.name.of(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.display(24, color: p.text),
          ),
          const SizedBox(height: 4),
          Text(
            product.blurb.of(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(13, color: p.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                _money(context, product.price),
                style: AppText.body(19, weight: FontWeight.w600, color: p.text),
              ),
              const Spacer(),
              ListenableBuilder(
                listenable: cart,
                builder: (context, _) => _Stepper(product: product, cart: cart),
              ),
            ],
          ),
        ],
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
// Panier et paiement.

enum _Step { cart, pay, done }

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

  void _goToPayment() {
    // Code court à mettre dans le message Interac pour retrouver la commande.
    final n = math.Random().nextInt(9000) + 1000;
    setState(() {
      _reference = 'RWY-$n';
      _paidTotal = widget.cart.total;
      _step = _Step.pay;
    });
  }

  void _confirmSent() {
    setState(() => _step = _Step.done);
    widget.cart.clear();
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
              onCheckout: _goToPayment,
            ),
            _Step.pay => _PayView(
              key: const ValueKey('pay'),
              total: _paidTotal,
              reference: _reference,
              onBack: () => setState(() => _step = _Step.cart),
              onSent: _confirmSent,
            ),
            _Step.done => _DoneView(
              key: const ValueKey('done'),
              onNewOrder: () => setState(() => _step = _Step.cart),
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
                for (final e in cart.lines.entries)
                  Builder(
                    builder: (context) {
                      final product = catalog.firstWhere((x) => x.id == e.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: product.colors,
                                ),
                              ),
                              child: Icon(
                                product.icon,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${e.value} × ${product.name.of(context)}',
                                maxLines: 2,
                                style: AppText.body(
                                  15,
                                  weight: FontWeight.w500,
                                  color: p.text,
                                ),
                              ),
                            ),
                            Text(
                              _money(context, product.price * e.value),
                              style: AppText.body(
                                15,
                                weight: FontWeight.w600,
                                color: p.text,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          Divider(color: p.hairline),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.total, style: AppText.body(18, color: p.textMuted)),
              const Spacer(),
              Text(
                _money(context, cart.total),
                style: AppText.display(36, color: p.text),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlowButton(
            label: l10n.checkout,
            icon: AppIcons.arrowRight,
            onTap: onCheckout,
          ),
        ],
      ],
    );
  }
}

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
  const _DoneView({super.key, required this.onNewOrder});

  final VoidCallback onNewOrder;

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
            l10n.orderThanks,
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

import 'dart:math' as math;

import '../backend/backend.dart';
import 'store_catalog.dart';

/// Coordonnées saisies par le client avant le paiement.
class CustomerDetails {
  const CustomerDetails({
    required this.name,
    required this.phone,
    this.address,
  });

  final String name;
  final String phone;
  final String? address;
}

/// Commande déposée dans la base : son identifiant (aléatoire, sert de clé
/// pour signaler ensuite le virement) et sa référence lisible.
class PlacedOrder {
  const PlacedOrder(this.id, this.reference);

  final String id;
  final String reference;
}

/// Un numéro de téléphone plausible : au moins 10 chiffres.
bool isValidPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 10 &&
      digits.length <= 15 &&
      RegExp(r'^[0-9+() .-]{7,24}$').hasMatch(value.trim());
}

/// Lignes de la commande telles qu'elles sont enregistrées : le nom et le
/// prix sont copiés, pour que la commande reste lisible même si le
/// catalogue change ensuite.
List<Map<String, dynamic>> orderLines(Cart cart) => [
  for (final line in cart.lines)
    {
      'id': line.product.id,
      'name': line.product.name.fr,
      'size': line.size ?? '',
      'qty': line.quantity,
      'price': line.product.price,
      'on_order': line.onOrder,
    },
];

abstract final class OrderService {
  static final _random = math.Random.secure();

  /// Identifiant aléatoire au format UUID v4.
  static String _uuid() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }

  /// Code court à mettre dans le message Interac pour retrouver la commande.
  static String newReference() => 'RWY-${_random.nextInt(9000) + 1000}';

  /// Enregistre la commande. Lève une erreur si la base est injoignable :
  /// l'appelant propose alors de passer par WhatsApp.
  static Future<PlacedOrder> place({
    required CustomerDetails customer,
    required Cart cart,
    required String language,
  }) async {
    final order = PlacedOrder(_uuid(), newReference());
    final address = customer.address?.trim();
    await Backend.insert('orders', {
      'id': order.id,
      'reference': order.reference,
      'name': customer.name.trim(),
      'phone': customer.phone.trim(),
      'address': (address == null || address.isEmpty) ? null : address,
      'language': language == 'en' ? 'en' : 'fr',
      'lines': orderLines(cart),
      'pay_now': cart.payNow,
      'pay_later': cart.payLater,
    });
    return order;
  }

  /// Le client a touché « Virement envoyé ». Sans réseau, tant pis : la
  /// commande est déjà enregistrée.
  static Future<void> claimTransfer(PlacedOrder order) async {
    try {
      await Backend.rpc('claim_transfer', {
        'order_id': order.id,
        'order_reference': order.reference,
      });
    } catch (_) {
      // Voir le commentaire de la méthode.
    }
  }
}

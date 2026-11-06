import 'store_catalog.dart';

/// Montant en dollars, sans décimales quand il est rond : « 80 $ » / « $80 ».
String orderAmount(double amount, {required bool english}) {
  final digits = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  return english ? '\$$digits' : '${digits.replaceAll('.', ',')} \$';
}

/// Message WhatsApp déjà rempli quand le passager commande : les articles,
/// le total, l'acompte, et la place pour son adresse. La tablette n'envoie
/// rien elle-même ; le passager l'envoie depuis son téléphone.
String orderMessage(Cart cart, {required bool english}) {
  String money(double v) => orderAmount(v, english: english);
  final items = [
    for (final line in cart.lines)
      '- ${line.quantity} × ${english ? line.product.name.en : line.product.name.fr}'
          ' (${english ? line.product.category.label.en : line.product.category.label.fr})'
          '${line.size == null ? '' : (english ? ', size ${line.size}' : ', taille ${line.size}')}'
          ' : ${money(line.subtotal)}',
  ];

  return [
    english
        ? 'Hi Yanis, I would like to order:'
        : 'Bonjour Yanis, je voudrais commander :',
    ...items,
    english
        ? 'Total: ${money(cart.total)} · 50% deposit: ${money(cart.deposit)}'
        : 'Total : ${money(cart.total)} · acompte 50 % : ${money(cart.deposit)}',
    '',
    english ? 'My delivery address:' : 'Mon adresse de livraison :',
  ].join('\n');
}

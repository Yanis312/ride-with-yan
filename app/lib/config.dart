/// Coordonnées affichées dans l'app. À remplir par Yanis : tant qu'une valeur
/// est vide, l'élément correspondant affiche "à configurer" au lieu d'un lien.
abstract final class AppConfig {
  /// URL publique du profil, ex. https://www.linkedin.com/in/votre-nom
  static const linkedInUrl = '';

  /// Numéro WhatsApp au format international sans "+", ex. 15145550199
  static const whatsAppNumber = '';

  /// Courriel qui reçoit les virements Interac de la boutique.
  static const interacEmail = '';

  static String? get whatsAppLink =>
      whatsAppNumber.isEmpty ? null : 'https://wa.me/$whatsAppNumber';
}

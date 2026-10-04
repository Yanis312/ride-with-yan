/// Coordonnées affichées dans l'app. À remplir par Yanis : tant qu'une valeur
/// est vide, l'élément correspondant affiche "à configurer" au lieu d'un lien.
abstract final class AppConfig {
  /// URL publique du profil, ex. https://www.linkedin.com/in/votre-nom
  static const linkedInUrl =
      'https://www.linkedin.com/in/yanis-garoui-29887a275';

  /// Numéro WhatsApp au format international sans "+", ex. 15145550199
  static const whatsAppNumber = '14389948668';

  /// Courriel qui reçoit les virements Interac de la boutique.
  static const interacEmail = 'yanisgaroui1@gmail.com';

  /// Volume maximal du coin musique (0 à 100) : jamais trop fort en conduisant.
  static const maxMusicVolume = 70;

  /// Base en ligne (Supabase, plan gratuit) du panneau d'administration.
  /// Cette clé est publique par nature : les droits sont gérés par la base.
  static const supabaseUrl = 'https://jwwftxjbswpwtbkluslz.supabase.co';
  static const supabaseKey = 'sb_publishable_HQyveAWuMCiS0PLoTFrJmg_Ga6v5rsp';

  static String? get whatsAppLink =>
      whatsAppNumber.isEmpty ? null : 'https://wa.me/$whatsAppNumber';
}

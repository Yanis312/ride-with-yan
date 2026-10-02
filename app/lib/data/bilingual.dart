import 'package:flutter/widgets.dart';

/// Texte de contenu en deux langues (catalogue, portfolio, profil).
/// Les libellés d'interface, eux, passent par les fichiers ARB.
@immutable
class Bi {
  const Bi(this.fr, this.en);

  final String fr;
  final String en;

  String of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : fr;
}

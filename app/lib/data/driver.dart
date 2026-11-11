import 'bilingual.dart';

/// Une photo de voyage de Yanis, avec la ville et le pays.
typedef TravelPhoto = ({String asset, Bi place});

/// Contenu de l'écran « Votre chauffeur ». Textes à ajuster par Yanis.
abstract final class Driver {
  static const firstName = 'Yanis';

  static const story = Bi(
    'Originaire de Kabylie, en Algérie, j’ai d’abord fait un master en génie '
        'civil. Arrivé au Canada, je me suis reconverti en informatique au '
        'Collège La Cité. Aujourd’hui, je suis développeur .NET, professeur à '
        'temps partiel… et votre chauffeur.\n\n'
        'Cette tablette, c’est moi qui l’ai programmée. J’adore voyager, '
        'découvrir de nouvelles villes et rencontrer des gens : '
        'n’hésitez pas à me demander une bonne adresse !',
    'Originally from Kabylie, in Algeria, I first earned a master’s degree in '
        'civil engineering. After moving to Canada, I switched to computer '
        'science at Collège La Cité. Today I’m a .NET developer, a part-time '
        'professor… and your driver.\n\n'
        'I programmed this tablet myself. I love travelling, discovering new '
        'cities and meeting people: feel free to ask me for a good spot!',
  );

  static const languages = [
    Bi('Français', 'French'),
    Bi('Anglais', 'English'),
    Bi('Arabe', 'Arabic'),
    Bi('Kabyle', 'Kabyle'),
  ];

  /// Pays où Yanis a vécu ou voyagé, avec leur drapeau.
  static const countries = [
    ('🇩🇿', Bi('Algérie', 'Algeria')),
    ('🇨🇦', Bi('Canada', 'Canada')),
    ('🇫🇷', Bi('France', 'France')),
    ('🇧🇪', Bi('Belgique', 'Belgium')),
    ('🇳🇱', Bi('Pays-Bas', 'Netherlands')),
    ('🇩🇪', Bi('Allemagne', 'Germany')),
  ];

  static const List<TravelPhoto> photos = [
    (
      asset: 'assets/driver/paris.jpg',
      place: Bi('Paris, France', 'Paris, France'),
    ),
    (
      asset: 'assets/driver/lille.jpg',
      place: Bi('Lille, France', 'Lille, France'),
    ),
    (
      asset: 'assets/driver/bruxelles-galeries.jpg',
      place: Bi('Bruxelles, Belgique', 'Brussels, Belgium'),
    ),
    (
      asset: 'assets/driver/bruxelles-manneken-pis.jpg',
      place: Bi('Bruxelles, Belgique', 'Brussels, Belgium'),
    ),
    (
      asset: 'assets/driver/amsterdam-canal.jpg',
      place: Bi('Amsterdam, Pays-Bas', 'Amsterdam, Netherlands'),
    ),
    (
      asset: 'assets/driver/amsterdam-dam.jpg',
      place: Bi('Amsterdam, Pays-Bas', 'Amsterdam, Netherlands'),
    ),
    (
      asset: 'assets/driver/cologne.jpg',
      place: Bi('Cologne, Allemagne', 'Cologne, Germany'),
    ),
    (
      asset: 'assets/driver/niagara.jpg',
      place: Bi('Chutes du Niagara, Canada', 'Niagara Falls, Canada'),
    ),
  ];
}

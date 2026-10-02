import 'package:flutter/widgets.dart';

import '../theme/app_icons.dart';
import 'bilingual.dart';

/// Contenu de l'aperçu "profil LinkedIn". À ajuster par Yanis pour qu'il
/// corresponde exactement à son vrai profil.
abstract final class Profile {
  static const name = 'Yanis Garoui';
  static const headline = Bi(
    'Développeur Full Stack .NET, React et Flutter',
    'Full Stack Developer .NET, React and Flutter',
  );
  static const location = Bi('Montréal, Québec', 'Montréal, Quebec');
  static const about = Bi(
    'Développeur ERP et professeur à temps partiel, je conçois des sites, des applications et des automatisations pour les entreprises. Cette tablette, c’est moi qui l’ai programmée.',
    'ERP developer and part-time teacher, I build websites, apps and automations for businesses. I programmed this very tablet.',
  );

  static const experience = [
    (
      AppIcons.briefcase,
      Bi('Développeur ERP', 'ERP Developer'),
      Bi(
        'Solutions de gestion sur mesure, C# et .NET',
        'Custom business software, C# and .NET',
      ),
    ),
    (
      AppIcons.graduationCap,
      Bi('Professeur à temps partiel', 'Part-time teacher'),
      Bi(
        'Programmation et développement web',
        'Programming and web development',
      ),
    ),
    (
      AppIcons.lightning,
      Bi('Fondateur, Ride with Yan', 'Founder, Ride with Yan'),
      Bi(
        'Cette app : Flutter, ASP.NET Core, Azure',
        'This app: Flutter, ASP.NET Core, Azure',
      ),
    ),
  ];

  static const skills = [
    'C#',
    '.NET',
    'ASP.NET Core',
    'React',
    'Flutter',
    'Azure',
    'Docker',
    'Kubernetes',
    'SQL',
    'IA générative',
  ];

  static const languages = [
    Bi('Français', 'French'),
    Bi('Anglais', 'English'),
    Bi('Arabe', 'Arabic'),
    Bi('Kabyle', 'Kabyle'),
  ];
}

typedef ExperienceLine = (IconData, Bi, Bi);

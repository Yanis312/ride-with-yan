import 'bilingual.dart';

/// Une ligne de l'aperçu LinkedIn : expérience, formation, certification ou
/// projet. Les textes viennent du vrai profil de Yanis (novembre 2026).
class ProfileEntry {
  const ProfileEntry({
    required this.title,
    required this.org,
    required this.dates,
    this.place,
    this.detail,
    this.logo,
  });

  final Bi title;
  final Bi org;
  final Bi dates;
  final Bi? place;
  final Bi? detail;

  /// Initiales affichées dans la vignette, faute de logo.
  final String? logo;
}

/// Contenu de l'aperçu "profil LinkedIn", calqué sur le vrai profil.
abstract final class Profile {
  static const name = 'Yanis Garoui';
  static const pronoun = 'il';
  static const avatar = 'assets/profile/avatar.jpg';
  static const cover = 'assets/profile/cover.jpg';

  static const headline = Bi(
    '.NET Software Developer | Flutter & Azure AI | Part-time Instructor (La Cité)',
    '.NET Software Developer | Flutter & Azure AI | Part-time Instructor (La Cité)',
  );
  static const location = Bi(
    'Ottawa, Ontario, Canada',
    'Ottawa, Ontario, Canada',
  );
  static const followers = Bi('1 308 abonnés', '1,308 followers');
  static const connections = Bi('Plus de 500 relations', '500+ connections');
  static const openToWork = Bi(
    'À l’écoute de nouvelles opportunités',
    'Open to work',
  );
  static const openToWorkDetail = Bi(
    'Ottawa, ON + 3 de plus | Sur site · Hybride · À distance',
    'Ottawa, ON + 3 more | On-site · Hybrid · Remote',
  );
  static const school = 'Collège La Cité';

  static const about = Bi(
    'Développeur .NET avec 2 ans d’expérience en production sur un ERP multi-modules utilisé par environ 1 500 utilisateurs. Je me spécialise dans les intégrations API REST (processeurs de paiement, catalogues fournisseurs, Google Maps, Oracle NetSuite) et je livre des fonctionnalités full-stack Web et Desktop avec C#, ASP.NET MVC, WinForms, React et DevExtreme. Je construis aussi des workflows d’automatisation IA avec n8n et des agents IA.\n\nBilingue (français/anglais), résident permanent, disponible en télétravail, en hybride ou sur site partout au Canada.\n\nMon projet personnel : Ride with Yan, l’application de cette tablette, que j’ai conçue et codée seul.',
    '.NET developer with 2 years of production experience on a multi-module ERP used by about 1,500 people. I specialize in REST API integrations (payment processors, supplier catalogs, Google Maps, Oracle NetSuite) and ship full-stack Web and Desktop features with C#, ASP.NET MVC, WinForms, React and DevExtreme. I also build AI automation workflows with n8n and AI agents.\n\nBilingual (French/English), permanent resident, available remote, hybrid or on-site anywhere in Canada.\n\nMy personal project: Ride with Yan, the app on this very tablet, which I designed and built on my own.',
  );

  static const experience = [
    ProfileEntry(
      title: Bi(
        'Professeur à temps partiel (programmation informatique)',
        'Part-time Professor (Computer Programming)',
      ),
      org: Bi(
        'Collège La Cité · CDD temps partiel',
        'Collège La Cité · Part-time contract',
      ),
      dates: Bi('sept. 2026 – aujourd’hui', 'Sep 2026 – Present'),
      place: Bi(
        'Ottawa, Ontario, Canada · Sur site',
        'Ottawa, Ontario, Canada · On-site',
      ),
      detail: Bi(
        'Cours de développement web côté serveur avec Node.js et Express.js : API REST, HTTP, bases de données, authentification, HTTPS et WebSockets.',
        'Server-side web development course with Node.js and Express.js: REST APIs, HTTP, databases, authentication, HTTPS and WebSockets.',
      ),
      logo: 'LC',
    ),
    ProfileEntry(
      title: Bi(
        'Software Developer .NET | Web & Desktop | REST API Integrations',
        'Software Developer .NET | Web & Desktop | REST API Integrations',
      ),
      org: Bi('Surfagest · CDI à temps plein', 'Surfagest · Full-time'),
      dates: Bi(
        'août 2024 – juil. 2026 · 2 ans',
        'Aug 2024 – Jul 2026 · 2 yrs',
      ),
      place: Bi('Gatineau, QC · Sur site', 'Gatineau, QC · On-site'),
      detail: Bi(
        'ERP multi-modules (~1 500 utilisateurs) : CRM, ventes, inventaire, entrepôt, PDV. Intégrations de paiement (Nuvei, Monark), Google Maps, Oracle NetSuite et plus de 10 fournisseurs. C#, ASP.NET MVC, WinForms, React, DevExtreme, Azure DevOps.',
        'Multi-module ERP (~1,500 users): CRM, sales, inventory, warehouse, POS. Payment integrations (Nuvei, Monark), Google Maps, Oracle NetSuite and 10+ suppliers. C#, ASP.NET MVC, WinForms, React, DevExtreme, Azure DevOps.',
      ),
      logo: 'S',
    ),
    ProfileEntry(
      title: Bi(
        'Développeur d’applications mobiles junior (temps partiel)',
        'Junior Mobile Application Developer (Part-time)',
      ),
      org: Bi('Tasuqilt inc · Stage', 'Tasuqilt inc · Internship'),
      dates: Bi(
        'avr. 2024 – sept. 2024 · 6 mois',
        'Apr 2024 – Sep 2024 · 6 mos',
      ),
      place: Bi(
        'Ottawa, Ontario, Canada · À distance',
        'Ottawa, Ontario, Canada · Remote',
      ),
      detail: Bi(
        'Jeu de mémoire tamazight-français avec reconnaissance vocale, en Flutter.',
        'Tamazight-French memory game with voice recognition, in Flutter.',
      ),
      logo: 'T',
    ),
    ProfileEntry(
      title: Bi(
        'Technicien de soutien informatique',
        'Information Technology Support Technician',
      ),
      org: Bi(
        'École secondaire Si Hcen Outaleb',
        'École secondaire Si Hcen Outaleb',
      ),
      dates: Bi(
        'avr. 2024 – sept. 2024 · 6 mois',
        'Apr 2024 – Sep 2024 · 6 mos',
      ),
      logo: 'SH',
    ),
  ];

  static const education = [
    ProfileEntry(
      title: Bi('Collège La Cité', 'Collège La Cité'),
      org: Bi('DEC, programmation informatique', 'DEC, Computer Programming'),
      dates: Bi('2023 – 2024', '2023 – 2024'),
      logo: 'LC',
    ),
    ProfileEntry(
      title: Bi(
        'Université Mouloud Mammeri Tizi-Ouzou',
        'Université Mouloud Mammeri Tizi-Ouzou',
      ),
      org: Bi('Master, génie civil', 'Master’s degree, Civil Engineering'),
      dates: Bi('2019 – 2021', '2019 – 2021'),
      logo: 'UM',
    ),
  ];

  static const certifications = [
    ProfileEntry(
      title: Bi(
        'Certificate of completion: Claude Code 101',
        'Certificate of completion: Claude Code 101',
      ),
      org: Bi('Anthropic', 'Anthropic'),
      dates: Bi('Émise en mai 2026', 'Issued May 2026'),
      logo: 'A',
    ),
    ProfileEntry(
      title: Bi(
        'Certificate of completion: Claude 101',
        'Certificate of completion: Claude 101',
      ),
      org: Bi('Anthropic', 'Anthropic'),
      dates: Bi('Émise en mai 2026', 'Issued May 2026'),
      logo: 'A',
    ),
  ];

  static const projects = [
    ProfileEntry(
      title: Bi('Ride with Yan', 'Ride with Yan'),
      org: Bi('Projet personnel', 'Personal project'),
      dates: Bi('oct. 2026 – aujourd’hui', 'Oct 2026 – Present'),
      detail: Bi(
        'Cette app : Flutter/Dart (Android et WebAssembly), Supabase/PostgreSQL avec RLS, assistant IA « Yan » avec Azure OpenAI via Azure AI Foundry, Terraform, 133 tests automatisés, CI/CD GitHub Actions et Azure Pipelines.',
        'This app: Flutter/Dart (Android and WebAssembly), Supabase/PostgreSQL with RLS, “Yan” AI assistant with Azure OpenAI through Azure AI Foundry, Terraform, 133 automated tests, CI/CD with GitHub Actions and Azure Pipelines.',
      ),
      logo: 'RY',
    ),
    ProfileEntry(
      title: Bi('React Booking System', 'React Booking System'),
      org: Bi('Full stack MERN', 'Full stack MERN'),
      dates: Bi('janv. 2024 – avr. 2024', 'Jan 2024 – Apr 2024'),
      detail: Bi(
        'Réservation d’hôtels : interface React, API Node.js, base MongoDB.',
        'Hotel booking: React interface, Node.js API, MongoDB database.',
      ),
      logo: 'RB',
    ),
  ];

  static const skills = [
    'C#',
    '.NET',
    'ASP.NET MVC',
    'React',
    'Flutter',
    'Dart',
    'Azure AI Foundry',
    'Azure OpenAI',
    'Terraform',
    'Supabase',
    'PostgreSQL',
    'Playwright',
    'GitHub Actions',
    'Azure DevOps',
    'Docker',
    'n8n',
    'REST API',
  ];

  static const languages = [
    Bi('Français', 'French'),
    Bi('Anglais', 'English'),
    Bi('Arabe', 'Arabic'),
    Bi('Kabyle', 'Kabyle'),
  ];
}

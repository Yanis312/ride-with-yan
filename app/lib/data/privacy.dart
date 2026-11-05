import 'bilingual.dart';

/// Politique de confidentialité de la tablette.
///
/// Ottawa et Gatineau : deux lois s'appliquent. Au Québec, la Loi 25 (loi
/// sur la protection des renseignements personnels dans le secteur privé) ;
/// en Ontario, la loi fédérale (LPRPDE / PIPEDA). Le texte décrit ce que
/// l'app fait réellement : à mettre à jour si une fonction change.
///
/// Ce n'est pas un avis juridique : une base honnête et claire, à faire
/// relire si l'activité grandit.

const privacyUpdated = Bi(
  'Mise à jour : 5 novembre 2026',
  'Updated: November 5, 2026',
);

const privacyIntro = Bi(
  'Cette tablette est installée dans la voiture de Yanis Garoui, chauffeur à '
      'Ottawa et Gatineau. Voici, simplement, ce qu’elle recueille, pourquoi, '
      'et vos droits.',
  'This tablet is installed in the car of Yanis Garoui, a driver in Ottawa '
      'and Gatineau. Here is, simply, what it collects, why, and your rights.',
);

/// (titre, texte) de chaque section.
const privacySections = <(Bi, Bi)>[
  (
    Bi('Rapports de plantage', 'Crash reports'),
    Bi(
      'Si l’app plante, un rapport technique est envoyé à Sentry, aux '
          'États-Unis, pour corriger le problème : type d’appareil et erreur. '
          'Il ne contient ni votre nom, ni votre commande, ni image de l’écran.',
      'If the app crashes, a technical report is sent to Sentry, in the '
          'United States, to fix the problem: device type and error. It '
          'contains neither your name, nor your order, nor a screen image.',
    ),
  ),
  (
    Bi('Responsable', 'Person in charge'),
    Bi(
      'Yanis Garoui est responsable de la protection des renseignements '
          'personnels. Pour toute question ou demande : yanisgaroui1@gmail.com.',
      'Yanis Garoui is responsible for protecting personal information. For '
          'any question or request: yanisgaroui1@gmail.com.',
    ),
  ),
  (
    Bi(
      'Sans commande : rien qui vous identifie',
      'Without an order: nothing that identifies you',
    ),
    Bi(
      'Regarder, écouter, voter ou consulter la météo ne demande ni nom, ni '
          'compte, ni caméra. La tablette compte de façon anonyme les écrans '
          'ouverts et les boutons touchés, avec un numéro tiré au hasard et '
          'oublié à la fin de la course, pour savoir ce qui plaît. Les votes '
          'du sondage sont de simples compteurs.',
      'Watching, listening, voting or checking the weather needs no name, no '
          'account and no camera. The tablet anonymously counts the screens '
          'opened and buttons tapped, with a random number forgotten at the '
          'end of the ride, to learn what passengers enjoy. Poll votes are '
          'simple counters.',
    ),
  ),
  (
    Bi('Si vous commandez', 'If you place an order'),
    Bi(
      'La commande se fait sur WhatsApp, depuis votre téléphone : la tablette '
          'ne recueille ni votre nom, ni votre numéro, ni votre adresse. Ce que '
          'vous envoyez (articles, adresse) sert uniquement à traiter la '
          'commande, à vous joindre et à vous livrer. Ce n’est jamais vendu ni '
          'utilisé pour de la publicité.',
      'You order on WhatsApp, from your own phone: the tablet collects '
          'neither your name, nor your number, nor your address. What you send '
          '(items, address) is used only to process the order, reach you and '
          'deliver it. It is never sold or used for advertising.',
    ),
  ),
  (
    Bi('Où vont vos renseignements', 'Where your information goes'),
    Bi(
      'Votre commande arrive sur le WhatsApp de Yanis, et seul Yanis la lit. '
          'Meta traite ce message selon ses propres règles. Le paiement de '
          'l’acompte passe par Interac, depuis votre banque.',
      'Your order reaches Yanis on WhatsApp, and only Yanis reads it. Meta '
          'handles that message under its own rules. The deposit is paid by '
          'Interac, from your own bank.',
    ),
  ),
  (
    Bi('L’assistant', 'The assistant'),
    Bi(
      'Les questions posées à l’assistant sont envoyées au service Azure '
          'OpenAI de Microsoft, dans un centre de données au Canada, pour '
          'produire la réponse (et à Azure Speech, au Canada, si vous l’écoutez). Nous ne les enregistrons pas ; seul un '
          'compteur anonyme limite le nombre de questions. Microsoft ne s’en '
          'sert pas pour entraîner ses modèles, mais peut les garder jusqu’à '
          '30 jours pour détecter les abus. N’y écrivez pas de renseignements '
          'personnels.',
      'Questions asked to the assistant are sent to Microsoft’s Azure OpenAI '
          'service, in a data centre in Canada, to produce the answer (and to Azure '
          'Speech, in Canada, if you listen to it). We do '
          'not store them; only an anonymous counter limits the number of '
          'questions. Microsoft does not use them to train its models, but '
          'may keep them up to 30 days to detect abuse. Do not include '
          'personal information.',
    ),
  ),
  (
    Bi('Services externes', 'Outside services'),
    Bi(
      'Les vidéos et la musique sont lues par YouTube (Google), qui peut '
          'recueillir des données selon sa propre politique. La météo vient '
          'd’Open-Meteo et d’Environnement Canada, les nouvelles de '
          'Radio-Canada et de CBC : ces services ne reçoivent aucun '
          'renseignement sur vous.',
      'Videos and music are played by YouTube (Google), which may collect '
          'data under its own policy. Weather comes from Open-Meteo and '
          'Environment Canada, news from Radio-Canada and CBC: these services '
          'receive no information about you.',
    ),
  ),
  (
    Bi('Combien de temps', 'How long'),
    Bi(
      'Vos coordonnées sont gardées le temps de la commande et de la '
          'livraison, puis effacées au plus tard 12 mois après. Les montants '
          'et les articles vendus, sans votre nom, sont conservés 6 ans pour '
          'la comptabilité, comme l’exige la loi.',
      'Your contact details are kept for the order and delivery, then erased '
          'no later than 12 months after. Amounts and items sold, without your '
          'name, are kept for 6 years for accounting, as the law requires.',
    ),
  ),
  (
    Bi('Vos droits', 'Your rights'),
    Bi(
      'Vous pouvez demander à consulter, corriger ou effacer vos '
          'renseignements, ou retirer votre consentement, en écrivant à '
          'yanisgaroui1@gmail.com. Réponse sous 30 jours. Vous pouvez aussi '
          'vous adresser à la Commission d’accès à l’information du Québec '
          '(cai.gouv.qc.ca) ou au Commissariat à la protection de la vie '
          'privée du Canada (priv.gc.ca).',
      'You can ask to see, correct or delete your information, or withdraw '
          'your consent, by writing to yanisgaroui1@gmail.com. Answer within '
          '30 days. You may also contact Quebec’s Commission d’accès à '
          'l’information (cai.gouv.qc.ca) or the Office of the Privacy '
          'Commissioner of Canada (priv.gc.ca).',
    ),
  ),
  (
    Bi('Sécurité', 'Security'),
    Bi(
      'La tablette n’enregistre aucune commande : tout passe par WhatsApp. '
          'Le panneau d’administration est protégé par mot de passe, et les '
          'règles de la base sont testées automatiquement. En cas d’incident '
          'touchant vos renseignements, vous serez avisé.',
      'The tablet stores no order: everything goes through WhatsApp. The '
          'admin panel is password-protected, and the database rules are '
          'tested automatically. If an incident affects your information, you '
          'will be notified.',
    ),
  ),
];

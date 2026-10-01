# Plan de projet — Application tablette pour taxi/rideshare

## Contexte et objectif

Application bilingue (FR/EN) installée sur une tablette Android montée derrière l'appui-tête du conducteur, destinée à divertir et informer les clients pendant la course. Projet personnel de Yanis Garoui (développeur Full Stack .NET/C#, React, en apprentissage actif de Flutter), avec deux objectifs :
1. Offrir une vraie expérience aux clients (divertissement, info, petite boutique)
2. Servir de projet-vitrine couvrant des technologies demandées sur le marché (Flutter, Kubernetes, Docker, Kafka, Semantic Kernel, Azure, CI/CD) pour la recherche d'emploi

---

## Stack technique

- **Frontend tablette :** Flutter (Dart)
- **Dashboard admin :** app web React ou Blazor, hébergée sur Vercel
- **Backend API :** ASP.NET Core Web API (C#)
- **Base de données :** PostgreSQL via Supabase
- **Conteneurisation :** Docker
- **Orchestration :** Kubernetes (apprentissage — commencer avec Minikube en local)
- **Cloud :** Azure (Azure Container Registry + App Service ou AKS)
- **CI/CD :** GitHub Actions (plus simple à démarrer, natif avec GitHub) ou Azure DevOps Pipelines
- **Messagerie asynchrone (optionnel, apprentissage) :** Kafka — événement `OrderCreated` pour les commandes du Store
- **IA :** Semantic Kernel (.NET) orchestrant des appels à l'API OpenAI ou Claude pour un chatbot

---

## Écran d'accueil

- Écran plein écran animé (Rive pour l'interactivité, ou flutter_animate pour les transitions), message "Tap anywhere to continue"
- Choix de langue FR/EN (deux boutons ou drapeaux), fixe la langue pour toute la session
- Librairies suggérées : `flutter_animate`, `rive`, package `IntroViews-Flutter` en référence pour l'onboarding
- Inspiration repo GitHub : `flutterdude/flutter-animation-masterclass` (onboarding "Luxury Car Rental" — thème très proche, staggered animations, courbes de Bézier, transitions Hero)

## Section News

- API gratuite : NewsData.io ou GNews.io (catégories sport, finance, etc., pas de carte de crédit requise)
- Intégration simple via package `http`

## Section "About Me"

- Bio, langues parlées (français, anglais, arabe, kabyle), lien LinkedIn
- QR code généré via package `qr_flutter` (pas besoin d'image externe)
- Carousel de photos de voyage (Lille, Bruxelles, Amsterdam) via `carousel_slider`
- Mention de l'expérience : développeur ERP, professeur à temps partiel, ouvert aux collaborations
- **Sous-section Services/Collaborations :** un bouton qui ouvre une liste animée (style bulles/chips) listant les services offerts en freelance — création de sites web, création d'applications, automatisations — avec un call-to-action pour contacter Yanis (LinkedIn ou WhatsApp déjà prévu ailleurs dans l'app)

## Section Divertissement

- **YouTube** : package `youtube_player_flutter` ou webview avec iframe embed — légal, gratuit, stable
- **Séries personnelles** (contenu possédé légalement, numérisé) : serveur média **Jellyfin** (open-source, gratuit) hébergé sur un NAS/serveur perso, streamé vers l'app via l'API REST de Jellyfin
- Pas de clone Netflix/IPTV piraté — exclu du scope pour raisons légales
- Netflix via WebView avec compte personnel : non recommandé (restrictions DRM/Widevine bloquent la lecture HD dans la plupart des WebViews)

## Section Store (achat/revente)

- Catalogue produits (photo, nom, prix, stock) stocké dans Supabase, servi par l'API .NET
- Paiement : affichage de l'email Interac + montant, confirmation manuelle par Yanis après réception (pas d'intégration Interac automatisée — pas d'API publique pour particuliers)
- Tap-to-pay (Stripe Terminal/Square) : amélioration future, pas dans la V1 (nécessite compte marchand, frais par transaction)
- Contact : bouton WhatsApp (`wa.me/numero`) pour discuter d'une commande

## Question du jour / mini-sondage communautaire

- Question affichée (ex. "Quelle est votre ville préférée ?"), le client répond, réponse stockée dans Supabase
- Affichage des statistiques agrégées en temps réel (classement des réponses précédentes) via `fl_chart` (graphique à barres animé)
- Yanis peut changer la question depuis le dashboard admin sans republier l'app

## Autres fonctionnalités

- Widget météo (OpenWeather API, free tier)
- Mode nuit automatique (luminosité réduite après une certaine heure)
- Bouton feedback rapide en fin de course (étoiles + commentaire optionnel)
- Bouton "Buy Me a Coffee" / Ko-fi pour pourboires discrétionnaires (les courses elles-mêmes sont déjà payées via Uber/Lyft)
- Jeux simples (Sudoku, trivia via Open Trivia DB) — non prioritaire, V2

## Panneau d'administration

- Application web séparée (pas intégrée à l'app tablette, pour des raisons de sécurité), hébergée sur Vercel, sous-domaine gratuit
- Connexion protégée par mot de passe
- Fonctionnalités : gérer les prix/stock du Store, uploader des photos, changer la question du jour, consulter les feedbacks
- Accessible depuis le téléphone de Yanis n'importe où

## Mode kiosque

- Objectif : empêcher un passager de quitter l'app, d'ouvrir les paramètres ou d'installer quelque chose pendant la course
- Android **Lock Task Mode** (épinglage d'écran programmatique, API `startLockTask()`) : désactive la barre de navigation, le bouton retour et l'accès aux paramètres hors de l'app
- Alternative plus simple pour les tests : épinglage d'écran manuel (screen pinning) activable dans les paramètres Android
- Package Flutter à explorer : `kiosk_mode` ou configuration native via `MainActivity.kt`

## Réinitialisation entre passagers

- Problème : sans ça, le passager suivant hérite de la langue, la vidéo en cours ou le panier du passager précédent
- Solution retenue : minuteur d'inactivité (ex. 60-90 secondes sans interaction) qui ramène automatiquement à l'écran d'accueil et réinitialise langue/panier/lecture vidéo
- Complément : bouton discret côté conducteur (zone non visible du passager, ou geste spécifique) pour forcer le retour immédiat à l'accueil entre deux courses

## Connexion internet

- La tablette a besoin d'une connexion data : SIM dédiée (forfait data low-cost) ou partage de connexion (hotspot) depuis le téléphone de Yanis
- Le streaming (Jellyfin, YouTube) peut consommer beaucoup de données mobiles — prévoir :
  - une qualité vidéo plafonnée (ex. 480p/720p max) pour les connexions mobiles
  - du cache local pour le contenu News/météo déjà chargé
  - un état hors ligne propre (message clair plutôt qu'un écran qui plante ou tourne indéfiniment)

## Son

- Décision à prendre tôt : son via haut-parleur de la tablette (avec un plafond de volume raisonnable) ou via écouteurs fournis au passager (filaire ou Bluetooth)
- Contrainte principale : ne jamais distraire le conducteur — pas de son fort ou intempestif qui sort de l'app
- Recommandation V1 : volume plafonné par défaut + bouton mute visible, écouteurs en option V2

## Conformité : règles des plateformes et réglementation locale

- **Règles Uber/Lyft :** vendre des produits (Store) ou promouvoir des services freelance pendant une course rémunérée peut toucher aux conditions d'utilisation des plateformes (sollicitation commerciale pendant un trajet) — à vérifier dans les conditions Uber et Lyft avant le lancement du Store, pour éviter un risque de suspension de compte
- **Réglementation locale (Québec/Canada, à confirmer) :** vérifier s'il existe des règles spécifiques au transport rémunéré de personnes (taxi/covoiturage) concernant l'affichage publicitaire ou la vente à bord

## Protection des données personnelles (Loi 25, Québec)

- Les données collectées par l'app (réponses au sondage du jour, feedback avec commentaire, éventuellement contact si quelqu'un répond au CTA freelance) sont des renseignements personnels au sens de la Loi 25
- Minimum requis : une courte mention de confidentialité dans l'app (quelles données sont collectées, pourquoi, combien de temps conservées, contact pour en savoir plus)
- Bonne pratique : garder la collecte anonyme quand possible (pas de nom/email obligatoire pour répondre au sondage ou laisser un feedback)

## Sécurité (clés et accès API)

- La tablette ne doit **jamais** contenir une clé Supabase privilégiée (`service_role`) — uniquement la clé publique anonyme si Supabase est touché en lecture directe, idéalement même pas ça
- Toutes les écritures (commande Store, réponse au sondage, feedback) passent par l'API .NET, qui détient la clé privilégiée côté serveur — cohérent avec l'objectif vitrine (l'API a une vraie responsabilité de sécurité, pas juste un proxy inutile)
- Le dashboard admin passe aussi par l'API .NET (ou par une clé Supabase distincte, scoped, jamais la même que celle du serveur de prod)

---

## Test en développement (sans tablette physique)

- Téléphone Android personnel connecté en USB (débogage USB activé) + `flutter run` pour hot reload en temps réel
- Alternative : émulateur Android via Android Studio

## Workflow de build/test depuis un iPhone (sans PC)

Contexte : Yanis code principalement via Claude Code depuis son téléphone (iPhone), pas depuis un PC. La cible réelle du projet est une **tablette Android** — le workflow doit donc prioriser Android, pas iOS.

- **Test de la vraie cible (prioritaire) :** Codemagic (CI/CD spécialisé Flutter, gratuit pour usage perso) build un **APK Android** automatiquement à chaque push GitHub → lien d'installation envoyé par Codemagic → téléchargement et installation directe (sideload) sur la tablette ou un téléphone Android de test. Gratuit, sans expiration, pas besoin de compte développeur.
- **Flow :** Claude Code modifie le code → push GitHub → Codemagic détecte le push et build l'APK → lien d'installation envoyé → installation et test sur l'appareil Android
- **Aperçu rapide de l'interface depuis l'iPhone :** build **Flutter Web** déployé automatiquement sur Vercel à chaque push, ouvert dans Safari — gratuit, instantané, pratique pour itérer sur l'UI sans attendre un APK. Certains plugins natifs (lecteur YouTube, accès kiosque, etc.) n'ont pas d'équivalent web ou doivent être désactivés conditionnellement sur cette cible.
- **iOS :** non prioritaire — la tablette cible est Android. Si un test iOS devient utile plus tard, à vérifier : l'installation d'une app iOS signée avec un identifiant Apple gratuit nécessite généralement un outil sur ordinateur (Xcode, AltStore, Sideloadly) ; un lien d'installation envoyé directement sur iPhone sans ordinateur n'est pas garanti avec Codemagic — à confirmer avant de construire quoi que ce soit dessus.

---

## Repos GitHub utiles en référence

Note pour Claude Code : les repos ci-dessous sont des pistes de départ — fais aussi tes propres recherches GitHub pour trouver des packages/repos plus récents ou mieux adaptés à chaque section au moment de l'implémentation (les bibliothèques Flutter évoluent vite).

- `flutterdude/flutter-animation-masterclass` — animations d'onboarding (thème voiture de luxe, très proche du besoin)
- `GetWidget` (pub.dev/GitHub, ~4800 étoiles, MIT) — 1000+ widgets Flutter prêts à l'emploi
- `awesome-flutter` — liste organisée de ressources Flutter par catégorie
- `IntroViews-Flutter` — écrans d'onboarding animés
- `TheChance101/beep-beep` — projet complet (Kotlin) avec app chauffeur + dashboard admin séparé, bonne référence d'architecture globale
- Jellyfin (jellyfin/jellyfin) — serveur média open-source pour le contenu personnel

---

## Scope du MVP

Le projet complet est ambitieux (bonne chose pour la vitrine technique), mais Kubernetes et Kafka doivent rester clairement **après** un MVP qui tourne réellement dans la voiture. MVP réaliste : écran d'accueil + choix de langue, About Me, YouTube, question du jour, feedback, mode kiosque de base. Ça couvre déjà Flutter, l'API .NET, Supabase, Docker et le CI/CD — largement suffisant comme vitrine initiale.

## Prochaines étapes suggérées

1. Setup du projet Flutter + pipeline de build (Codemagic → APK Android) + test hot reload sur téléphone personnel
2. Construire l'écran d'accueil animé + choix de langue
3. Construire les sections statiques (About Me) avant les sections dynamiques (News, Store)
4. Mettre en place l'API .NET + Supabase pour la Question du jour et le feedback (toutes les écritures passent par l'API, jamais directement depuis Flutter)
5. Ajouter le mode kiosque de base (épinglage d'écran) + réinitialisation entre passagers
6. Dockeriser l'API, tester en local
7. Déployer sur Azure, mettre en place le pipeline CI/CD
8. Construire le dashboard admin (Vercel)
9. Construire le Store (après vérification des règles Uber/Lyft) et la section Divertissement (Jellyfin)
10. Explorer Kubernetes et Kafka en apprentissage une fois le MVP fonctionnel

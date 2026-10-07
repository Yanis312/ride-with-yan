# Base en ligne (Supabase, plan gratuit)

Projet : `jwwftxjbswpwtbkluslz` (région Canada). Sert au panneau d'administration.

- `product_overrides` : prix, stock par taille et visibilité de chaque article.
- `settings` : réglages (ex. `poll_question`, la question du jour imposée).
- `poll_votes` : compteurs anonymes de la question du jour.

Tout le monde peut lire. Seul le compte `yanisgaroui1@gmail.com`, une fois son
courriel confirmé, peut écrire (fonction `is_admin()`, règles RLS). La tablette
ajoute un vote uniquement par la fonction `cast_vote()`.

Panneau : ouvrir l'app web avec `?admin` à la fin de l'adresse.
Le schéma est dans `migrations/`.

## Commandes

- `orders` : nom, téléphone, adresse facultative, lignes du panier, montant à
  payer tout de suite (Interac) et à la livraison (articles sur commande).
- La tablette peut seulement **déposer** une commande ; seul le compte admin
  peut les lire, les modifier ou les supprimer.
- À chaque commande, une alerte part vers l'app ntfy de Yanis (nom du client
  et panier, sans téléphone ni adresse). Le nom du canal est dans
  `private.app_secrets`, jamais dans le dépôt.

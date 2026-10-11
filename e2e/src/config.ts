/** Réglages des tests, modifiables par variables d'environnement. */
export const config = {
  /** Adresse de l'app à tester (par défaut : la version construite, servie en local). */
  appUrl: process.env.APP_URL ?? 'http://localhost:8080',

  /**
   * Base Supabase de l'app. L'adresse et la clé "publishable" sont publiques
   * par nature (elles sont dans l'app) : ce sont les règles de la base qui
   * décident qui peut lire et écrire, et c'est justement ce que les tests
   * d'API vérifient.
   */
  supabaseUrl: process.env.SUPABASE_URL ?? 'https://jwwftxjbswpwtbkluslz.supabase.co',
  supabaseKey: process.env.SUPABASE_KEY ?? 'sb_publishable_HQyveAWuMCiS0PLoTFrJmg_Ga6v5rsp',
};

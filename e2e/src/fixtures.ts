import { test as base, expect, type Page, type Request } from '@playwright/test';
import { LoungePage } from './pages/lounge-page.js';
import { StorePage } from './pages/store-page.js';
import { WelcomePage } from './pages/welcome-page.js';

/** Fausse base de données : retient ce que l'app a envoyé pendant un test. */
export class FakeBackend {
  readonly orders: Record<string, unknown>[] = [];
  readonly calls: string[] = [];

  /** Mettre à `true` pour simuler une panne de réseau à l'envoi d'une commande. */
  failOrders = false;

  /** Réglages de produits renvoyés à l'app (prix, stock), vides par défaut. */
  overrides: Record<string, unknown>[] = [];

  async install(page: Page) {
    // Toutes les requêtes vers la base sont interceptées : les tests d'écran
    // n'écrivent jamais dans la vraie base et donnent toujours le même résultat.
    await page.route('**/*.supabase.co/**', async (route) => {
      const request = route.request();
      this.calls.push(`${request.method()} ${new URL(request.url()).pathname}`);
      if (request.method() === 'GET') {
        const body = request.url().includes('/product_overrides') ? this.overrides : [];
        return route.fulfill({ json: body });
      }
      if (isOrder(request)) {
        if (this.failOrders) return route.abort('internetdisconnected');
        this.orders.push(request.postDataJSON() as Record<string, unknown>);
        return route.fulfill({ status: 201, body: '' });
      }
      return route.fulfill({ status: 200, json: null });
    });
    // Météo, nouvelles et vidéos : pas de dépendance à Internet dans ces tests.
    await page.route(/open-meteo\.com|rss2json\.com|radio-canada\.ca|cbc\.ca|youtube/, (route) =>
      route.abort(),
    );
  }
}

function isOrder(request: Request) {
  return request.method() === 'POST' && request.url().includes('/rest/v1/orders');
}

type Fixtures = {
  backend: FakeBackend;
  welcome: WelcomePage;
  lounge: LoungePage;
  store: StorePage;
};

export const test = base.extend<Fixtures>({
  // Automatique : l'interception est en place avant l'ouverture de l'app,
  // même pour un test qui ne regarde pas ce que la base a reçu.
  backend: [
    async ({ page }, use) => {
      const backend = new FakeBackend();
      await backend.install(page);
      await use(backend);
    },
    { auto: true },
  ],
  welcome: async ({ page }, use) => {
    await use(new WelcomePage(page));
  },
  lounge: async ({ page }, use) => {
    await use(new LoungePage(page));
  },
  store: async ({ page }, use) => {
    await use(new StorePage(page));
  },
});

export { expect };

import { expect, test } from '../../src/fixtures.js';

test.describe('Boutique', () => {
  test.beforeEach(async ({ welcome, lounge }) => {
    await welcome.open();
    await welcome.start('en');
    await lounge.openStore();
  });

  test('s’ouvre avec un panier vide et la mention de revendeur', async ({ store }) => {
    await expect(store.emptyCart).toBeVisible();
    await expect(store.resellerNotice).toBeVisible();
    await expect(store.whatsAppButton).toBeVisible();
  });

  test('filtre le catalogue par catégorie', async ({ store }) => {
    await store.showCategory('Essentials');

    await expect(store.products()).toHaveCount(4);
    await expect(store.product('3-in-1 charging cable')).toHaveAccessibleName(/\$12$/);
    await expect(store.product('Spring water')).toHaveAccessibleName(/\$2$/);
  });

  test('propose les maillots sur commande quand il n’y en a pas en stock', async ({ store }) => {
    await store.showCategory('Jerseys');

    await expect(store.products()).toHaveCount(4);
    await expect(store.products().first()).toHaveAccessibleName(/On order.*\$50$/);
  });

  test('ajoute un article au panier et calcule le total', async ({ page, store }) => {
    await store.showCategory('Essentials');
    await store.addToCart('3-in-1 charging cable');
    await store.addToCart('Spring water');

    await expect(store.cartLine('3-in-1 charging cable')).toBeVisible();
    await expect(store.cartLine('Spring water')).toBeVisible();
    await expect(page.getByText('$14', { exact: true })).toBeVisible();
    await expect(store.emptyCart).toBeHidden();
  });

  test('annonce le paiement Interac avant de demander les coordonnées', async ({ store }) => {
    await store.showCategory('Essentials');
    await store.addToCart('Spring water');

    await expect(store.nextStepHint).toContainText('payment by Interac e-Transfer');
  });

  test('applique un prix modifié depuis le panneau d’administration', async ({
    page,
    backend,
    welcome,
    lounge,
    store,
  }) => {
    backend.overrides = [{ id: 'water', price: 3, sizes: null, stock: 7, hidden: false }];
    await page.reload();
    await welcome.startButton.waitFor({ timeout: 45_000 });
    await welcome.start('en');
    await lounge.openStore();
    await store.showCategory('Essentials');

    await expect(store.product('Spring water')).toHaveAccessibleName(/^7 in stock.*\$3$/);
  });
});

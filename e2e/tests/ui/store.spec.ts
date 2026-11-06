import { expect, test } from '../../src/fixtures.js';

test.describe('Boutique', () => {
  test.beforeEach(async ({ welcome, lounge }) => {
    await welcome.open();
    await welcome.start('en');
    await lounge.openStore();
  });

  test('s’ouvre avec un panier vide, les prix et la mention de revendeur', async ({ store }) => {
    await expect(store.emptyCart).toBeVisible();
    await expect(store.pitch).toContainText('Everything $80');
    await expect(store.pitch).toContainText('20 to 30 days');
    await expect(store.resellerNotice).toBeVisible();
    await expect(store.whatsAppButton).toBeVisible();
  });

  test('propose deux rayons, hommes et femmes, ouverts sur les hommes', async ({ store }) => {
    await expect(store.shopper('Men')).toBeVisible();
    await expect(store.shopper('Women')).toBeVisible();
    await expect(store.product('Blue patent')).toBeVisible();
    await expect(store.product('Candy pink')).toHaveCount(0);
  });

  test('le rayon femmes montre le rose, pas le bleu', async ({ store }) => {
    await store.showShopper('Women');

    await expect(store.product('Pink and burgundy patent')).toBeVisible();
    await expect(store.product('Blue patent')).toHaveCount(0);
    // Le blanc et les doudounes sont dans les deux rayons.
    await store.showCategory('The North Face');
    await expect(store.product('Black puffer')).toBeVisible();
  });

  test('range les articles par modèle, sans maillots', async ({ page, store }) => {
    for (const category of ['Air Force 1', 'Dunk', 'Vans', 'The North Face'] as const) {
      await expect(store.category(category)).toBeVisible();
    }
    await expect(page.getByRole('button', { name: 'Jerseys' })).toHaveCount(0);
  });

  test('les Air Force 1 sont sur commande à 80 $', async ({ store }) => {
    await store.showCategory('Air Force 1');

    await expect(store.product('All white')).toHaveAccessibleName(/On order.*\$80$/);
    await expect(store.product('All black')).toHaveAccessibleName(/On order.*\$80$/);
    await expect(store.products().filter({ hasText: /in stock/ })).toHaveCount(0);
  });

  test('les Dunk et les Vans ont chacune leur section', async ({ store }) => {
    await store.showCategory('Dunk');
    await expect(store.product('Sky blue and white')).toBeVisible();
    await expect(store.product('All white')).toHaveCount(0);

    await store.showCategory('Vans');
    await expect(store.product('White, studded')).toBeVisible();
  });

  test('les doudounes The North Face sont sur commande à 80 $', async ({ store }) => {
    await store.showCategory('The North Face');

    await expect(store.product('Black puffer')).toHaveAccessibleName(/On order.*\$80$/);
    await expect(store.product('All white')).toHaveCount(0);
  });

  test('une paire : 40 $ d’acompte, 40 $ à la livraison', async ({ store }) => {
    await store.showCategory('Air Force 1');
    await store.addSized('All white', 'US 9');

    await expect(store.cartLine('All white')).toBeVisible();
    await expect(store.amount('$80')).toBeVisible();
    await expect(store.depositLine).toBeVisible();
    await expect(store.onDelivery).toBeVisible();
    await expect(store.amount('$40')).toHaveCount(2);
  });

  test('applique un prix modifié depuis le panneau d’administration', async ({
    page,
    backend,
    welcome,
    lounge,
    store,
  }) => {
    backend.overrides = [
      { id: 'doudoune-jaune', price: 99, sizes: null, stock: null, hidden: false },
    ];
    await page.reload();
    await welcome.startButton.waitFor({ timeout: 45_000 });
    await welcome.start('en');
    await lounge.openStore();
    await store.showCategory('The North Face');

    await expect(store.product('Yellow puffer')).toHaveAccessibleName(/\$99$/);
    await expect(store.product('Orange puffer')).toHaveAccessibleName(/\$80$/);
  });
});

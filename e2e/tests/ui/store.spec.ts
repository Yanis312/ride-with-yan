import { expect, test } from '../../src/fixtures.js';

test.describe('Boutique', () => {
  test.beforeEach(async ({ welcome, lounge }) => {
    await welcome.open();
    await welcome.start('en');
    await lounge.openStore();
  });

  test('s’ouvre avec un panier vide, les prix et la mention de revendeur', async ({ store }) => {
    await expect(store.emptyCart).toBeVisible();
    await expect(store.pitch).toContainText('Shoes $100 · Jerseys $50');
    await expect(store.pitch).toContainText('combo $140');
    await expect(store.pitch).toContainText('30 days');
    await expect(store.resellerNotice).toBeVisible();
    await expect(store.whatsAppButton).toBeVisible();
  });

  test('ne propose que des chaussures et des maillots', async ({ page, store }) => {
    await expect(store.category('Shoes')).toBeVisible();
    await expect(store.category('Jerseys')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Essentials' })).toHaveCount(0);
  });

  test('toutes les chaussures sont sur commande à 100 $', async ({ store }) => {
    await store.showCategory('Shoes');

    await expect(store.product('All white')).toHaveAccessibleName(/On order.*\$100$/);
    await expect(store.product('All black')).toHaveAccessibleName(/On order.*\$100$/);
    await expect(store.products().filter({ hasText: /in stock/ })).toHaveCount(0);
  });

  test('tous les maillots sont sur commande à 50 $', async ({ store }) => {
    await store.showCategory('Jerseys');

    await expect(store.products()).toHaveCount(4);
    for (const player of ['Yamal', 'Olise', 'Mbappé', 'Bellingham']) {
      await expect(store.product(`${player} jersey`)).toHaveAccessibleName(/On order.*\$50$/);
    }
  });

  test('une paire seule se paie 100 $ à la livraison', async ({ store }) => {
    await store.showCategory('Shoes');
    await store.addSized('All white', 'US 9');

    await expect(store.cartLine('All white')).toBeVisible();
    await expect(store.onDelivery).toBeVisible();
    await expect(store.amount('$100')).toBeVisible();
    await expect(store.comboLine).toBeHidden();
    await expect(store.nextStepHint).toContainText('You pay on delivery');
  });

  test('une paire avec un maillot revient à 140 $ (combo)', async ({ store }) => {
    await store.showCategory('Shoes');
    await store.addSized('All white', 'US 9');
    await store.showCategory('Jerseys');
    await store.addSized('Yamal jersey', 'M');

    await expect(store.comboLine).toBeVisible();
    await expect(store.amount('− $10')).toBeVisible();
    await expect(store.amount('$140')).toBeVisible();
  });

  test('applique un prix modifié depuis le panneau d’administration', async ({
    page,
    backend,
    welcome,
    lounge,
    store,
  }) => {
    backend.overrides = [
      { id: 'maillot-yamal', price: 45, sizes: null, stock: null, hidden: false },
    ];
    await page.reload();
    await welcome.startButton.waitFor({ timeout: 45_000 });
    await welcome.start('en');
    await lounge.openStore();
    await store.showCategory('Jerseys');

    await expect(store.product('Yamal jersey')).toHaveAccessibleName(/\$45$/);
    await expect(store.product('Olise jersey')).toHaveAccessibleName(/\$50$/);
  });
});

import { expect, test } from '../../src/fixtures.js';

// La commande se termine sur WhatsApp : la tablette montre un code QR avec
// la commande déjà écrite et trois étapes courtes, et n'enregistre rien.
test.describe('Commande sur WhatsApp', () => {
  test.beforeEach(async ({ welcome, lounge }) => {
    await welcome.open();
    await welcome.start('en');
    await lounge.openStore();
  });

  test('montre trois étapes et l’acompte de 50 %', async ({ page, store, backend }) => {
    await store.showCategory('The North Face');
    await store.addSized('Black puffer', 'M');
    await store.order();

    await expect(store.step('Scan the code')).toBeVisible();
    await expect(store.step('Add your address and send')).toBeVisible();
    await expect(store.step('Pay $40 by Interac, the rest on delivery')).toBeVisible();
    await expect(page.getByText('WhatsApp', { exact: true })).toBeVisible();

    // Aucune commande n'est écrite dans la base depuis la tablette.
    expect(backend.orders).toHaveLength(0);
  });

  test('l’acompte suit le total du panier', async ({ store }) => {
    await store.showCategory('Air Force 1');
    await store.addSized('All black', 'US 10');
    await store.showCategory('The North Face');
    await store.addSized('Orange puffer', 'L');
    await store.order();

    await expect(store.step('Pay $80 by Interac, the rest on delivery')).toBeVisible();
  });

  test('se ferme et garde le panier', async ({ page, store }) => {
    await store.showCategory('Air Force 1');
    await store.addSized('All white', 'US 9');
    await store.order();
    await page.getByRole('button', { name: 'Close' }).last().click();

    await expect(store.orderSheetTitle).toBeHidden();
    await expect(store.cartLine('All white')).toBeVisible();
  });
});

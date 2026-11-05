import { expect, test } from '../../src/fixtures.js';

// La commande se termine sur WhatsApp : la tablette montre un code QR avec
// la commande déjà écrite, et n'enregistre rien elle-même.
test.describe('Commande sur WhatsApp', () => {
  test.beforeEach(async ({ welcome, lounge }) => {
    await welcome.open();
    await welcome.start('en');
    await lounge.openStore();
  });

  test('ouvre le code QR avec l’acompte de 50 % et le reste à la livraison', async ({
    page,
    store,
    backend,
  }) => {
    await store.showCategory('Puffer jackets');
    await store.addSized('Black puffer', 'M');
    await store.order();

    await expect(store.orderSheetBody).toContainText('50% Interac deposit ($60)');
    await expect(store.orderSheetBody).toContainText('The rest ($60) is paid on delivery');
    await expect(store.orderSheetBody).toContainText('Not satisfied: I refund you');
    await expect(page.getByText('WhatsApp', { exact: true })).toBeVisible();

    // Aucune commande n'est écrite dans la base depuis la tablette.
    expect(backend.orders).toHaveLength(0);
  });

  test('le combo paire + maillot se commande à 120 $', async ({ store }) => {
    await store.showCategory('Shoes');
    await store.addSized('All black', 'US 10');
    await store.showCategory('Jerseys');
    await store.addSized('Mbappé jersey', 'L');
    await store.order();

    await expect(store.orderSheetBody).toContainText('($60)');
  });

  test('se ferme et garde le panier', async ({ page, store }) => {
    await store.showCategory('Shoes');
    await store.addSized('All white', 'US 9');
    await store.order();
    await page.getByRole('button', { name: 'Close' }).last().click();

    await expect(store.orderSheetTitle).toBeHidden();
    await expect(store.cartLine('All white')).toBeVisible();
  });
});

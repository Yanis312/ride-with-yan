import { expect, test } from '../../src/fixtures.js';
import { orderSchema } from '../../src/api/schemas.js';

const passenger = { name: 'Test Passager', phone: '514 555 0199' };

test.describe('Commande et paiement Interac', () => {
  test.beforeEach(async ({ welcome, lounge, store }) => {
    await welcome.open();
    await welcome.start('en');
    await lounge.openStore();
    await store.showCategory('Essentials');
    await store.addToCart('3-in-1 charging cable');
    await store.goToDetails();
  });

  test('refuse une commande sans nom ni téléphone', async ({ store, backend }) => {
    await store.confirm();

    await expect(store.nameError).toBeVisible();
    await expect(store.phoneError).toBeVisible();
    expect(backend.orders).toHaveLength(0);
  });

  test('refuse un numéro de téléphone trop court', async ({ store, backend }) => {
    await store.fillDetails({ name: passenger.name, phone: '514 555' });
    await store.confirm();

    await expect(store.phoneError).toBeVisible();
    await expect(store.nameError).toBeHidden();
    expect(backend.orders).toHaveLength(0);
  });

  test('envoie la commande puis affiche le paiement Interac', async ({ page, store, backend }) => {
    await store.fillDetails(passenger);
    await store.confirm();

    // L'écran de paiement : montant, adresse courriel et code à recopier.
    await expect(store.interacTitle).toBeVisible();
    await expect(store.interacAmount).toContainText('$12');
    await expect(store.reference).toBeVisible();
    await expect(store.transferSentButton).toBeVisible();

    // Ce que la base a reçu : une seule commande, complète et bien formée.
    expect(backend.orders).toHaveLength(1);
    const order = orderSchema.parse(backend.orders[0]);
    expect(order).toMatchObject({
      name: passenger.name,
      phone: passenger.phone,
      address: null,
      language: 'en',
      pay_now: 12,
      pay_later: 0,
    });
    expect(order.lines).toEqual([
      expect.objectContaining({ id: 'charger', qty: 1, price: 12, on_order: false }),
    ]);
    // Le code affiché au client est bien celui enregistré avec la commande.
    await expect(page.getByText(order.reference, { exact: true })).toBeVisible();
  });

  test('remercie le client après « Virement envoyé »', async ({ page, store, backend }) => {
    await store.fillDetails(passenger);
    await store.confirm();
    await store.transferSentButton.click();

    await expect(page.getByText(/^Thank you!/)).toBeVisible();
    await expect(page.getByRole('button', { name: 'New order' })).toBeVisible();
    expect(backend.calls).toContain('POST /rest/v1/rpc/claim_transfer');
  });

  test('garde les coordonnées et prévient quand le réseau tombe', async ({ store, backend }) => {
    backend.failOrders = true;
    await store.fillDetails(passenger);
    await store.confirm();

    await expect(store.networkError).toBeVisible();
    await expect(store.interacTitle).toBeHidden();
    await expect(store.nameField).toHaveValue(passenger.name);

    // Le réseau revient : la même commande passe au deuxième essai.
    backend.failOrders = false;
    await store.confirm();

    await expect(store.interacTitle).toBeVisible();
    expect(backend.orders).toHaveLength(1);
  });
});

test.describe('Article sur commande', () => {
  test('demande l’adresse et saute le paiement Interac', async ({
    page,
    welcome,
    lounge,
    store,
    backend,
  }) => {
    await welcome.open();
    await welcome.start('en');
    await lounge.openStore();
    await store.showCategory('Jerseys');
    await store.products().first().getByRole('button', { name: 'View' }).click();
    await page.getByRole('button', { name: 'M', exact: true }).click();
    await page.getByRole('button', { name: /^Order · \$50/ }).click();

    await expect(store.nextStepHint).toContainText('You pay on delivery');
    await store.goToDetails();
    await store.fillDetails(passenger);
    await store.confirm();

    // Sans adresse, impossible de livrer : la commande n'est pas envoyée.
    await expect(page.getByText('Needed to deliver to you')).toBeVisible();
    expect(backend.orders).toHaveLength(0);

    await store.fillDetails({ address: '1234 rue Sainte-Catherine, Montreal' });
    await store.confirm();

    await expect(page.getByText(/^Order received!/)).toBeVisible();
    await expect(store.interacTitle).toBeHidden();
    const order = orderSchema.parse(backend.orders[0]);
    expect(order).toMatchObject({ pay_now: 0, pay_later: 50 });
    expect(order.lines[0]).toMatchObject({ size: 'M', on_order: true });
  });
});

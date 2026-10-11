import { expect, test } from '../../src/fixtures.js';
import { orderSchema } from '../../src/api/schemas.js';

const passenger = { name: 'Test Passager', phone: '514 555 0199' };
const address = '1234 rue Sainte-Catherine, Montreal';

test.describe('Commande livrée à domicile', () => {
  test.beforeEach(async ({ welcome, lounge, store }) => {
    await welcome.open();
    await welcome.start('en');
    await lounge.openStore();
    await store.showCategory('Jerseys');
    await store.addSized('Yamal jersey', 'M');
    await store.goToDetails();
  });

  test('refuse une commande sans nom, téléphone ni adresse', async ({ store, backend }) => {
    await store.confirm();

    await expect(store.nameError).toBeVisible();
    await expect(store.phoneError).toBeVisible();
    await expect(store.addressError).toBeVisible();
    expect(backend.orders).toHaveLength(0);
  });

  test('refuse un numéro de téléphone trop court', async ({ store, backend }) => {
    await store.fillDetails({ name: passenger.name, phone: '514 555', address });
    await store.confirm();

    await expect(store.phoneError).toBeVisible();
    await expect(store.nameError).toBeHidden();
    expect(backend.orders).toHaveLength(0);
  });

  test('envoie la commande, à payer à la livraison, sans écran Interac', async ({
    store,
    backend,
  }) => {
    await store.fillDetails({ ...passenger, address });
    await store.confirm();

    await expect(store.orderReceived).toBeVisible();
    await expect(store.interacTitle).toBeHidden();

    // Ce que la base a reçu : une seule commande, complète et bien formée.
    expect(backend.orders).toHaveLength(1);
    const order = orderSchema.parse(backend.orders[0]);
    expect(order).toMatchObject({
      name: passenger.name,
      phone: passenger.phone,
      address,
      language: 'en',
      pay_now: 0,
      pay_later: 50,
    });
    expect(order.lines).toEqual([
      expect.objectContaining({ id: 'maillot-yamal', size: 'M', qty: 1, on_order: true }),
    ]);
  });

  test('garde les coordonnées et prévient quand le réseau tombe', async ({ store, backend }) => {
    backend.failOrders = true;
    await store.fillDetails({ ...passenger, address });
    await store.confirm();

    await expect(store.networkError).toBeVisible();
    await expect(store.orderReceived).toBeHidden();
    await expect(store.nameField).toHaveValue(passenger.name);

    // Le réseau revient : la même commande passe au deuxième essai.
    backend.failOrders = false;
    await store.confirm();

    await expect(store.orderReceived).toBeVisible();
    expect(backend.orders).toHaveLength(1);
  });
});

test.describe('Combo paire + maillot', () => {
  test('la commande enregistrée vaut 140 $', async ({ welcome, lounge, store, backend }) => {
    await welcome.open();
    await welcome.start('en');
    await lounge.openStore();
    await store.showCategory('Shoes');
    await store.addSized('All black', 'US 10');
    await store.showCategory('Jerseys');
    await store.addSized('Mbappé jersey', 'L');
    await store.goToDetails();
    await store.fillDetails({ ...passenger, address });
    await store.confirm();

    await expect(store.orderReceived).toBeVisible();
    const order = orderSchema.parse(backend.orders[0]);
    expect(order.lines).toHaveLength(2);
    expect(order).toMatchObject({ pay_now: 0, pay_later: 140 });
  });
});

// Quand Yanis saisit du stock dans le panneau d'administration, l'article se
// paie tout de suite par virement Interac.
test.describe('Article en stock : paiement Interac', () => {
  test.beforeEach(async ({ backend, welcome, lounge, store }) => {
    backend.overrides = [
      { id: 'chaussures-noir', price: null, sizes: { 'US 9': 2 }, stock: null, hidden: false },
    ];
    await welcome.open();
    await welcome.start('en');
    await lounge.openStore();
    await store.showCategory('Shoes');
    await store.addSized('All black', 'US 9');
  });

  test('annonce le paiement Interac dès le panier', async ({ store }) => {
    await expect(store.nextStepHint).toContainText('payment by Interac e-Transfer');
  });

  test('affiche le montant et le code du virement', async ({ page, store, backend }) => {
    await store.goToDetails();
    await store.fillDetails(passenger);
    await store.confirm();

    await expect(store.interacTitle).toBeVisible();
    await expect(store.interacAmount).toContainText('$100');
    await expect(store.transferSentButton).toBeVisible();

    const order = orderSchema.parse(backend.orders[0]);
    expect(order).toMatchObject({ address: null, pay_now: 100, pay_later: 0 });
    expect(order.lines[0]).toMatchObject({ id: 'chaussures-noir', size: 'US 9', on_order: false });
    // Le code affiché au client est bien celui enregistré avec la commande.
    await expect(page.getByText(order.reference, { exact: true })).toBeVisible();
  });

  test('remercie le client après « Virement envoyé »', async ({ page, store, backend }) => {
    await store.goToDetails();
    await store.fillDetails(passenger);
    await store.confirm();
    await store.transferSentButton.click();

    await expect(page.getByText(/^Thank you!/)).toBeVisible();
    await expect(page.getByRole('button', { name: 'New order' })).toBeVisible();
    expect(backend.calls).toContain('POST /rest/v1/rpc/claim_transfer');
  });
});

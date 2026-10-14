import { expect, test } from '../../src/fixtures.js';

test.describe('Confidentialité', () => {
  test.beforeEach(async ({ welcome, lounge }) => {
    await welcome.open();
    await welcome.start('en');
    await lounge.openStore();
  });

  test('la politique est accessible depuis la boutique', async ({ page }) => {
    await page.getByRole('button', { name: /Privacy and your information/ }).first().click();

    await expect(page.getByText('Privacy', { exact: true })).toBeVisible();
    await expect(page.getByText('Person in charge')).toBeVisible();
    await expect(page.getByText(/Office of the Privacy Commissioner of Canada/)).toBeVisible();
  });

  test('le formulaire de commande renvoie aussi à la politique', async ({ page, store }) => {
    await store.showCategory('Jerseys');
    await store.addSized('Yamal jersey', 'M');
    await store.goToDetails();

    await expect(page.getByRole('button', { name: /Privacy and your information/ })).toHaveCount(2);
  });
});

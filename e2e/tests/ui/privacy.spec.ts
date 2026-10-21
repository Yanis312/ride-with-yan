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

    // La politique est longue : on la fait défiler jusqu'à chaque section,
    // quelle que soit la hauteur de l'écran ou la vitesse de la machine.
    for (const section of [
      page.getByText('The assistant', { exact: true }),
      page.getByText(/Office of the Privacy Commissioner of Canada/),
    ]) {
      await expect(async () => {
        if (!(await section.isVisible())) {
          await page.mouse.move(640, 450);
          await page.mouse.wheel(0, 300);
        }
        await expect(section).toBeVisible({ timeout: 1500 });
      }).toPass({ timeout: 60_000 });
    }
  });

  test('le formulaire de commande renvoie aussi à la politique', async ({ page, store }) => {
    await store.showCategory('Jerseys');
    await store.addSized('Yamal jersey', 'M');
    await store.goToDetails();

    await expect(page.getByRole('button', { name: /Privacy and your information/ })).toHaveCount(2);
  });
});

import { expect, test } from '../../src/fixtures.js';

test.describe('Écran de veille', () => {
  test.beforeEach(async ({ welcome }) => {
    await welcome.open();
  });

  test('fait défiler ses dix présentations et invite à commencer', async ({ welcome }) => {
    await expect(welcome.slide).toHaveAccessibleName(/Ride with Yan \d{2} \/ 10/);
    await expect(welcome.startButton).toBeVisible();
    await expect(welcome.discoverButton).toBeVisible();
  });

  test('montre les raccourcis qui rapportent : boutique, services, publicité', async ({
    welcome,
  }) => {
    for (const name of ['Music', 'LinkedIn', 'Collaborations', 'My store', 'Advertise']) {
      await expect(welcome.shortcut(name)).toBeVisible();
    }
  });

  test('demande la langue avant d’ouvrir le lounge', async ({ welcome }) => {
    await welcome.startButton.click();

    await expect(welcome.frenchChoice).toBeVisible();
    await expect(welcome.englishChoice).toBeVisible();
  });

  test('ouvre le lounge en anglais', async ({ welcome, lounge }) => {
    await welcome.start('en');

    await expect(lounge.backToWelcome).toBeVisible();
    await expect(lounge.servicesTile).toBeVisible();
    await expect(lounge.videosTile).toBeVisible();
    await expect(lounge.pollTile).toContainText('QUESTION OF THE DAY');
  });

  test('ouvre le lounge en français', async ({ welcome, lounge }) => {
    await welcome.start('fr');

    await expect(lounge.pollTile).toContainText('QUESTION DU JOUR');
  });

  test('revient à l’écran de veille depuis le lounge', async ({ welcome, lounge }) => {
    await welcome.start('en');
    await lounge.returnToWelcome();

    await expect(welcome.startButton).toBeVisible();
  });
});

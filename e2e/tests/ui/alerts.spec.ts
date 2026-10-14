import { expect, test } from '../../src/fixtures.js';

const stormWarning = {
  alert_code: 'WS',
  alert_type: 'warning',
  alert_name_fr: 'avertissement de tempête hivernale',
  alert_name_en: 'winter storm warning',
  alert_text_fr: 'Quoi : de 25 à 35 cm de neige.\n\nQuand : demain',
  alert_text_en: 'What: 25 to 35 cm of snow.\n\nWhen: tomorrow',
  status_en: 'issued',
  expiration_datetime: '2099-01-01T00:00:00Z',
};

test.describe('Alertes pour les passagers', () => {
  test('aucun bandeau quand il n’y a rien à signaler', async ({ page, welcome }) => {
    await welcome.open();
    await welcome.start('en');

    await expect(page.getByRole('button', { name: /Back to welcome/ })).toBeVisible();
    await expect(page.getByRole('button', { name: /warning|message|driver/i })).toHaveCount(0);
  });

  test('affiche l’alerte officielle d’Environnement Canada', async ({
    page,
    backend,
    welcome,
  }) => {
    backend.weatherAlerts = [stormWarning];
    await welcome.open();
    await welcome.start('en');

    const banner = page.getByRole('button', { name: /^Winter storm warning\./ });
    await expect(banner).toHaveAccessibleName(/25 to 35 cm of snow\. — tomorrow/);

    // Toucher le bandeau montre le détail et la source.
    await banner.click();
    await expect(page.getByText('Good to know today')).toBeVisible();
    await expect(page.getByText('Environment Canada')).toBeVisible();
  });

  test('l’alerte s’affiche en français pour un passager francophone', async ({
    page,
    backend,
    welcome,
  }) => {
    backend.weatherAlerts = [stormWarning];
    await welcome.open();
    await welcome.start('fr');

    await expect(
      page.getByRole('button', { name: /^Avertissement de tempête hivernale\./ }),
    ).toBeVisible();
  });
});

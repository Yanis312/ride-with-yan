import { expect, test } from '../../src/fixtures.js';

const concert = {
  id: '2099-11-20-concert',
  title_fr: 'Grand concert',
  title_en: 'Big concert',
  venue: 'Centre Bronson',
  city: 'Ottawa',
  starts_at: '2099-11-20T20:00:00-05:00',
  link: 'https://exemple.ca/billets',
  photo_url: null,
  active: true,
};

test.describe('Sorties à Ottawa et à Gatineau', () => {
  test('propose une activité à venir et son code QR', async ({
    page,
    backend,
    welcome,
    lounge,
  }) => {
    backend.activities = [concert];
    await welcome.open();
    await welcome.start('fr');

    await lounge.activitiesTile.click();
    await page.getByRole('button', { name: /Grand concert.*Centre Bronson, Ottawa/ }).click();

    await expect(page.getByRole('img', { name: 'Code QR : Grand concert' })).toBeVisible();
  });

  test('n’affiche jamais une activité hors de la région', async ({
    page,
    backend,
    welcome,
    lounge,
  }) => {
    backend.activities = [{ ...concert, title_fr: 'Concert à Montréal', city: 'Montréal' }];
    await welcome.open();
    await welcome.start('fr');

    await lounge.activitiesTile.click();

    await expect(page.getByText('Aucune activité à venir pour le moment.')).toBeVisible();
    await expect(page.getByText('Concert à Montréal')).toBeHidden();
  });
});

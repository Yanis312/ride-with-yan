import { expect, test } from '../../src/fixtures.js';

test('une course est mesurée sans aucune donnée personnelle', async ({
  page,
  backend,
  welcome,
  lounge,
}) => {
  await welcome.open();
  await welcome.start('fr');
  await lounge.shortcut('Ma boutique').click();
  await expect(page.getByRole('button', { name: 'Maillots', exact: true })).toBeVisible();

  // Les évènements partent groupés, toutes les 20 secondes.
  await expect
    .poll(() => backend.usage.map((e) => `${e.kind}:${e.name}`), { timeout: 40_000 })
    .toEqual(expect.arrayContaining(['session_start:lounge', 'screen:store']));

  // Un seul numéro de passager, tiré au hasard, et rien d'autre sur lui.
  expect(new Set(backend.usage.map((e) => e.session_id)).size).toBe(1);
  for (const event of backend.usage) {
    expect(Object.keys(event).sort()).toEqual(['kind', 'language', 'name', 'session_id', 'value']);
    expect(event.language).toBe('fr');
  }
});

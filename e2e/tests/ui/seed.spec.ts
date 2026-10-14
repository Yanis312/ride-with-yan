import { expect, test } from '../../src/fixtures.js';

// Point de départ des agents IA de Playwright (planner, generator, healer) :
// l'app est ouverte, la base est simulée, rien n'est écrit dans la vraie base.
// Les agents partent de cet état pour explorer l'app et écrire leurs tests.
test.describe('Graine des agents', () => {
  test('seed', async ({ page, welcome }) => {
    await welcome.open();
    await expect(page.getByRole('button', { name: /Tap to start/ })).toBeVisible();
  });
});

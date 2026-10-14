import { AxeBuilder } from '@axe-core/playwright';
import type { Page } from '@playwright/test';
import { expect, test } from '../../src/fixtures.js';

/**
 * Vérifie les règles d'accessibilité WCAG 2 (niveaux A et AA) avec axe-core.
 * Seules les erreurs graves bloquent : un bouton sans nom, une image sans
 * description, un champ sans étiquette… ce qu'un lecteur d'écran ne peut
 * pas annoncer.
 */
async function seriousViolations(page: Page) {
  const report = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa'])
    // Les zones qui défilent sont créées par le moteur web de Flutter, pas par
    // l'app : impossible de les rendre accessibles au clavier depuis le code.
    // La tablette, elle, se pilote au doigt.
    .disableRules(['scrollable-region-focusable'])
    .analyze();
  return report.violations
    .filter((v) => v.impact === 'serious' || v.impact === 'critical')
    .map((v) => `${v.id} : ${v.help} (${v.nodes.length})`);
}

test.describe('Accessibilité', () => {
  test('écran de veille', async ({ page, welcome }) => {
    await welcome.open();

    expect(await seriousViolations(page)).toEqual([]);
  });

  test('lounge', async ({ page, welcome, lounge }) => {
    await welcome.open();
    await welcome.start('en');
    await expect(lounge.backToWelcome).toBeVisible();

    expect(await seriousViolations(page)).toEqual([]);
  });

  test('boutique et formulaire de commande', async ({ page, welcome, lounge, store }) => {
    await welcome.open();
    await welcome.start('en');
    await lounge.openStore();
    await expect(store.emptyCart).toBeVisible();
    expect(await seriousViolations(page)).toEqual([]);

    await store.showCategory('Jerseys');
    await store.addSized('Yamal jersey', 'M');
    await store.goToDetails();
    expect(await seriousViolations(page)).toEqual([]);
  });
});

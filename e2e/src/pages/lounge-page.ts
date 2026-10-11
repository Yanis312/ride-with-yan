import { expect, type Locator, type Page } from '@playwright/test';

/** Accueil du passager : les cartes vers chaque section. */
export class LoungePage {
  readonly backToWelcome: Locator;
  readonly servicesTile: Locator;
  readonly videosTile: Locator;
  readonly pollTile: Locator;
  readonly newsTile: Locator;
  readonly weatherTile: Locator;

  constructor(private readonly page: Page) {
    this.backToWelcome = page.getByRole('button', { name: /Back to welcome|Retour/ });
    this.servicesTile = page.getByRole('button', { name: /Services & collaborations/ });
    this.videosTile = page.getByRole('button', { name: /YouTube/ });
    this.pollTile = page.getByRole('button', { name: /QUESTION OF THE DAY|QUESTION DU JOUR/ });
    this.newsTile = page.getByRole('button', { name: /^(News|Nouvelles|Actualités)/ });
    this.weatherTile = page.getByRole('button', { name: /Weather|Météo/ });
  }

  /** Raccourci du haut de l'écran (Music, My store…). */
  shortcut(name: string) {
    return this.page.getByRole('button', { name, exact: true }).first();
  }

  /** Geste discret du conducteur entre deux courses : appui long sur le logo. */
  async returnToWelcome() {
    // L'appui est répété tant que le lounge est affiché : sur une machine
    // lente, un premier appui long peut ne pas être reconnu.
    await expect(async () => {
      await this.backToWelcome.click({ delay: 1500, timeout: 5000 });
      await expect(this.backToWelcome).toBeHidden({ timeout: 5000 });
    }).toPass();
  }

  async openStore() {
    await this.shortcut('My store').click();
  }
}

import type { Locator, Page } from '@playwright/test';

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
    await this.backToWelcome.click({ delay: 1500 });
  }

  async openStore() {
    await this.shortcut('My store').click();
  }
}

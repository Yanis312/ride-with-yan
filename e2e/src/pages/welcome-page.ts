import type { Locator, Page } from '@playwright/test';

export type Language = 'en' | 'fr';

/** Écran de veille : ce que le passager voit en montant dans la voiture. */
export class WelcomePage {
  readonly startButton: Locator;
  /** Présentation en cours (l'écran en fait défiler dix). */
  readonly slide: Locator;
  readonly discoverButton: Locator;
  readonly frenchChoice: Locator;
  readonly englishChoice: Locator;

  constructor(private readonly page: Page) {
    this.startButton = page.getByRole('button', { name: /Tap to start/ });
    this.slide = page.getByRole('group', { name: /^Ride with Yan/ });
    this.discoverButton = page.getByRole('button', { name: /Discover this app/ });
    this.frenchChoice = page.getByRole('button', { name: /^Français\s+FR/ });
    this.englishChoice = page.getByRole('button', { name: /^English\s+EN/ });
  }

  /** `?e2e` demande à l'app d'exposer ses boutons et ses textes aux tests. */
  async open() {
    await this.page.goto('./?e2e');
    await this.startButton.waitFor({ timeout: 45_000 });
  }

  shortcut(name: string) {
    return this.page.getByRole('button', { name, exact: true });
  }

  async start(language: Language = 'en') {
    // « Tap to start » laisse sa place à « Shop now » pendant les 15 s de la
    // vitrine : sur une machine lente, ce clic peut donc attendre un moment.
    await this.startButton.click();
    await (language === 'fr' ? this.frenchChoice : this.englishChoice).click();
  }
}

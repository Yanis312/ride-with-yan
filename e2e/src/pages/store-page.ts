import type { Locator, Page } from '@playwright/test';

export type Category = 'All' | 'Shoes' | 'Jerseys' | 'Essentials';

/** Boutique : catalogue, panier, coordonnées, paiement Interac. */
export class StorePage {
  readonly emptyCart: Locator;
  readonly orderButton: Locator;
  readonly nextStepHint: Locator;
  readonly whatsAppButton: Locator;
  readonly resellerNotice: Locator;

  // Coordonnées du client
  readonly detailsTitle: Locator;
  readonly nameField: Locator;
  readonly phoneField: Locator;
  readonly addressField: Locator;
  readonly confirmButton: Locator;
  readonly nameError: Locator;
  readonly phoneError: Locator;
  readonly networkError: Locator;

  // Paiement
  readonly interacTitle: Locator;
  readonly interacAmount: Locator;
  readonly reference: Locator;
  readonly transferSentButton: Locator;

  constructor(private readonly page: Page) {
    this.emptyCart = page.getByText('Your cart is empty.');
    this.orderButton = page.getByRole('button', { name: 'Order', exact: true });
    this.nextStepHint = page.getByText(/^Next: your details/);
    this.whatsAppButton = page.getByRole('button', { name: 'Contact me on WhatsApp' });
    this.resellerNotice = page.getByText(/Independent reseller/);

    this.detailsTitle = page.getByText('Your details', { exact: true });
    this.nameField = page.getByLabel('Your name');
    this.phoneField = page.getByLabel('Phone (WhatsApp)');
    this.addressField = page.getByLabel(/^Delivery address/);
    this.confirmButton = page.getByRole('button', { name: 'Confirm the order' });
    this.nameError = page.getByText('Enter your name');
    this.phoneError = page.getByText('10-digit phone number');
    this.networkError = page.getByText(/No network right now/);

    this.interacTitle = page.getByText('Interac', { exact: true });
    this.interacAmount = page.getByText(/^Send \$[\d.,]+ by Interac e-Transfer to/);
    this.reference = page.getByText(/^RWY-\d{4}$/);
    this.transferSentButton = page.getByRole('button', { name: 'Transfer sent' });
  }

  async showCategory(category: Category) {
    await this.page.getByRole('button', { name: category, exact: true }).click();
  }

  /** Carte d'un produit, retrouvée par son nom. */
  product(name: string) {
    return this.page.getByRole('group', { name });
  }

  /** Toutes les cartes de produits affichées (elles portent toutes un prix). */
  products() {
    return this.page.getByRole('group', { name: /\$\d/ });
  }

  /** Ajoute au panier un article sans taille (les "essentiels"). */
  async addToCart(name: string) {
    await this.product(name).getByRole('button', { name: 'Add' }).click();
  }

  cartLine(name: string) {
    return this.page.getByRole('button', { name: new RegExp(`^\\d+ × ${name}`) });
  }

  async goToDetails() {
    await this.orderButton.click();
    await this.detailsTitle.waitFor();
  }

  /**
   * Tape dans un champ comme le ferait un passager, touche par touche :
   * c'est ce que l'app reçoit réellement d'un clavier de tablette.
   */
  private async type(field: Locator, value: string) {
    await field.click();
    await field.pressSequentially(value, { delay: 15 });
  }

  async fillDetails(details: { name?: string; phone?: string; address?: string }) {
    if (details.name) await this.type(this.nameField, details.name);
    if (details.phone) await this.type(this.phoneField, details.phone);
    if (details.address) await this.type(this.addressField, details.address);
  }

  async confirm() {
    await this.confirmButton.click();
  }
}

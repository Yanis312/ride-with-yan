import type { Locator, Page } from '@playwright/test';

export type Category = 'All' | 'Air Force 1' | 'Dunk' | 'Vans' | 'The North Face';
export type Shopper = 'Men' | 'Women';

/** Boutique : deux rayons, catalogue, panier, commande sur WhatsApp. */
export class StorePage {
  readonly emptyCart: Locator;
  /** Rappel des prix et du délai, en haut de la boutique. */
  readonly pitch: Locator;
  readonly depositLine: Locator;
  readonly onDelivery: Locator;
  readonly orderButton: Locator;
  readonly whatsAppButton: Locator;
  readonly resellerNotice: Locator;

  // Feuille de commande WhatsApp, en trois étapes
  readonly orderSheetTitle: Locator;

  constructor(private readonly page: Page) {
    this.emptyCart = page.getByText('Your cart is empty.');
    this.pitch = page.getByText(/^From \$\d+ · Delivered/);
    this.depositLine = page.getByText('Deposit when ordering (50%, Interac)', { exact: true });
    this.onDelivery = page.getByText('On delivery (20 to 30 days)', { exact: true });
    this.orderButton = page.getByRole('button', { name: 'Order on WhatsApp' });
    this.whatsAppButton = page.getByRole('button', { name: 'Contact me on WhatsApp' });
    this.resellerNotice = page.getByText(/Independent reseller/);

    this.orderSheetTitle = page.getByText('Order in 3 steps', { exact: true });
  }

  /** Bouton d'un des deux rayons, en haut de la boutique. */
  shopper(shopper: Shopper) {
    return this.page.getByRole('button', { name: shopper, exact: true });
  }

  async showShopper(shopper: Shopper) {
    await this.shopper(shopper).click();
  }

  category(category: Category) {
    return this.page.getByRole('button', { name: category, exact: true });
  }

  async showCategory(category: Category) {
    await this.category(category).click();
  }

  /** Carte d'un produit, retrouvée par son nom. */
  product(name: string) {
    return this.page.getByRole('group', { name });
  }

  /** Toutes les cartes de produits affichées (elles portent toutes un prix). */
  products() {
    return this.page.getByRole('group', { name: /\$\d/ });
  }

  /** Ouvre la fiche d'un article, choisit la taille et l'ajoute au panier. */
  async addSized(name: string, size: string) {
    await this.product(name).getByRole('button', { name: 'View' }).click();
    await this.page.getByRole('button', { name: size, exact: true }).click();
    // « Add » pour un article en stock, « Order » pour un article sur commande.
    await this.page.getByRole('button', { name: /^(Add|Order) · \$/ }).click();
    await this.cartLine(name).waitFor();
  }

  /** Montant affiché dans le panier. */
  amount(text: string) {
    return this.page.getByText(text, { exact: true });
  }

  cartLine(name: string) {
    return this.page.getByRole('button', { name: new RegExp(`^\\d+ × ${name}`) });
  }

  /** Étape de la commande, retrouvée par son texte. */
  step(text: string | RegExp) {
    return this.page.getByText(text);
  }

  async order() {
    await this.orderButton.click();
    await this.orderSheetTitle.waitFor();
  }
}

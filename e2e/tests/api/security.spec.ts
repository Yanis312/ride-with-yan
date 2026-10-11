import { randomUUID } from 'node:crypto';
import { expect, test } from '@playwright/test';
import { config } from '../../src/config.js';
import { apiErrorSchema } from '../../src/api/schemas.js';
import { SupabaseAnon } from '../../src/api/supabase.js';

// Ces tests jouent le rôle d'un inconnu qui n'a que la clé publique de l'app
// (elle est visible par tous). Chaque tentative doit être REFUSÉE par la base :
// tant que les règles tiennent, aucun test ne crée ni ne modifie de données.

/** Code d'erreur PostgreSQL : accès refusé par les règles de sécurité (RLS). */
const FORBIDDEN = '42501';
/** Code d'erreur PostgreSQL : valeur refusée par une contrainte de la table. */
const INVALID = '23514';

const validOrder = () => ({
  id: randomUUID(),
  reference: 'RWY-0000',
  name: 'Test automatique',
  phone: '514 555 0199',
  address: null,
  language: 'en',
  lines: [{ id: 'water', name: 'Eau', size: '', qty: 1, price: 2, on_order: false }],
  pay_now: 2,
  pay_later: 0,
});

async function errorCode(response: { json(): Promise<unknown> }) {
  return apiErrorSchema.parse(await response.json()).code;
}

test.describe('Accès sans clé', () => {
  test('la base refuse une requête sans clé', async ({ request }) => {
    const response = await request.get(`${config.supabaseUrl}/rest/v1/settings?select=*`);

    expect(response.status()).toBe(401);
  });

  test('le schéma privé (nom du canal d’alertes) n’est pas exposé', async ({ request }) => {
    const response = await new SupabaseAnon(request).read('app_secrets', {
      'Accept-Profile': 'private',
    });

    expect(response.status()).toBe(406);
  });

  test('un visiteur n’est pas administrateur', async ({ request }) => {
    const response = await new SupabaseAnon(request).call('is_admin');

    expect(response.status()).toBe(200);
    expect(await response.json()).toBe(false);
  });
});

test.describe('Commandes : données personnelles des clients', () => {
  test('un visiteur ne peut pas lire les commandes', async ({ request }) => {
    const response = await new SupabaseAnon(request).read('orders');

    // La base répond, mais ne montre aucune ligne à un visiteur.
    expect(response.status()).toBe(200);
    expect(await response.json()).toEqual([]);
  });

  test('un visiteur ne peut pas modifier une commande', async ({ request }) => {
    // Modification sans effet (« new » reste « new ») : même si la règle
    // sautait un jour, ce test ne pourrait rien abîmer, seulement le signaler.
    const response = await new SupabaseAnon(request).update('orders', 'status=eq.new', {
      status: 'new',
    });

    // Aucune ligne touchée : la base ne laisse voir aucune commande.
    expect(await response.json()).toEqual([]);
  });

  test('impossible de déposer une commande déjà marquée payée', async ({ request }) => {
    const response = await new SupabaseAnon(request).insert(
      'orders',
      { ...validOrder(), status: 'paid' },
      { silent: true },
    );

    expect(response.ok()).toBe(false);
    expect(await errorCode(response)).toBe(FORBIDDEN);
  });

  test('impossible de déposer une commande avec le virement déjà déclaré', async ({ request }) => {
    const response = await new SupabaseAnon(request).insert(
      'orders',
      { ...validOrder(), transfer_claimed: true },
      { silent: true },
    );

    expect(response.ok()).toBe(false);
    expect(await errorCode(response)).toBe(FORBIDDEN);
  });

  const invalidOrders: [string, Record<string, unknown>][] = [
    ['un code de commande mal formé', { reference: 'HACK-1' }],
    ['un nom vide', { name: '   ' }],
    ['un téléphone qui n’en est pas un', { phone: '<script>alert(1)</script>' }],
    ['une adresse démesurée', { address: 'x'.repeat(301) }],
    ['une langue inconnue', { language: 'xx' }],
    ['un panier vide', { lines: [] }],
    ['un montant négatif', { pay_now: -5 }],
    ['un montant démesuré', { pay_now: 10_001 }],
  ];

  for (const [label, change] of invalidOrders) {
    test(`la base refuse une commande avec ${label}`, async ({ request }) => {
      const response = await new SupabaseAnon(request).insert(
        'orders',
        { ...validOrder(), ...change },
        { silent: true },
      );

      expect(response.status()).toBe(400);
      expect(await errorCode(response)).toBe(INVALID);
    });
  }

  test('déclarer un virement sur une commande inconnue ne change rien', async ({ request }) => {
    const response = await new SupabaseAnon(request).call('claim_transfer', {
      order_id: randomUUID(),
      order_reference: 'RWY-0000',
    });

    expect(response.status()).toBe(204);
  });
});

test.describe('Catalogue et sondage : réservés à l’administrateur', () => {
  // Un identifiant qui n'est celui d'aucun produit réel.
  const probe = 'e2e-security-probe';

  test('un visiteur ne peut pas changer un prix', async ({ request }) => {
    const response = await new SupabaseAnon(request).insert('product_overrides', {
      id: probe,
      price: 1,
    });

    expect(response.ok()).toBe(false);
    expect(await errorCode(response)).toBe(FORBIDDEN);
  });

  test('un visiteur ne peut pas modifier les réglages', async ({ request }) => {
    const response = await new SupabaseAnon(request).insert('settings', {
      key: probe,
      value: { hacked: true },
    });

    expect(response.ok()).toBe(false);
    expect(await errorCode(response)).toBe(FORBIDDEN);
  });

  test('un visiteur ne peut pas écrire directement dans les votes', async ({ request }) => {
    const response = await new SupabaseAnon(request).insert('poll_votes', {
      question_id: probe,
      option_id: 'a',
      votes: 9999,
    });

    expect(response.ok()).toBe(false);
    expect(await errorCode(response)).toBe(FORBIDDEN);
  });

  test('un vote aux identifiants invalides est refusé', async ({ request }) => {
    const response = await new SupabaseAnon(request).call('cast_vote', {
      question: "x'; drop table poll_votes; --",
      choice: 'a',
    });

    expect(response.status()).toBe(400);
    expect(apiErrorSchema.parse(await response.json()).message).toBe('vote invalide');
  });
});

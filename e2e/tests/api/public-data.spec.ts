import { expect, test } from '@playwright/test';
import { z } from 'zod';
import { pollVoteSchema, productOverrideSchema, settingSchema } from '../../src/api/schemas.js';
import { SupabaseAnon } from '../../src/api/supabase.js';

// Ce que l'app lit au démarrage, sans compte. Lecture seule.
test.describe('Données publiques de la base', () => {
  test('les réglages de produits ont la forme attendue par l’app', async ({ request }) => {
    const response = await new SupabaseAnon(request).read('product_overrides');

    expect(response.status()).toBe(200);
    const overrides = z.array(productOverrideSchema).parse(await response.json());
    // Un même produit n'a qu'un seul réglage.
    expect(new Set(overrides.map((o) => o.id)).size).toBe(overrides.length);
  });

  test('les réglages généraux ont la forme attendue', async ({ request }) => {
    const response = await new SupabaseAnon(request).read('settings');

    expect(response.status()).toBe(200);
    z.array(settingSchema).parse(await response.json());
  });

  test('les votes de la question du jour sont des compteurs anonymes', async ({ request }) => {
    const response = await new SupabaseAnon(request).read('poll_votes');

    expect(response.status()).toBe(200);
    const votes = z.array(pollVoteSchema.strict()).parse(await response.json());
    // `strict` : aucune colonne en trop, donc rien qui identifie un votant.
    expect(votes.every((v) => v.votes >= 0)).toBe(true);
  });

  test('la base répond en moins de 3 secondes', async ({ request }) => {
    const start = Date.now();
    const response = await new SupabaseAnon(request).read('product_overrides');

    expect(response.ok()).toBe(true);
    expect(Date.now() - start).toBeLessThan(3000);
  });
});

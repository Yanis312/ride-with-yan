import { z } from 'zod';

/** Commande telle que l'app l'envoie à la base (table `orders`). */
export const orderSchema = z.object({
  id: z.string().uuid(),
  reference: z.string().regex(/^RWY-\d{4}$/),
  name: z.string().min(1).max(80),
  phone: z.string().regex(/^[0-9+() .-]{7,24}$/),
  address: z.string().max(300).nullable(),
  language: z.enum(['fr', 'en']),
  lines: z
    .array(
      z.object({
        id: z.string().min(1),
        name: z.string().min(1),
        size: z.string(),
        qty: z.number().int().positive(),
        price: z.number().nonnegative(),
        on_order: z.boolean(),
      }),
    )
    .min(1)
    .max(30),
  pay_now: z.number().min(0).max(10_000),
  pay_later: z.number().min(0).max(10_000),
});

/** Réglage d'un produit fait dans le panneau d'administration. */
export const productOverrideSchema = z.object({
  id: z.string().min(1).max(80),
  price: z.number().nonnegative().nullable(),
  sizes: z.record(z.string(), z.number().int().nonnegative()).nullable(),
  stock: z.number().int().nonnegative().nullable(),
  hidden: z.boolean(),
  updated_at: z.string().datetime({ offset: true }),
});

export const settingSchema = z.object({
  key: z.string().min(1).max(80),
  value: z.unknown(),
  updated_at: z.string().datetime({ offset: true }),
});

/** Compteur anonyme d'une réponse à la question du jour. */
export const pollVoteSchema = z.object({
  question_id: z.string().regex(/^[a-z0-9_-]{1,40}$/),
  option_id: z.string().regex(/^[a-z0-9_-]{1,40}$/),
  votes: z.number().int().nonnegative(),
});

/** Erreur renvoyée par l'API de la base. */
export const apiErrorSchema = z.object({
  code: z.string(),
  message: z.string(),
});

export type Order = z.infer<typeof orderSchema>;

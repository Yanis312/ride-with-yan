export const targets = ['website', 'instagram', 'tiktok', 'facebook', 'maps'] as const;
export type Target = (typeof targets)[number];

/** Adresse de destination, ou null si l'annonceur ne l'a pas renseignée. */
export function destination(ad: Record<string, unknown>, to: Target): string | null {
  if (to === 'maps') {
    const { lat, lng } = ad;
    if (typeof lat !== 'number' || typeof lng !== 'number') return null;
    return `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;
  }
  const url = ad[to];
  return typeof url === 'string' && url.startsWith('https://') ? url : null;
}

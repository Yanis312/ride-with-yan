import type { APIRequestContext } from '@playwright/test';
import { config } from '../config.js';

/**
 * Accès à la base tel que l'a un inconnu sur Internet : seulement la clé
 * publique de l'app, sans compte. C'est le point de vue d'un attaquant.
 */
export class SupabaseAnon {
  constructor(private readonly request: APIRequestContext) {}

  private get headers() {
    return {
      apikey: config.supabaseKey,
      Authorization: `Bearer ${config.supabaseKey}`,
      'Content-Type': 'application/json',
      // Demande à la base de renvoyer les lignes réellement touchées.
      Prefer: 'return=representation',
    };
  }

  private url(path: string) {
    return `${config.supabaseUrl}/rest/v1/${path}`;
  }

  read(table: string, headers: Record<string, string> = {}) {
    return this.request.get(this.url(`${table}?select=*`), {
      headers: { ...this.headers, ...headers },
    });
  }

  /**
   * `silent` : ne demande pas à relire la ligne créée. C'est ce que fait
   * l'app pour une commande, puisqu'elle n'a pas le droit de la relire.
   */
  insert(table: string, row: unknown, { silent = false } = {}) {
    const headers = silent ? { ...this.headers, Prefer: 'return=minimal' } : this.headers;
    return this.request.post(this.url(table), { headers, data: row });
  }

  update(table: string, filter: string, changes: unknown) {
    return this.request.patch(this.url(`${table}?${filter}`), {
      headers: this.headers,
      data: changes,
    });
  }

  call(fn: string, args: unknown = {}) {
    return this.request.post(this.url(`rpc/${fn}`), { headers: this.headers, data: args });
  }
}

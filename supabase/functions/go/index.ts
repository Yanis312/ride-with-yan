// Lien des QR codes des annonceurs : compte le scan, puis envoie le
// passager vers la page du commerce (Instagram, site, carte…).
//
//   /functions/v1/go?ad=<id>&to=instagram
//
// Seules les adresses enregistrées pour cet annonceur sont possibles :
// impossible de se servir de ce lien pour rediriger ailleurs.

import { destination, type Target, targets } from './destination.ts';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';


const headers = {
  apikey: serviceKey,
  Authorization: `Bearer ${serviceKey}`,
  'Content-Type': 'application/json',
};

function notFound() {
  return new Response('Lien introuvable · Link not found', {
    status: 404,
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
}

Deno.serve(async (request) => {
  const params = new URL(request.url).searchParams;
  const id = params.get('ad') ?? '';
  const to = params.get('to') as Target;
  if (!/^[a-z0-9-]{2,40}$/.test(id) || !targets.includes(to)) return notFound();

  const response = await fetch(
    `${supabaseUrl}/rest/v1/advertisers?id=eq.${id}&active=eq.true&select=*`,
    { headers },
  );
  const rows = response.ok ? await response.json() : [];
  const url = rows.length ? destination(rows[0], to) : null;
  if (!url) return notFound();

  // Le scan compte dans les statistiques (anonyme, comme le reste).
  await fetch(`${supabaseUrl}/rest/v1/usage_events`, {
    method: 'POST',
    headers: { ...headers, Prefer: 'return=minimal' },
    body: JSON.stringify({
      session_id: crypto.randomUUID(),
      kind: 'tap',
      name: `ads.scan:${id}:${to}`,
    }),
  }).catch(() => {});

  return Response.redirect(url, 302);
});

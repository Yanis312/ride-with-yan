// Assistant de bord : reçoit la conversation du passager, l'envoie au modèle
// déployé sur Azure AI Foundry et renvoie la réponse.
//
// La clé du service d'IA reste ici, côté serveur : la tablette ne la voit
// jamais. Le contenu des conversations n'est ni enregistré ni journalisé.

import { systemPrompt } from './prompt.ts';
import { cleanMessages } from './validate.ts';

const endpoint = Deno.env.get('AZURE_OPENAI_ENDPOINT') ?? '';
const apiKey = Deno.env.get('AZURE_OPENAI_KEY') ?? '';
const deployment = Deno.env.get('AZURE_OPENAI_DEPLOYMENT') ?? 'assistant';
const apiVersion = Deno.env.get('AZURE_OPENAI_API_VERSION') ?? '2024-10-21';
// Les modèles récents attendent « max_completion_tokens », les anciens « max_tokens ».
const tokenParam = Deno.env.get('AZURE_OPENAI_TOKEN_PARAM') ?? 'max_tokens';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function reply(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
}

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

async function takeQuota(session: string): Promise<boolean> {
  const response = await fetch(`${supabaseUrl}/rest/v1/rpc/chat_take_quota`, {
    method: 'POST',
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ session }),
  });
  if (!response.ok) throw new Error(`quota ${response.status}`);
  return (await response.json()) === true;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (request.method !== 'POST') return reply(405, { error: 'method' });
  if (!endpoint || !apiKey) return reply(503, { error: 'not_configured' });

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return reply(400, { error: 'json' });
  }

  const session = String(body.session_id ?? '');
  const messages = cleanMessages(body.messages);
  if (!uuid.test(session) || !messages) return reply(400, { error: 'invalid' });

  try {
    if (!(await takeQuota(session))) return reply(429, { error: 'quota' });
  } catch {
    return reply(503, { error: 'quota_unavailable' });
  }

  const language = body.language === 'fr' ? 'français' : 'English';
  const url =
    `${endpoint.replace(/\/$/, '')}/openai/deployments/${deployment}` +
    `/chat/completions?api-version=${apiVersion}`;

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'api-key': apiKey, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        messages: [
          { role: 'system', content: `${systemPrompt}\n\nLangue de l'interface : ${language}.` },
          ...messages,
        ],
        [tokenParam]: 400,
      }),
      signal: AbortSignal.timeout(25_000),
    });
    if (response.status === 400) {
      // Filtre de contenu d'Azure ou question refusée.
      return reply(200, { reply: null, filtered: true });
    }
    if (!response.ok) {
      console.error('Azure', response.status);
      return reply(502, { error: 'model' });
    }
    const data = await response.json();
    const text = data?.choices?.[0]?.message?.content;
    if (typeof text !== 'string' || !text.trim()) return reply(502, { error: 'empty' });
    return reply(200, { reply: text.trim() });
  } catch {
    return reply(504, { error: 'timeout' });
  }
});

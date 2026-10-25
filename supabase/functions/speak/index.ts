// Voix de Yan : transforme une réponse en audio avec Azure AI Speech.
//
//   GET /functions/v1/speak?lang=fr&text=Bonjour
//
// La clé d'Azure reste ici. Le service est au niveau gratuit (F0) : au-delà
// de 500 000 caractères par mois, Azure refuse au lieu de facturer.

import { ssml } from './voice.ts';

const key = Deno.env.get('SPEECH_KEY') ?? '';
const region = Deno.env.get('SPEECH_REGION') ?? 'canadacentral';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (!key) return new Response('not configured', { status: 503, headers: cors });

  const params = new URL(request.url).searchParams;
  const text = params.get('text') ?? '';
  const language = params.get('lang') === 'en' ? 'en' : 'fr';
  if (!text.trim()) return new Response('empty', { status: 400, headers: cors });

  const response = await fetch(
    `https://${region}.tts.speech.microsoft.com/cognitiveservices/v1`,
    {
      method: 'POST',
      headers: {
        'Ocp-Apim-Subscription-Key': key,
        'Content-Type': 'application/ssml+xml',
        'X-Microsoft-OutputFormat': 'audio-24khz-48kbitrate-mono-mp3',
        'User-Agent': 'ride-with-yan',
      },
      body: ssml(text, language),
    },
  );
  if (!response.ok) {
    console.error('Speech', response.status);
    return new Response('speech error', { status: 502, headers: cors });
  }
  return new Response(response.body, {
    headers: { ...cors, 'Content-Type': 'audio/mpeg', 'Cache-Control': 'public, max-age=86400' },
  });
});

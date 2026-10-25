/** Voix neuronales du Canada, et SSML envoyé à Azure Speech. */
export const voices = { fr: 'fr-CA-SylvieNeural', en: 'en-CA-ClaraNeural' } as const;

const escapes: Record<string, string> = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&apos;',
};

/** Texte prêt à être lu : nettoyé, raccourci, et protégé pour le XML. */
export function ssml(text: string, language: 'fr' | 'en'): string {
  const clean = text.replace(/\s+/g, ' ').trim().slice(0, 600);
  const safe = clean.replace(/[&<>"']/g, (c) => escapes[c]);
  const lang = language === 'fr' ? 'fr-CA' : 'en-CA';
  return `<speak version="1.0" xml:lang="${lang}"><voice name="${voices[language]}">${safe}</voice></speak>`;
}

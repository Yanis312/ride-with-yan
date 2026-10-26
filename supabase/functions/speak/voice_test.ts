import { assertEquals, assertStringIncludes } from 'jsr:@std/assert@1';
import { ssml } from './voice.ts';

Deno.test('voix québécoise en français, canadienne en anglais', () => {
  assertStringIncludes(ssml('Bonjour', 'fr'), 'fr-CA-SylvieNeural');
  assertStringIncludes(ssml('Hello', 'en'), 'en-CA-ClaraNeural');
});

Deno.test('un texte ne peut pas injecter de balises SSML', () => {
  const xml = ssml('Prix <break time="10s"/> & taxes', 'fr');
  assertStringIncludes(xml, 'Prix &lt;break time=&quot;10s&quot;/&gt; &amp; taxes');
});

Deno.test('texte raccourci à 600 caractères', () => {
  const xml = ssml('a'.repeat(900), 'fr');
  assertEquals(xml.match(/<voice[^>]*>(a*)<\/voice>/)![1].length, 600);
});

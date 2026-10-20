import { assertEquals } from 'jsr:@std/assert@1';
import { destination } from './destination.ts';

Deno.test('renvoie seulement une adresse https enregistrée', () => {
  const ad = { instagram: 'https://instagram.com/atlas', facebook: 'javascript:alert(1)' };
  assertEquals(destination(ad, 'instagram'), 'https://instagram.com/atlas');
  assertEquals(destination(ad, 'facebook'), null);
  assertEquals(destination(ad, 'website'), null);
});

Deno.test('itinéraire vers le commerce', () => {
  assertEquals(
    destination({ lat: 45.42, lng: -75.7 }, 'maps'),
    'https://www.google.com/maps/search/?api=1&query=45.42,-75.7',
  );
  assertEquals(destination({}, 'maps'), null);
});

// Mesure du premier chargement de l'app, comme sur la tablette branchée sur
// le partage de connexion d'un téléphone (4G simulée).
//
//   node perf/load.mjs [adresse] [nombre d'essais]
//
// Affiche le temps jusqu'à « Tap to start » et le poids téléchargé.
import { chromium } from '@playwright/test';

const url = process.argv[2] ?? 'http://localhost:8080/';
const runs = Number(process.argv[3] ?? 3);

// 4G moyenne : 9 Mb/s descendant, 2 Mb/s montant, 60 ms de latence.
const network = {
  offline: false,
  latency: 60,
  downloadThroughput: (9 * 1024 * 1024) / 8,
  uploadThroughput: (2 * 1024 * 1024) / 8,
};

const results = [];
for (let i = 0; i < runs; i++) {
  const browser = await chromium.launch({ channel: process.env.PW_CHANNEL });
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Network.enable');
  await cdp.send('Network.emulateNetworkConditions', network);

  let bytes = 0;
  const byType = {};
  cdp.on('Network.loadingFinished', (e) => (bytes += e.encodedDataLength));
  cdp.on('Network.responseReceived', (e) => {
    const ext = new URL(e.response.url).pathname.match(/\.(\w+)$/)?.[1] ?? 'autre';
    byType[ext] = (byType[ext] ?? 0) + 1;
  });

  const start = Date.now();
  await page.goto(`${url}?e2e`);
  await page.getByRole('button', { name: /Tap to start/ }).waitFor({ timeout: 120_000 });
  const seconds = (Date.now() - start) / 1000;
  results.push({ seconds, mo: bytes / 1048576 });
  console.log(`essai ${i + 1} : ${seconds.toFixed(1)} s, ${(bytes / 1048576).toFixed(1)} Mo`);
  if (i === 0) console.log('  fichiers :', JSON.stringify(byType));
  await browser.close();
}

const avg = (k) => results.reduce((s, r) => s + r[k], 0) / results.length;
console.log(`moyenne : ${avg('seconds').toFixed(1)} s, ${avg('mo').toFixed(1)} Mo`);

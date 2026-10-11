// Petit serveur de fichiers pour l'app web construite (app/build/web).
// Il sert les bons types pour .mjs et .wasm, indispensables à Flutter web.
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize, resolve } from 'node:path';

const root = resolve(process.argv[2] ?? '../app/build/web');
const port = Number(process.argv[3] ?? 8080);
const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.wasm': 'application/wasm',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.mp4': 'video/mp4',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.frag': 'text/plain',
  '.bin': 'application/octet-stream',
};

createServer(async (request, response) => {
  try {
    const path = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    let file = normalize(join(root, path));
    if (!file.startsWith(root)) throw new Error('hors du dossier');
    if ((await stat(file)).isDirectory()) file = join(file, 'index.html');
    const body = await readFile(file);
    response.writeHead(200, {
      'Content-Type': types[extname(file)] ?? 'application/octet-stream',
      'Cache-Control': 'no-store',
    });
    response.end(body);
  } catch {
    response.writeHead(404).end('Introuvable');
  }
}).listen(port, () => console.log(`App servie sur http://localhost:${port}`));

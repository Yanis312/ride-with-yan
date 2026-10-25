#!/usr/bin/env bash
# Construction de l'app sur Cloudflare (leur machine n'a pas Flutter).
# Réglages du projet Cloudflare (le dossier de sortie est dans wrangler.jsonc) :
#   commande de build : bash tools/cloudflare-pages-build.sh
#   dossier de sortie : app/build/web
set -euo pipefail

FLUTTER_VERSION=3.47.5
if [ ! -x "$HOME/flutter/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"
flutter config --no-analytics >/dev/null

cd app
flutter pub get
flutter build web --release --wasm
# Sites de démonstration publiés à côté de l'app, comme sur GitHub Pages.
cp -r ../showcase build/web/showcase

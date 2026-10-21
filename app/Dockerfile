# Image de l'app web, construite sans rien installer sur le poste :
#   1. une image avec Flutter construit l'app (WebAssembly) ;
#   2. une image nginx, légère, la sert. Seule celle-ci est gardée.

FROM debian:bookworm-slim AS build
RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl unzip xz-utils ca-certificates \
 && rm -rf /var/lib/apt/lists/*
# Même version de Flutter que sur le poste de développement.
ARG FLUTTER_VERSION=3.47.5
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter config --no-analytics && flutter precache --web

WORKDIR /app
# Dépendances d'abord : elles restent en cache tant que pubspec ne change pas.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release --wasm

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

# Image officielle de Playwright : navigateurs et dépendances système déjà
# installés. La version doit être celle de @playwright/test (package-lock).
FROM mcr.microsoft.com/playwright:v1.64.0-noble

WORKDIR /e2e
COPY package.json package-lock.json ./
RUN npm ci
COPY . .

ENV CI=true
CMD ["npx", "playwright", "test", "--project=api", "--project=ui-chromium"]

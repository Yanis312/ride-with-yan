import { defineConfig, devices } from '@playwright/test';
import { config } from './src/config.js';

// Firefox et WebKit (le moteur de Safari) ne tournent que la nuit : ALL_BROWSERS.
const extraBrowsers = process.env.ALL_BROWSERS
  ? [
      {
        name: 'ui-firefox',
        testDir: './tests/ui',
        // Firefox et WebKit sans carte graphique dessinent l'app lentement.
        timeout: 180_000,
        use: { ...devices['Desktop Firefox'], ...tablet() },
      },
      {
        name: 'ui-webkit',
        testDir: './tests/ui',
        timeout: 180_000,
        use: { ...devices['Desktop Safari'], ...tablet() },
      },
    ]
  : [];

/** L'app est faite pour une tablette en paysage. */
function tablet() {
  return { viewport: { width: 1280, height: 800 }, locale: 'en-CA' };
}

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  // Les machines d'intégration continue n'ont que deux processeurs.
  workers: process.env.CI ? 2 : undefined,
  // Sur GitHub, chaque échec est aussi annoté directement dans la page de l'exécution.
  reporter: process.env.GITHUB_ACTIONS
    ? [['list'], ['html', { open: 'never' }], ['github']]
    : [['list'], ['html', { open: 'never' }]],
  // L'app Flutter met quelques secondes à démarrer dans un navigateur neuf,
  // davantage sur les machines partagées de GitHub et d'Azure.
  timeout: process.env.CI ? 120_000 : 60_000,
  expect: { timeout: 15_000 },
  use: {
    baseURL: config.appUrl,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'api', testDir: './tests/api' },
    {
      name: 'ui-chromium',
      testDir: './tests/ui',
      use: {
        ...devices['Desktop Chrome'],
        ...tablet(),
        // En local, PW_CHANNEL=chrome réutilise le Chrome déjà installé.
        channel: process.env.PW_CHANNEL,
      },
    },
    ...extraBrowsers,
  ],
  // L'app construite (flutter build web) est servie le temps des tests.
  webServer: process.env.APP_URL
    ? undefined
    : {
        command: 'node serve.mjs ../app/build/web 8080',
        url: 'http://localhost:8080',
        reuseExistingServer: !process.env.CI,
        timeout: 30_000,
      },
});

# Plans de test

Les plans écrits par l'agent **playwright-test-planner** arrivent ici (Markdown),
avant d'être transformés en tests par **playwright-test-generator**.

## Utiliser les agents (Claude Code)

Depuis le dossier `e2e/`, dans Claude Code :

1. « Avec playwright-test-planner, fais un plan de test pour l'écran Météo. »
   → le plan est enregistré dans `specs/`.
2. « Avec playwright-test-generator, écris les tests du plan `specs/meteo.md`. »
   → les tests arrivent dans `tests/`.
3. Quand un test casse après un changement de l'app :
   « Avec playwright-test-healer, répare `tests/ui/store.spec.ts`. »

Chaque test part de `tests/ui/seed.spec.ts` : l'app ouverte, la base simulée.
Les agents passent par le serveur MCP de Playwright déclaré dans `.mcp.json`.

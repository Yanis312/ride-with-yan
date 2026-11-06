import { expect, test } from '../../src/fixtures.js';

test.describe('Assistant de bord', () => {
  test.beforeEach(async ({ welcome }) => {
    await welcome.open();
    await welcome.start('fr');
  });

  test('répond à une question suggérée', async ({ page, backend }) => {
    await page.getByRole('button', { name: 'Demandez à Yan' }).click();
    await expect(page.getByText('Bonjour, je suis Yan ! Posez-moi une question.')).toBeVisible();

    await page.getByRole('button', { name: /Comment se passe la livraison/ }).click();

    await expect(page.getByText(/Livraison chez vous en 20 à 30 jours/)).toBeVisible();
    // Ce que reçoit le serveur : la question, la langue, le numéro de course.
    expect(backend.chats).toHaveLength(1);
    expect(backend.chats[0]).toMatchObject({
      language: 'fr',
      messages: [{ role: 'user', content: 'Comment se passe la livraison ?' }],
    });
    expect(String(backend.chats[0].session_id)).toMatch(/^[0-9a-f-]{36}$/);
  });

  test('prévient quand le passager a posé trop de questions', async ({ page, backend }) => {
    backend.chatReply = { status: 429, body: { error: 'quota' } };
    await page.getByRole('button', { name: 'Demandez à Yan' }).click();
    await page.getByRole('button', { name: /Que faire à Ottawa/ }).click();

    await expect(page.getByText(/Vous avez posé beaucoup de questions/)).toBeVisible();
  });
});

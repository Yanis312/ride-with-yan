import { expect, test } from '../../src/fixtures.js';

test.describe('Assistant de bord', () => {
  test.beforeEach(async ({ welcome }) => {
    await welcome.open();
    await welcome.start('fr');
  });

  test('répond à une question suggérée', async ({ page, backend }) => {
    await page.getByRole('button', { name: 'Demandez à Yan' }).click();
    await expect(page.getByText('Bonjour, je suis Yan ! Posez-moi une question.')).toBeVisible();

    await page.getByRole('button', { name: /C’est quoi le combo/ }).click();

    await expect(page.getByText(/une paire et un maillot pour 120/)).toBeVisible();
    // Ce que reçoit le serveur : la question, la langue, le numéro de course.
    expect(backend.chats).toHaveLength(1);
    expect(backend.chats[0]).toMatchObject({
      language: 'fr',
      messages: [{ role: 'user', content: 'C’est quoi le combo à 120 $ ?' }],
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

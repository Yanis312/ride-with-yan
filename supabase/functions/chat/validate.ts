export type Message = { role: 'user' | 'assistant'; content: string };

/** Garde seulement une conversation raisonnable : 10 messages, 500 caractères. */
export function cleanMessages(input: unknown): Message[] | null {
  if (!Array.isArray(input) || input.length === 0) return null;
  const messages: Message[] = [];
  for (const m of input.slice(-10)) {
    if (typeof m !== 'object' || m === null) return null;
    const { role, content } = m as Record<string, unknown>;
    if ((role !== 'user' && role !== 'assistant') || typeof content !== 'string') return null;
    const text = content.trim().slice(0, 500);
    if (text) messages.push({ role, content: text });
  }
  if (messages.length === 0 || messages[messages.length - 1].role !== 'user') return null;
  return messages;
}

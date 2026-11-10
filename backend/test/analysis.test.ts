import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createServer } from '../src/main.js';

const payload = { text: 'Synthetic task', today: '2026-11-10' };

test('local analysis validates input and returns bounded suggestions', async (context) => {
  const app = await createServer(true);
  context.after(() => app.close());
  await app.listen(0, '127.0.0.1');
  const url = new URL('/v1/memory-analysis', await app.getUrl());
  const post = (body: object) => fetch(url, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });
  const response = await post(payload);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { suggestions: [{ kind: 'task', title: payload.text, day: payload.today }] });
  const malformed = await fetch(url, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{"text":"Synthetic task"',
  });
  assert.equal(malformed.status, 400);
  assert.deepEqual(await malformed.json(), { statusCode: 400 });
  assert.equal((await post({ ...payload, text: "x".repeat(110_000) })).status, 413);
  for (const invalid of [
    { ...payload, text: ' ' }, { ...payload, text: 'x'.repeat(4001) },
    { ...payload, today: '2026-02-30' }, { ...payload, attachment: 'unexpected' },
  ]) {
    const error = await post(invalid);
    assert.equal(error.status, 400);
    assert.equal((await error.text()).includes(payload.text), false);
  }
});

test('default server configuration has no analysis route', async (context) => {
  const app = await createServer(false);
  context.after(() => app.close());
  await app.listen(0, '127.0.0.1');
  const response = await fetch(new URL('/v1/memory-analysis', await app.getUrl()), { method: 'POST' });
  assert.equal(response.status, 404);
});

test('provider errors cannot expose record text', async (context) => {
  const app = await createServer(true, { async analyze(input) { throw new Error(input.text); } });
  context.after(() => app.close());
  await app.listen(0, '127.0.0.1');
  const response = await fetch(new URL('/v1/memory-analysis', await app.getUrl()), {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload),
  });
  assert.equal(response.status, 502);
  assert.equal((await response.text()).includes(payload.text), false);
});

const { after, before, test } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');

let server;
let baseUrl;

before(async () => {
  server = app.listen(0);
  await new Promise((resolve, reject) => {
    server.once('listening', resolve);
    server.once('error', reject);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
});

test('health endpoint reports the API is running', async () => {
  const response = await fetch(`${baseUrl}/api/health`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'ok' });
});

test('protected customer endpoint rejects requests without a token', async () => {
  const response = await fetch(`${baseUrl}/api/customers`);
  assert.equal(response.status, 401);
  assert.deepEqual(await response.json(), { error: 'Token autentikasi diperlukan.' });
});

test('complaint attachment upload rejects unauthenticated requests', async () => {
  const response = await fetch(`${baseUrl}/api/complaints/images`, {
    method: 'POST',
    headers: { 'content-type': 'image/jpeg' },
    body: Buffer.from([0xff, 0xd8, 0xff])
  });
  assert.equal(response.status, 401);
  assert.deepEqual(await response.json(), { error: 'Token autentikasi diperlukan.' });
});

test('product photo upload rejects unauthenticated requests', async () => {
  const response = await fetch(`${baseUrl}/api/products/images`, {
    method: 'POST',
    headers: { 'content-type': 'image/jpeg' },
    body: Buffer.from([0xff, 0xd8, 0xff])
  });
  assert.equal(response.status, 401);
  assert.deepEqual(await response.json(), { error: 'Token autentikasi diperlukan.' });
});

test('customer registration validates input before touching the database', async () => {
  const response = await fetch(`${baseUrl}/api/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ name: 'A', phone: '1', password: 'short' })
  });
  assert.equal(response.status, 400);
  assert.equal((await response.json()).error, 'Input tidak valid.');
});

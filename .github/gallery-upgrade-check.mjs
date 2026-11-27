import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { join } from 'node:path';

const sharp = createRequire(join(process.cwd(), 'package.json'))('sharp');
const phase = process.argv[2];
const base = 'http://127.0.0.1:18765';
const auth = { Authorization: `Bearer ${process.env.BRIDGE_API_KEY}` };
const project = '/tmp/ci-gallery-package';
const listPath = '/api/gallery?project=' + encodeURIComponent(project);
const state = join(process.env.RUNNER_TEMP, 'gallery-smoke-state.json');
const source = await sharp({ create: { width: 965, height: 600, channels: 4, background: '#597b8b' } }).png().toBuffer();
async function upload() {
  const res = await fetch(base + '/api/gallery/upload', {
    method: 'POST', headers: { ...auth, 'Content-Type': 'application/json' },
    body: JSON.stringify({ base64: source.toString('base64'), mimeType: 'image/png', projectPath: project }),
  });
  assert.equal(res.status, 201);
  return (await res.json()).image;
}
async function list() {
  const res = await fetch(base + listPath, { headers: auth });
  assert.equal(res.status, 200);
  return (await res.json()).images;
}
const health = await fetch(base + '/health').then(r => r.json());
assert.equal(health.status, 'ok');
assert.equal(health.auth, 'required');
if (phase === 'seed') {
  const [a, b, survivor] = await Promise.all([upload(), upload(), upload()]);
  assert.equal(survivor.thumbnailUrl, undefined);
  await writeFile(state, JSON.stringify({ a, b, survivor }));
} else {
  const { a, b, survivor } = JSON.parse(await readFile(state));
  if (phase === 'upgrade') {
    assert.equal((await fetch(base + listPath)).status, 401);
    const listing = await list();
    const item = listing.find(entry => entry.id === survivor.id);
    assert.equal(item.url, survivor.url);
    const raw = await fetch(base + item.url);
    assert.equal(raw.headers.get('content-type'), 'image/png');
    assert.deepEqual(Buffer.from(await raw.arrayBuffer()), source);
    const thumb = await fetch(base + item.thumbnailUrl);
    assert.equal(thumb.headers.get('content-type'), 'image/webp');
    assert.equal((await sharp(Buffer.from(await thumb.arrayBuffer())).metadata()).width, 448);
    assert.equal((await fetch(base + a.url, { method: 'DELETE' })).status, 401);
    const deletes = await Promise.all([a, a, b].map(async image =>
      (await fetch(base + image.url, { method: 'DELETE', headers: auth })).status));
    assert.deepEqual(deletes.sort(), [200, 200, 404]);
  }
  assert.deepEqual((await list()).map(image => image.id), [survivor.id]);
  assert.equal((await fetch(base + a.url)).status, 404);
  assert.equal((await fetch(base + b.url)).status, 404);
}
console.log(`Packaged gallery smoke passed: ${phase}`);

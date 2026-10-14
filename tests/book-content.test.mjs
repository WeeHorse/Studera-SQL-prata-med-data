import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { chapters } from '../scripts/book-content.mjs';

const items = chapters();
test('exakt 29 kapitel, nummer 01–29 utan luckor', () => {
  assert.deepEqual(items.map(c => c.id),
    Array.from({length: 29}, (_, i) => String(i+1).padStart(2, '0')));
});
test('varje kapitel har Grund, Avancerat och Reflektion i rätt ordning', () => {
  for (const c of items) {
    const positions = ['## Grund', '## Avancerat', '## Reflektion'].map(h => c.source.indexOf(h));
    assert.ok(positions.every(n => n >= 0), c.name + ': saknad rubrik');
    assert.ok(positions[0] < positions[1] && positions[1] < positions[2], c.name + ': fel rubrikordning');
  }
});
test('publiceringskapitlen är bokbyggets aktuella källor', () => {
  for (const c of items) {
    assert.equal(c.source, readFileSync('content/sv/chapters/' + c.name, 'utf8'),
      c.name + ': avvikelse från publiceringskällan');
    assert.ok(c.title.startsWith(Number(c.id) + '. '),
      c.name + ': kapitelrubriken saknar rätt nummer');
    assert.ok(c.url.startsWith('/sv/chapters/'), c.name + ': fel URL');
  }
});

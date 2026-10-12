import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const chapter = readFileSync('content/sv/chapters/01-vad-ar-en-databas.md', 'utf8');
test('pilotkapitlet har rätt struktur', () => {
  for (const heading of ['## Grund', '## Avancerat', '## Reflektion']) {
    assert.ok(chapter.includes(heading), 'Saknad rubrik: ' + heading);
  }
});
test('pilotkapitlet innehåller SQL eller datamodellering', () => {
  assert.match(chapter, /SQL|databas/i);
});

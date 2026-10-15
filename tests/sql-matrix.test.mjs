import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';

test('SQL-verifieringsmatrisen omfattar exakt varje SQL-kodblock i manuskriptet', () => {
  const files = readdirSync('content/sv/chapters').filter(n => /^\d{2}-.*\.md$/.test(n)).sort();
  const expected = files.flatMap(name => {
    const chapter = name.slice(0, 2);
    const source = readFileSync('content/sv/chapters/' + name, 'utf8');
    const matches = [...source.matchAll(/\`\`\`sql\s*\n[\s\S]*?\`\`\`/g)];
    return matches.map((_, i) => chapter + '.' + String(i + 1).padStart(2, '0'));
  });
  const matrix = readFileSync('quality/sql-verification-matrix.md', 'utf8');
  const actual = [...matrix.matchAll(/^\| (\d{2}\.\d{2}) \|/gm)].map(m => m[1]);
  assert.deepEqual(actual, expected, 'Uppdatera matrisen när kodblock ändras');
  assert.equal(new Set(actual).size, actual.length, 'Varje block får finnas en gång');
});

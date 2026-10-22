import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { preparePrint } from '../scripts/book-content.mjs';

test('Publit-inlaga har innehåll men inget omslag', () => {
  preparePrint({ interiorOnly: true });
  const book = readFileSync('dist/generated/book-sv-publit.md', 'utf8');
  assert.ok(!book.includes('class="sql-cover"'));
  assert.ok(book.includes('class="book-print-toc"'));
  assert.ok(book.includes('id="bok-forfattare"'));
  assert.ok(book.includes('id="bok-forord"'));
  assert.ok(book.includes('id="kapitel-01"'));
  assert.ok(book.includes('id="bok-referenser"'));
  assert.ok(book.indexOf('class="book-print-toc"') < book.indexOf('id="bok-forfattare"'));
  assert.ok(book.indexOf('id="bok-forfattare"') < book.indexOf('id="bok-forord"'));
  assert.ok(book.indexOf('id="bok-forord"') < book.indexOf('id="kapitel-01"'));
  assert.ok(existsSync('publishing/print/publit.config.mjs'));
});

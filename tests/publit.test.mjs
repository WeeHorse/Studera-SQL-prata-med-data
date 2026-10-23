import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { preparePrint } from '../scripts/book-content.mjs';
import { expandPrintUrls } from '../scripts/print-links.mjs';

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

test('externa länkar visas som URL bara i Publit-inlagan', () => {
  const markdown = '[Läs artikeln](https://example.org/studie) och [internt](#del).';
  assert.match(expandPrintUrls(markdown), /https:\/\/example.org\/studie\)<\/span>/);
  assert.match(expandPrintUrls(markdown), /\[internt\]\(#del\)/);
  assert.equal(expandPrintUrls('![diagram](https://example.org/diagram.png)'), '![diagram](https://example.org/diagram.png)');
  assert.equal(expandPrintUrls('[https://example.org](https://example.org)'), '[https://example.org](https://example.org)');
  assert.equal(expandPrintUrls('```md\n[Länk](https://example.org)\n```'), '```md\n[Länk](https://example.org)\n```');
  preparePrint({ interiorOnly: true });
  assert.match(readFileSync('dist/generated/book-sv-publit.md', 'utf8'), /print-link-url/);
  preparePrint();
  assert.doesNotMatch(readFileSync('dist/generated/book-sv.md', 'utf8'), /print-link-url/);
});

test('inlagans försidor har rätt ordning och numreringsstilar', () => {
  preparePrint({ interiorOnly: true });
  const book = readFileSync('dist/generated/book-sv-publit.md', 'utf8');
  const markers = ['book-print-title-leaf', 'book-print-copyright-leaf', 'book-print-toc', 'book-print-author', 'book-print-foreword-section', 'id="kapitel-01"'];
  const positions = markers.map(marker => book.indexOf(marker));
  assert.ok(positions.every(pos => pos >= 0));
  assert.ok(positions.every((pos, i) => i === 0 || pos > positions[i - 1]));
  const css = readFileSync('publishing/print/book.css', 'utf8');
  assert.match(css, /@page :nth\(1 of foreword\)\s*\{\s*counter-reset:\s*page 0/);
});

test('innehållsförteckningen numrerar kapitel en gång och håller bilagor utanför', () => {
  preparePrint({ interiorOnly: true });
  const book = readFileSync('dist/generated/book-sv-publit.md', 'utf8');
  const toc = book.split('</section>')[2] ?? book.slice(book.indexOf('class="book-print-toc"'), book.indexOf('class="book-print-author"'));
  assert.match(toc, /<ol>[\s\S]*?href="#kapitel-01">Vad är en databas\?/);
  assert.doesNotMatch(toc, /href="#bok-forord"/);
  assert.match(toc, /<ul class="book-print-toc-appendices">/);
  const web = readFileSync('content/sv/innehall.md', 'utf8');
  assert.match(web, /1\. \[Vad är en databas\?\]/);
  assert.doesNotMatch(web, /1\. \[1\. Vad är en databas\?/);
});

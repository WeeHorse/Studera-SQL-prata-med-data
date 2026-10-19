import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { preparePrint } from '../scripts/book-content.mjs';

test('webbomslagen leder till innehållet och författarsidan ligger efter innehåll', () => {
  for (const file of ['content/index.md', 'content/sv/index.md']) {
    const source = readFileSync(file, 'utf8');
    assert.match(source, /layout: false/);
    assert.match(source, /book-cover-entry/);
    assert.match(source, /innehall\.html/);
  }
  assert.match(readFileSync('content/sv/forfattare.md','utf8'), /forord\.html/);
});
test('webbinnehåll länkar till alla kapitel och bilagan', () => {
  const toc = readFileSync('content/sv/innehall.md','utf8');
  const chapters = readdirSync('content/sv/chapters').filter(x => /^\d{2}-.*\.md$/.test(x));
  for (const file of chapters) assert.ok(toc.includes(file.replace(/\.md$/, '.html')), file);
  assert.match(toc, /bilaga-exempeldatabas\.html/);
  assert.match(toc, /forord\.html/);
  assert.match(toc, /bilaga-a-databasmodellering\.html/);
  assert.ok(toc.indexOf('bilaga-a-databasmodellering.html') < toc.indexOf('bilaga-exempeldatabas.html'));
  for (const n of [1,2,3]) assert.match(readFileSync('content/sv/bilaga-a-databasmodellering.md','utf8'), new RegExp('modell-a'+n+'\\.svg'));
  assert.ok(toc.indexOf('/sv/forfattare.html') < toc.indexOf('/sv/bilaga-exempeldatabas.html'));
});
test('PDF har innehållsförteckning och stabila ankare', () => {
  preparePrint();
  const book = readFileSync('dist/generated/book-sv.md','utf8');
  const covers = book.indexOf('class="sql-cover"');
  const author = book.indexOf('class="author-card"');
  const toc = book.indexOf('class="book-print-toc"');
  const first = book.indexOf('id="kapitel-01"');
  const foreword = book.indexOf('id="bok-forord"');
  assert.ok(covers >= 0 && covers < toc && toc < author && author < foreword && foreword < first);
  assert.ok(book.includes('href="#bok-forord"'));
  assert.ok(book.includes('Malmö, oktober 2026'));
  assert.ok(book.includes('research.ibm.com/publications/sequel-a-struciured-english-query-language'));
  for (let i = 1; i <= 29; i++) {
    const id = 'kapitel-' + String(i).padStart(2, '0');
    assert.ok(book.includes('href="#'+id+'"'),id+' link');
    assert.ok(book.includes('id="'+id+'"'),id+' target');
  }
  assert.ok(book.includes('href="#bok-forfattare"') && book.includes('id="bok-forfattare"'));
  assert.ok(book.includes('href="#bok-bilaga"') && book.includes('id="bok-bilaga"'));
  assert.ok(book.includes('href="#bok-bilaga-a"') && book.includes('id="bok-bilaga-a"'));
  assert.ok(book.indexOf('id="bok-bilaga-a"') < book.indexOf('id="bok-bilaga"'));
});

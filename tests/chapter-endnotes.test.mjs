import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { chapterEndnotes } from '../scripts/chapter-endnotes.mjs';
import { chapters, preparePrint } from '../scripts/book-content.mjs';

test('notes appear after their chapter, numbered and linked', () => {
  const source = '# Chapter\n\nText[^a] and more[^b].\n\n## Reflection\n\nA question.\n\n[^a]: First note.\n[^b]: Second note.';
  const out = chapterEndnotes(source, '03');
  assert.ok(out.includes('kapitel-03-not-1'));
  assert.ok(out.includes('kapitel-03-not-2'));
  assert.ok(out.indexOf('## Reflection') < out.indexOf('>Noter</h4>'));
  assert.ok(!out.includes('[^a]'));
});

test('chapters without footnotes do not get note sections', () => {
  assert.equal(chapterEndnotes('# Chapter\n\nText', '01'), '# Chapter\n\nText');
});

test('print does not retain raw chapter footnote markers', () => {
  const withNotes = chapters().filter(x => /\[\^[^\]]+\]/.test(x.source));
  assert.ok(withNotes.length > 0);
  preparePrint();
  const book = readFileSync('dist/generated/book-sv.md', 'utf8');
  for (const chapter of withNotes) assert.ok(book.includes('kapitel-' + chapter.id + '-not-1'));
  assert.doesNotMatch(book, /\[\^[^\]]+\]/);
});

import { readdirSync, readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, basename } from 'node:path';
import { chapterEndnotes } from './chapter-endnotes.mjs';
import { expandPrintUrls } from './print-links.mjs';

export const chaptersDirectory = 'content/sv/chapters';
export function chapters() {
  return readdirSync(chaptersDirectory)
    .filter(name => /^\d{2}-.*\.md$/.test(name))
    .sort((a, b) => Number(a.slice(0, 2)) - Number(b.slice(0, 2)))
    .map(name => {
      const source = readFileSync(join(chaptersDirectory, name), 'utf8');
      const title = source.match(/^#\s+(.+)$/m)?.[1];
      if (!title) throw new Error('Saknad kapitelrubrik: ' + name);
      return { id: name.slice(0, 2), name, title, source,
        url: '/sv/chapters/' + basename(name, '.md') + '.html' };
    });
}

function formatPrintForeword(source) {
  // Bind closing paragraph and signature for reliable pagination.
  const closing = /(Jag hoppas att den här boken[^\n]+)\n\n\*Benjamin Berglund\*\s+\n\*Malmö, oktober 2026\*/;
  return source.replace(closing,
    (_, paragraph) => '<div class="book-foreword-closing"><p>' + paragraph +
      '</p><p class="book-foreword-signature"><em>Benjamin Berglund</em><br><em>Malmö, oktober 2026</em></p></div>');
}
export function preparePrint({ interiorOnly = false } = {}) {
  const items = chapters();
  if (items.length !== 29) throw new Error('Förväntade 29 kapitel, fann ' + items.length);
  mkdirSync('dist/generated', { recursive: true });
  const toc = [
    '<section class="book-print-toc">',
    '<h1>Innehåll</h1>',
    '<ol>',
    ...items.map(item => '<li><a href="#kapitel-' + item.id + '">' + item.title.replace(/^\d+\.\s*/, '').replace(/&/g, '&amp;').replace(/</g, '&lt;') + '</a></li>'),
    '</ol>',
    '<ul class="book-print-toc-appendices">',
    '<li><a href="#bok-bilaga-a">Bilaga A – Att planera och modellera en databas</a></li>',
    '<li><a href="#bok-bilaga">Bilaga B – Exempeldatabasen</a></li>',
    '<li><a href="#bok-referenser">Referenser och vidare läsning</a></li>',
    '</ul>',
    '</section>'
  ].join('\n');
  const sections = [
      '<section class="book-print-title-leaf" aria-label="Försättsblad"></section>',
      '<section class="book-print-copyright-leaf" aria-label="Upphovsrätt"></section>',
      ...(interiorOnly ? [] : [readFileSync('publishing/print/author.md', 'utf8').split('<div class="author-card">')[0].trim()]),
      toc,
      '<section class="book-print-author"><span id="bok-forfattare"></span><div class="author-card">' + readFileSync('publishing/print/author.md','utf8').split('<div class="author-card">')[1].trim() + '</section>',
      '<section class="book-print-foreword-section">\n' + formatPrintForeword(readFileSync('content/sv/forord.md', 'utf8').replace(/^---\n[\s\S]*?\n---\n/, '').replace(/<div class="book-foreword-marker"><\/div>/, '').replace(/\[Börja läsa – Kapitel 1\]\([^)]*\)/, '').trim().replace(/^# Förord/, '<h1 class="book-print-foreword" id="bok-forord">Förord</h1>')) + '\n</section>',
      ...items.map(item => chapterEndnotes(item.source, item.id).replace(/^# ([^\n]+)/, (_, title) => '<h1 id="kapitel-' + item.id + '">' + title.replace(/&/g, '&amp;').replace(/</g, '&lt;') + '</h1>')),
      readFileSync('content/sv/bilaga-a-databasmodellering.md', 'utf8').trim()
        .replace(/^# ([^\n]+)/, (_, title) => '<h1 id="bok-bilaga-a">' + title.replace(/&/g, '&amp;') + '</h1>')
        .replace(/!\[([^\]]*)\]\(\/images\/([^)]+)\)/g, '![$1](../../content/public/images/$2)'),
      readFileSync('publishing/print/appendix-database.md', 'utf8').trim().replace(/^# ([^\n]+)/, (_, title) => '<h1 id="bok-bilaga">' + title.replace(/&/g, '&amp;') + '</h1>'),
      readFileSync('content/sv/referenser.md', 'utf8').replace(/^---\n[\s\S]*?\n---\n/, '').trim().replace(/^# ([^\n]+)/, (_, title) => '<h1 id="bok-referenser">' + title.replace(/&/g, '&amp;') + '</h1>')
    ];
  writeFileSync(interiorOnly ? 'dist/generated/book-sv-publit.md' : 'dist/generated/book-sv.md',
    (interiorOnly ? sections.map(expandPrintUrls) : sections).join('\n\n') + '\n');
  return items;
}

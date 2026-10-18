import { readdirSync, readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, basename } from 'node:path';

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

export function preparePrint() {
  const items = chapters();
  if (items.length !== 29) throw new Error('Förväntade 29 kapitel, fann ' + items.length);
  mkdirSync('dist/generated', { recursive: true });
  const toc = [
    '<section class="book-print-toc">',
    '<h1>Innehåll</h1>',
    '<ol>',
    ...items.map(item => '<li><a href="#kapitel-' + item.id + '">' + item.title.replace(/&/g, '&amp;').replace(/</g, '&lt;') + '</a></li>'),
    '<li><a href="#bok-forfattare">Om författaren</a></li>',
    '<li><a href="#bok-bilaga-a">Bilaga A – Att planera och modellera en databas</a></li>',
    '<li><a href="#bok-bilaga">Bilaga B – Exempeldatabasen</a></li>',
    '</ol>',
    '</section>'
  ].join('\n');
  writeFileSync('dist/generated/book-sv.md',
    [
      readFileSync('publishing/print/author.md', 'utf8').split('<div class="author-card">')[0].trim(),
      toc,
      '<section class="book-print-author"><span id="bok-forfattare"></span><div class="author-card">' + readFileSync('publishing/print/author.md','utf8').split('<div class="author-card">')[1].trim() + '</section>',
      ...items.map(item => item.source.trim().replace(/^# ([^\n]+)/, (_, title) => '<h1 id="kapitel-' + item.id + '">' + title.replace(/&/g, '&amp;').replace(/</g, '&lt;') + '</h1>')),
      readFileSync('content/sv/bilaga-a-databasmodellering.md', 'utf8').trim()
        .replace(/^# ([^\n]+)/, (_, title) => '<h1 id="bok-bilaga-a">' + title.replace(/&/g, '&amp;') + '</h1>')
        .replace(/!\[([^\]]*)\]\(\/images\/([^)]+)\)/g, '![$1](../../content/public/images/$2)'),
      readFileSync('publishing/print/appendix-database.md', 'utf8').trim().replace(/^# ([^\n]+)/, (_, title) => '<h1 id="bok-bilaga">' + title.replace(/&/g, '&amp;') + '</h1>')
    ].join('\n\n') + '\n');
  return items;
}

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
    '<li><a href="#bok-bilaga">Bilaga – exempeldatabasen</a></li>',
    '</ol>',
    '</section>'
  ].join('\n');
  writeFileSync('dist/generated/book-sv.md',
    [
      readFileSync('publishing/print/author.md', 'utf8').trim(),
      toc,
      ...items.map(item => '<span id="kapitel-' + item.id + '"></span>\n\n' + item.source.trim()),
      '<span id="bok-bilaga"></span>\n\n' + readFileSync('publishing/print/appendix-database.md', 'utf8').trim()
    ].join('\n\n') + '\n');
  return items;
}

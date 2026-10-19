/**
 * Fotnoterna är skrivna i vanlig Markdown och fungerar separat per kapitelsida
 * på webben. PDF:en är en sammanfogad Markdown-fil, så vi materialiserar
 * kapitelvisa slutnoter för att undvika att allt hamnar sist i boken.
 */
export function chapterEndnotes(source, chapterId) {
  const definitions = new Map();
  const lines = source.split('\n');
  const kept = [];
  for (let i = 0; i < lines.length; i++) {
    const match = lines[i].match(/^\[\^([^\]]+)\]:\s*(.*)$/);
    if (!match) { kept.push(lines[i]); continue; }
    const parts = [match[2]];
    while (i + 1 < lines.length && /^(?: {4}|\t)\S/.test(lines[i + 1])) {
      parts.push(lines[++i].replace(/^(?: {4}|\t)/, ''));
    }
    definitions.set(match[1], parts.join(' '));
  }
  const numbering = new Map();
  const refCounts = new Map();
  let body = kept.join('\n').replace(/\[\^([^\]]+)\]/g, (whole, id) => {
    if (!definitions.has(id)) return whole;
    if (!numbering.has(id)) numbering.set(id, numbering.size + 1);
    const n = numbering.get(id);
    const count = (refCounts.get(id) || 0) + 1;
    refCounts.set(id, count);
    const root = 'kapitel-' + chapterId + '-not-' + n;
    return '<sup id="' + root + '-ref-' + count + '"><a href="#' + root + '">' + n + '</a></sup>';
  }).trim();
  if (numbering.size === 0) return body;
  const notes = [...numbering].map(([id, n]) => {
    const root = 'kapitel-' + chapterId + '-not-' + n;
    const back = '<a href="#' + root + '-ref-1" aria-label="Tillbaka till nothänvisningen">↩</a>';
    return n + '. <span id="' + root + '"></span>' + definitions.get(id) + ' ' + back;
  });
  return body + '\n\n<h4 class="book-chapter-endnotes">Noter</h4>\n\n' + notes.join('\n') + '\n';
}

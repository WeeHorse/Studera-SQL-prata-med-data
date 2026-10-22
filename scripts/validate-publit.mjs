import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const pdf = resolve(process.argv[2] || 'dist/print/studera-sql-publit-inlaga-a5.pdf');
const report = resolve(process.argv[3] || 'dist/print/publit-preflight.md');
const checks = [];
const expected = { width: 148 * 72 / 25.4, height: 210 * 72 / 25.4 };
function command(binary, args) {
  try {
    return execFileSync(binary, args, { encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
  } catch (error) {
    throw new Error(`${binary}: ${error.stderr?.toString().trim() || error.message}`);
  }
}
function check(name, pass, details = '') {
  checks.push({ name, pass, details });
  console.log(`${pass ? 'PASS' : 'FAIL'} ${name}${details ? ': ' + details : ''}`);
}
if (!existsSync(pdf)) {
  check('Input PDF exists', false, pdf);
} else {
  check('Input PDF exists', true);
  try {
    command('qpdf', ['--check', pdf]);
    check('PDF structure (qpdf)', true);
  } catch (error) { check('PDF structure (qpdf)', false, error.message); }

  try {
    const info = command('pdfinfo', [pdf]);
    const pages = Number(info.match(/^Pages:\s*(\d+)/m)?.[1]);
    check('Positive page count', Number.isInteger(pages) && pages > 0, String(pages || 'unknown'));
    if (pages > 0) {
      // Query one page at a time: pdfinfo's default summary concerns only page one.
      const bad = [];
      for (let p = 1; p <= pages; p++) {
        const pageInfo = command('pdfinfo', ['-f', String(p), '-l', String(p), '-box', pdf]);
        const match = pageInfo.match(new RegExp(`^Page\\s+${p}\\s+size:\\s*([\\d.]+)\\s+x\\s+([\\d.]+)\\s+pts`, 'm'));
        if (!match || Math.abs(Number(match[1]) - expected.width) > 0.5 ||
            Math.abs(Number(match[2]) - expected.height) > 0.5) bad.push(p);
      }
      check('Every page is portrait A5', bad.length === 0,
        bad.length ? `Unexpected or unreadable dimensions on pages: ${bad.slice(0, 30).join(', ')}` : `${pages} pages`);
    }
  } catch (error) { check('Page geometry (pdfinfo)', false, error.message); }

  try {
    const lines = command('pdffonts', [pdf]).trim().split('\n').slice(2).filter(Boolean);
    // pdffonts columns: name | type | encoding | emb | sub | uni | object ID.
    const unembedded = lines.filter(line => !/\s+yes\s+(?:yes|no)\s+(?:yes|no)\s+\d+\s+\d+\s*$/i.test(line));
    check('All listed fonts embedded', unembedded.length === 0,
      `${lines.length} fonts; ${unembedded.length} non-embedded or unreadable entries`);
  } catch (error) { check('Fonts (pdffonts)', false, error.message); }

  try {
    command('gs', ['-q', '-dBATCH', '-dNOPAUSE', '-sDEVICE=nullpage', pdf]);
    check('Ghostscript renders all pages', true);
  } catch (error) { check('Ghostscript renders all pages', false, error.message); }
}

const pending = [
  'PDF/X-4 conformance and output intent must be validated in dedicated software',
  'TrimBox/BleedBox, binding margins and print-safe placement',
  'Color/grayscale and image effective resolution for the selected product',
  'Visual inspection of code blocks, tables, diagrams, footnotes and page breaks',
  'Physical proof and separate cover using Publit’s exact template'
];
const lines = [
  '# Publit — preliminary preflight', '',
  `Input: \`${pdf}\``, '',
  `Generated: ${new Date().toISOString()}`, '',
  `Result: **${checks.every(c => c.pass) ? 'AUTOMATED CHECKS PASSED' : 'AUTOMATED CHECKS FAILED'}** (not print approval)`, '',
  '## Automated checks', '',
  ...checks.map(c => `- ${c.pass ? 'PASS' : '**FAIL**'} — ${c.name}${c.details ? ': ' + c.details : ''}`),
  '', '## Manual / specialist checks required', '',
  ...pending.map(x => `- [ ] ${x}`), '',
  '> Passing this report does not establish PDF/X-4 compliance or authorize printing.', ''
];
mkdirSync(dirname(report), { recursive: true });
writeFileSync(report, lines.join('\n'));
console.log('Preflight report:', report);
if (checks.some(c => !c.pass)) process.exitCode = 1;

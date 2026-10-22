import { execFileSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

const pdf = resolve(process.argv[2] || 'dist/print/studera-sql-publit-inlaga-a5.pdf');
const report = resolve(process.argv[3] || 'dist/print/publit-preflight.md');
const checks = [];
function cmd(name, args) {
  try { return execFileSync(name, args, { encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 }); }
  catch (e) { throw new Error(name + ' failed: ' + (e.stderr?.toString() || e.message)); }
}
function check(label, ok, detail) {
  checks.push({ label, ok, detail });
  console.log((ok ? 'PASS' : 'FAIL') + ' ' + label + (detail ? ': ' + detail : ''));
}
if (!existsSync(pdf)) throw new Error('Missing input PDF: ' + pdf);
let pdfInfo = '', fonts = '', gsInfo = '';
try {
  cmd('qpdf', ['--check', pdf]);
  check('PDF structural integrity (qpdf)', true);
} catch (e) { check('PDF structural integrity (qpdf)', false, e.message); }
try {
  pdfInfo = cmd('pdfinfo', ['-box', pdf]);
  const count = Number(pdfInfo.match(/^Pages:\s+(\d+)/m)?.[1]);
  check('Page count', count > 0, String(count || 'missing'));
  // Validate every page instead of trusting only page 1.
  if (count > 0) {
    const all = cmd('pdfinfo', ['-f', '1', '-l', String(count), '-box', pdf]);
    const media = [...all.matchAll(/Page\s+\d+\s+size:\s+([\d.]+)\s+x\s+([\d.]+)\s+pts/g)];
    const dimsOk = media.length === count && media.every(m => Math.abs(Number(m[1]) - 419.5276) < 1 && Math.abs(Number(m[2]) - 595.2756) < 1);
    check('All pages are A5 portrait (148 × 210 mm)', dimsOk, media.length + '/' + count + ' measured');
  }
} catch (e) { check('PDF page metadata (pdfinfo)', false, e.message); }
try {
  fonts = cmd('pdffonts', [pdf]);
  const lines = fonts.trim().split('\n').slice(2).filter(Boolean);
  const notEmbedded = lines.filter(line => !/\s+yes\s+(?:yes|no)\s+/i.test(line));
  check('Fonts embedded', notEmbedded.length === 0, lines.length + ' listed; ' + notEmbedded.length + ' suspicious');
} catch (e) { check('Font inspection (pdffonts)', false, e.message); }
try {
  gsInfo = cmd('gs', ['-q', '-dBATCH', '-dNOPAUSE', '-sDEVICE=nullpage', pdf]);
  check('Ghostscript raster parse', true);
} catch (e) { check('Ghostscript raster parse', false, e.message); }
const mustReview = [
  'PDF/X-4 compliance and valid output intent (NOT verified by this script)',
  'Bleed/TrimBox and binding safety margins',
  'Color/grayscale suitability for chosen Publit product',
  'Visual review: code, tables, ER diagrams, footnotes and pagination',
  'Proof copy and final cover using Publit template'
];
const md = [
  '# Publit — preliminary preflight', '',
  'Input: \x60' + pdf + '\x60', '',
  'Generated: ' + new Date().toISOString(), '',
  '## Automated checks', '',
  ...checks.map(c => '- ' + (c.ok ? 'PASS' : '**FAIL**') + ' — ' + c.label + (c.detail ? ': ' + c.detail : '')),
  '', '## Manual / specialist checks still required', '',
  ...mustReview.map(s => '- [ ] ' + s), '',
  '> These checks do NOT certify PDF/X-4 and do not authorize printing.', ''
].join('\n');
mkdirSync(resolve(report, '..'), { recursive: true });
writeFileSync(report, md);
console.log('Report: ' + report);
if (checks.some(c => !c.ok)) process.exitCode = 1;

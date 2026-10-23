import { execFileSync } from 'node:child_process';
import { preparePrint } from './book-content.mjs';

const chapters = preparePrint({ interiorOnly: true });
console.log('Bygger omslagsfri Publit-inlaga (A5),', chapters.length, 'kapitel.');
execFileSync(process.platform === 'win32' ? 'npx.cmd' : 'npx',
  ['vivliostyle', 'build', '-c', 'publishing/print/publit.config.mjs'],
  { stdio: 'inherit' });
console.log('Skapad: dist/print/studera-sql-publit-inlaga-a5.pdf');
console.log('OBS: Filen måste verifieras och konverteras till giltig PDF/X-4 före uppladdning.');

import { execFileSync } from 'node:child_process';
import { preparePrint } from './book-content.mjs';

const chapters = preparePrint();
console.log('Bygger svensk A5-bok med', chapters.length, 'kapitel.');
execFileSync(process.platform === 'win32' ? 'npx.cmd' : 'npx',
  ['vivliostyle', 'build', '-c', 'publishing/print/vivliostyle.config.mjs'],
  { stdio: 'inherit' });

import { defineConfig } from 'vitepress';
import { chapters } from '../scripts/book-content.mjs';

const sidebar = chapters().map(({ title, url }) => ({ text: title, link: url }));

// Root for local preview; GitHub Pages deploys this repository beneath /Studera-SQL-prata-med-data/.
const base = process.env.PAGES_BASE || '/';

export default defineConfig({
  title: 'Studera SQL – prata med data',
  description: 'SQL, relationella databaser och informationshantering',
  base,
  srcDir: 'content',
  outDir: '.vitepress/dist',
  cleanUrls: false,
  locales: {
    root: { label: 'Start', lang: 'sv-SE' },
    sv: {
      label: 'Svenska',
      lang: 'sv-SE',
      themeConfig: {
        nav: [{ text: 'Start', link: '/sv/' }, { text: 'Kapitel 1', link: '/sv/chapters/01-vad-ar-en-databas.html' }, { text: 'Bilaga: exempeldatabas', link: '/sv/bilaga-exempeldatabas.html' }],
        sidebar
      }
    }
  },
  themeConfig: { search: { provider: 'local' } }
});

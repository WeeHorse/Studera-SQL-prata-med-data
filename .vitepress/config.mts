import { defineConfig } from 'vitepress';
import { chapters } from '../scripts/book-content.mjs';

const sidebar = chapters().map(({ title, url }) => ({ text: title, link: url }));

export default defineConfig({
  title: 'Studera SQL – prata med data',
  description: 'SQL, relationella databaser och informationshantering',
  srcDir: 'content',
  outDir: '.vitepress/dist',
  cleanUrls: false,
  locales: {
    root: { label: 'Start', lang: 'sv-SE' },
    sv: {
      label: 'Svenska',
      lang: 'sv-SE',
      themeConfig: {
        nav: [{ text: 'Start', link: '/sv/' }],
        sidebar
      }
    }
  },
  themeConfig: { search: { provider: 'local' } }
});

import { defineConfig } from 'vitepress';

export default defineConfig({
  title: 'Studera SQL – prata med data',
  description: 'SQL, relationella databaser och informationshantering',
  srcDir: 'content',
  outDir: '.vitepress/dist',
  // Explicit .html URLs also work on simple static file servers.
  cleanUrls: false,
  locales: {
    root: { label: 'Start', lang: 'sv-SE' },
    sv: {
      label: 'Svenska',
      lang: 'sv-SE',
      themeConfig: {
        nav: [{ text: 'Start', link: '/sv/' }],
        sidebar: [{ text: 'Kapitel 1 – Vad är en databas?', link: '/sv/chapters/01-vad-ar-en-databas' }]
      }
    }
  },
  themeConfig: {
    search: { provider: 'local' }
  }
});

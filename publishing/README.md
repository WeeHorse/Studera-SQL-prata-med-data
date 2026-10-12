# Publicering av den svenska boken

Samtliga 29 svenska kapitel finns nu både i ursprungliga `chapters/` och i `content/sv/chapters/`, som används för publicering. Originalen har **inte** tagits bort. Kopiornas innehåll kontrolleras mot originalen i testerna.

## Lokalt

Kräver Node.js 22.

```bash
npm install
npm test
npm run dev:web
npm run build:web
npm run preview:web
npm run build:pdf
```

VitePress visar automatiskt innehållsförteckningen från de svenska Markdown-filerna. PDF-bygget sammanfogar samma Markdown-kapitel i nummerordning till `dist/generated/book-sv.md` och producerar `dist/print/studera-sql-sv-a5.pdf`. Slutresultatet är en A5-läs-PDF, **inte tryckarksutskjutning**.

Förhandsgranska det genererade webbresultatet via `npm run preview:web`, normalt http://localhost:4173/. Öppna inte HTML-filer direkt via `file://`.

## Fortsatt arbete

- Visuell kontroll av hela PDF:en: sidbrytningar, tabeller, kodblock, innehållsförteckning och sidnummer.
- Beslut om att göra `content/sv/` till enda redaktionella källan. Så länge dubbla filer finns måste de hållas synkroniserade.
- Engelsk redaktionell översättning och terminologisäker automatöversättning.
- GitHub Pages `base` och separat publiceringsflöde när mål-URL är vald.

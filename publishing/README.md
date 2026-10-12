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

## GitHub Pages

Webb och PDF publiceras automatiskt från `main` av `.github/workflows/publishing-pilot.yml`, efter lyckade tester och båda byggena. En Pull Request verifierar byggena men publicerar inte.

**En gång i GitHub:** Repository → Settings → Pages → Build and deployment → Source: **GitHub Actions**. Om Pages kräver godkännande eller miljöinställning, använd miljön `github-pages`.

Webbadress (för standarddomänen): https://weehorse.github.io/Studera-SQL-prata-med-data/

PDF: https://weehorse.github.io/Studera-SQL-prata-med-data/downloads/studera-sql-sv-a5.pdf

Bygget sätter `PAGES_BASE=/Studera-SQL-prata-med-data/` för rätt resurssökvägar. Lokalt är `PAGES_BASE` normalt tomt och VitePress använder `/`. För att testa GitHub Pages-strukturen lokalt kan du köra `PAGES_BASE=/Studera-SQL-prata-med-data/ npm run build:web`, men servern måste då också tillhandahålla sidan under motsvarande underkatalog.

PDF skapas från Markdown, kopieras till `.vitepress/dist/downloads/` och ingår alltså i samma Pages-artifact som HTML, CSS och JavaScript. Byggresultat ska inte checkas in i Git.

**Viktigt:** GitHub Pages är i standardfallet en **publik** webbplats. Lägg inte upp manus eller material där som måste hållas internt eller konfidentiellt.

**Beroende:** Den här Pages-PR:en baseras på `infra/full-swedish-book-build` (PR #34). Mergas först PR #34 till `main` och därefter Pages-ändringarna, så publiceras hela boken och inte pilotkapitlet.

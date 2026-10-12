# Publiceringspilot

Det här är en **icke-destruktiv pilot**. Befintliga filer under `chapters/` ligger kvar tills migreringen har verifierats. Kapitel 1 kopieras till `content/sv/chapters/`.

## Lokalt

- Node.js 22
- `npm install`
- `npm test`
- `npm run dev:web` för utveckling direkt från Markdown
- `npm run build:web` för att bygga webbplatsen
- `npm run preview:web` för att öppna det **byggda** resultatet via VitePress lokala server (standardport 4173)
- `npm run build:pdf` för A5-PDF

Vivliostyle kan behöva installera eller hitta en Chromium-miljö; första PDF-bygget kan därför kräva extra installation på en ny dator.

## Webbens sökvägar

Öppna **inte** `.vitepress/dist/index.html` direkt som en fil. Använd inte heller VS Code Live Server från projektroten för att testa byggresultatet. VitePress genererar absoluta resurssökvägar räknat från webbplatsens rot och behöver serveras från rätt plats.

Kör:

```bash
npm run build:web
npm run preview:web
```

Besök sedan adressen som VitePress skriver ut, normalt `http://localhost:4173/`. Kontrollera också `/sv/` och länken till kapitel 1.

Vi använder nu vanliga `.html`-adresser i det genererade resultatet, i stället för `cleanUrls`, så att de också är enklare att servera med en enklare statisk webbserver. Publicering på GitHub Pages under en **underkatalog** kräver senare ett uttryckligt `base`-värde för repots namn; piloten är tills vidare byggd för domänens rot.

## Begränsningar

- Endast ett svenskt pilotkapitel är inkopplat.
- Ingen översättning körs än. Engelska och övriga språk läggs till efter testad källstruktur.
- Ingen extern webbpublicering är aktiverad; CI laddar upp byggartefakter.
- A5-PDF i läsordning är **inte** färdig tryckarksutskjutning eller certifierad tryckerifil.
- Kontrollera CI-resultat och PDF-layout innan pilotens funktioner betraktas som godkända.

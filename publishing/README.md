# Publiceringspilot

Det här är en **icke-destruktiv pilot**. Befintliga filer under `chapters/` ligger kvar tills migreringen har verifierats. Kapitel 1 kopieras till `content/sv/chapters/`.

## Lokalt

- Node.js 22
- `npm install`
- `npm test`
- `npm run dev:web` för förhandsgranskning
- `npm run build:web` för webb
- `npm run build:pdf` för A5-PDF

Vivliostyle kan behöva installera eller hitta en Chromium-miljö; första PDF-bygget kan därför kräva extra installation på en ny dator.

## Begränsningar

- Endast ett svenskt pilotkapitel är inkopplat.
- Ingen översättning körs än. Engelska och övriga språk läggs till efter testad källstruktur.
- Ingen extern webbpublicering är aktiverad; CI laddar upp byggartefakter.
- A5-PDF i läsordning är **inte** färdig tryckarksutskjutning eller certifierad tryckerifil.
- Kontrollera CI-resultat och PDF-layout innan pilotens funktioner betraktas som godkända.

# Publit – tryckutgåva av *Studera SQL – Prata med data*

## Två filer, skilda från webbpubliceringen

- **Inlaga**: `dist/print/studera-sql-publit-inlaga-a5.pdf`. A5 (148 × 210 mm), enkelsidor, utan framsidesomslaget. Byggs från samma manus som webb och läs-PDF.
- **Omslag**: en framtida **separat**, sammanhängande PDF: baksida + rygg + framsida, baserat på Publits **exakta omslagsmall**. Ingen omslagsfil är ännu producerad.

Det vanliga kommandot `npm run build:pdf` och den publicerade läs-PDF:en påverkas inte.

## Bygg inlagan

```sh
npm ci
npm run build:publit
```

GitHub Actions bygger dessutom inlagan vid varje PR och lägger den i artifact `book-web-and-a5-pdf` (laddas ned från körningens sida under Actions).

## Tryckspecifikation och kontroll före uppladdning

Publits instruktioner:
- [Publit – Printed Books / Print Guide](https://get.publit.com/en#printed-books_print-guide)
- [Publit – PDF-inställningar](https://intercom.help/publit/sv/articles/6550965-pdf-installningar)
- [Publit – Skapa inlaga](https://intercom.help/publit/sv/articles/2850531-skapa-bokens-inlaga-i-indesign)

**Viktigt:** Vivliostyles PDF är **ett inlageoriginal, inte automatiskt en Publit-godkänd tryckfil**.

Kontrollera följande innan uppladdning:

1. Sidformat: varje sida exakt **148 × 210 mm**; **enkelsidor**, inga uppslag.
2. Första sidan: innehållsförteckningen (bokomslaget ska inte ligga i inlagan). Författarsida och förord följer sedan enligt innehållsförteckningen.
3. Säkerhetsmarginaler: inga tabeller, sidnummer eller diagram i skärnings- eller bindningszon.
4. Kontrollera för vald produkttyp/papperssort: svartvit/gråskaleinlaga eller färginlaga. Vektorillustrationer kan ge bra skärpa, men bildfiler behöver tillräcklig faktisk upplösning.
5. **PDF/X-4**: konvertera med korrekt tryckverktyg/profil och verifiera tekniskt; inbäddade teckensnitt, korrekta färgprofiler/CMYK för färgbilder, inga otillåtna lager eller transparenser enligt Publits gällande preflight. **Märk inte en vanlig PDF som PDF/X-4 utan validering.**
6. Begär och inspektera Publits provtryck. Notera sidantal från den färdiga inlagan; det avgör **ryggbredden**.
7. Om inlagan ska ha utfallande bilder/grafik: projektera **5 mm utfall** där det behövs. Nuvarande inlaga är utformad utan utfallande innehåll; lägg inte på godtyckligt utfall på alla sidor.
8. Omslaget kräver Publits nedladdade mall efter att sidantal, papper och bindning valts. Mallen avgör ryggbredd, TrimBox och **5 mm utfall**. Placera ISBN/EAN på avsedd plats.

### Rekommenderade lokala kontroller

```sh
pdfinfo dist/print/studera-sql-publit-inlaga-a5.pdf
pdffonts dist/print/studera-sql-publit-inlaga-a5.pdf
```

Öppna även PDF:en visuellt i sidordning. Först efter PDF/X-4-konvertering och validering ska originalet användas som slutlig uppladdningsfil. Spara både källfiler och det validerade originalet för spårbarhet.

## Omslaget

Behåll SEQUEL-inspirerad framsida och skapa baksida/rygg efter Publits mall; avvakta med slutlig layout tills sidantal och materialval är låsta. Även en ny version av inlagan kan ändra ryggbredden.

# Blockvis SQL-verifiering, omgång 2: kapitel 8–14

Fortsättning på `quality/sql-verification-early-chapters.md`. Den här omgången utökar befintliga MySQL-integrationstester med exakta resultatkontroller och isolerade modelltester.

| Kapitel | Kontroll | Förutsättning |
|---|---|---|
| 8 – Aggregering | Lagervärden, lager per typ, `WHERE` och `HAVING` | Grunddata |
| 9 – JOIN | `INNER`, `LEFT` och `CROSS JOIN`, filter i `ON` respektive `WHERE`, orderrelation | Grunddata |
| 10 – Subqueries | `EXISTS`, `NOT EXISTS`, jämförelse med genomsnittet inom produkttyp | Grunddata |
| 11 – Mängdoperationer | `UNION` på grunddata; `UNION`, `INTERSECT` och `EXCEPT` mot särskild illustrationsfixtur från tidigare omgång | Grunddata + tidigare testfixtur |
| 12–13 – Struktur och nycklar | `CREATE TABLE`, `DEFAULT`, `CHECK`, `UNIQUE` och främmande nyckel | Separata testtabeller |
| 14 – Normalisering | Kopplingstabell med ordning och constraints på författarrelation | Separat testtabell |

## Slutsatser och avgränsning

Den tidigare kontrollen av kapitel 11 omfattade tre **extra adresser** som boken uttryckligen tillför i sitt exempel. Att köra de frågorna direkt mot nedladdningsfilens fyra adresser skulle ge annorlunda resultat. Den skillnaden är därför avsiktlig och bevaras.

Vi kräver ingen bestämd radordning utan uttrycklig sortering. Vi testar heller inte att avsiktligt ogiltiga eller kontextlösa SQL-fragment ska fungera fristående. Schemaexemplen i kapitel 12–14 skapar tabeller som redan finns i grunddatabasen; testsviten använder därför egna namn och verifierar deras regler, i stället för att försöka skapa om grundtabellerna.

Denna PR utökar täckningen, men **är inte ett bevis på att samtliga 8–14:s SQL-block har exekverats ordagrant**. Efter att alla omgångar godkänts återstår att stämma av varje blockstatus i inventeringen.

Nya tester är ännu inte körda här. Kontrollera MySQL-jobbet i GitHub Actions innan merge.

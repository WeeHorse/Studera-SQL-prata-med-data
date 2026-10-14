# Slutgranskning – begrepp och pedagogisk konsekvens

Datum: 2026-10-14. Omfattning: **samtliga 29 svenska publiceringskapitel** i `content/sv/chapters/`. Detta är en **redaktionell genomgång av kapitelstruktur, begreppsintroduktion, kapitelhänvisningar och didaktisk progression**, inte en fullständig korrekturläsning rad för rad och inte heller ett exekveringstest av samtliga SQL-exempel.

## Övergripande bedömning

**Ingen större omdisponering rekommenderas.** Progressionen går från information och relationer (1–2), SQL:s grundläggande uttryck (3–8), kombinationer och underfrågor (9–11), schema/modell/ändringar (12–16), återanvändning och analysfunktioner (17–19), transaktioner/prestanda/applikationer (20–22) till kvalitet, säkerhet, analysplattformar, specialiserade datatyper och systemval (23–29). De reflekterande avsnitten om representation, modeller, data och verklighet ger boken ett tydligt sammanhang och bör behållas.

## Kapitelvis genomgång

| Kapitel | Pedagogisk funktion | Bedömning |
|---|---|---|
| 1 | Databasen och information som modell | Välplacerad introduktion |
| 2 | Entiteter, attribut, relationer, kardinalitet | Lägger grund för senare nycklar/normalisering |
| 3 | Första Queryn, SQL-satser och dialekter | Viktig terminologisk grund |
| 4 | Typer, värden, NULL | Ligger före filtrering och beräkningar |
| 5 | SELECT, WHERE, sortering och urval | Tydlig progression |
| 6 | Uttryck, funktioner och CASE | Bygger på urvalet |
| 7 | Datum, klockslag och tid | Kommer före grupperade tidsfrågor |
| 8 | Aggregat, GROUP BY, HAVING | Rätt förutsättning för senare JOIN/subqueries |
| 9 | JOIN, radmångfald och relationer | Förklarar viktigt skifte i vad en resultatrad betyder |
| 10 | Subqueries och korrelation | En felaktig bakåthänvisning till HAVING har rättats |
| 11 | UNION/INTERSECT/EXCEPT | Bra kontrast mot JOIN och subqueries |
| 12 | CREATE TABLE, typer och constraints | Övergår från logisk modell till struktur |
| 13 | Primär- och främmande nycklar | Konkretiserar samband från kapitel 2 |
| 14 | Normalformer och beroenden | Rätt placerat efter nycklar |
| 15 | INSERT, UPDATE, DELETE och historik | Separat datamanipulation efter datamodell |
| 16 | ALTER, migrationer och gränssnitt | Förhandsvisar View och hänvisar uttryckligen till kapitel 17 |
| 17 | Views och logiska representationer | Naturlig fortsättning på migrering |
| 18 | CTE och rekursiva steg | Bygger på Views och subqueries |
| 19 | Fönsterfunktioner och radnivå | Bra kontrast mot kapitel 8 |
| 20 | Transaktioner och samtidighet | Ger principer före applikationsanrop |
| 21 | Index och planering | Prestanda efter funktionell SQL |
| 22 | Applikationsåtkomst, parametrisering, ORM | Konkretiserar tidigare transaktioner |
| 23 | Rättigheter och informationssäkerhet | Utvidgar applikationssäkerheten |
| 24 | Datakvalitet och tillförlitlighet | Binder ihop constraints, mätning och ansvar |
| 25 | Analys och dataplattformar | Utvidgar operativa data till analys |
| 26 | JSON och semistrukturerade data | Bygger på ETL/ELT från kapitel 25 |
| 27 | Geografiska datatyper | Specialfall med explicit koppling till index och integritet |
| 28 | SQL-system, dialekter och systemval | Sammanfattar tidigare dialektskillnader |
| 29 | Databasens och modellens gränser | Sammanhållande avslutning |

## Begreppspolicy för slutredigering och översättning

- **Query / Queries:** använd som boktextens namn för en SQL-fråga som producerar ett resultat. En vanlig svensk fråga i naturligt språk behöver inte automatiskt skrivas som `Query`.
- **SQL-sats:** det bredare begreppet för en instruktion såsom `SELECT`, `INSERT`, `UPDATE` eller `CREATE TABLE`. `Statement` kan ges som engelsk motsvarighet, inte användas växelvis av stilskäl.
- **Subquery / underfråga:** presentera båda vid introduktionen, därefter håll samma huvudterm inom ett avsnitt.
- **View / vy:** presentera båda och skilj konsekvent mellan sparad definition och lagrade tabellrader.
- **CTE:** namngivet mellanresultat inom en SQL-sats, inte en permanent tabell och inte nödvändigtvis fysiskt materialiserat.
- **Relation / samband:** uppmärksamma skillnaden mellan relation i relationsmodellens formella språk och en koppling mellan entiteter. Behåll nyanseringen från kapitel 2.
- **NULL:** avsaknad av värde; varken tom sträng, noll eller ett eget sanningsvärde. Kapitel 4 och 5 behöver fortsatt läsas i samband.
- **Datakvalitet:** använd **konsekvens** för att beskriva motsägelsefrihet mellan data; vid behov ange `consistency` på engelska. Håll isär korrekthet, giltighet, fullständighet och aktualitet.

## Konkreta iakttagelser och beslut

1. **Åtgärdat i denna PR:** Kapitel 10 sade att `HAVING` introducerades i ”föregående kapitel” (kapitel 9). Det introduceras i **kapitel 8**. Hänvisningen har preciserats.
2. **Behåll avsiktlig framåtblick:** Kapitel 16 visar en View före View-kapitlet, men markerar att fördjupningen kommer i kapitel 17. Detta fungerar som en motiverande förhandsvisning.
3. **Behåll avsiktlig jämförelse:** Kapitel 10 nämner CTE som senare alternativ och introducerar begreppet fullt ut i kapitel 18. Det är en övergång, inte ett definitionsfel.
4. **Pedagogisk rekommendation:** Vid nästa revidering kan kapitel där `product_types`, `product_authors` eller `orders` tillkommer markera ännu tydligare vilka SQL-exempel som är fristående och vilka som bygger på nedladdningsdatabasen. Detta är primärt en fråga för den tekniska, exekverbara genomgången.
5. **Undvik automatisk ordlikriktning:** Skillnaden mellan ett naturligt språkligt ”fråga” och det tekniska `Query` är avsiktlig; en global sök/ersätt skulle försämra läsbarheten.
6. **Separat kontroll återstår:** Exakta resultat och SQL-dialektskillnader i samtliga exempel verifieras inom den tekniska testfasen, inte av denna konceptuella granskning.

## Slutsats

**Begrepps- och progressionsgranskningen kan avslutas utan större omstrukturering.** En saklig bakåthänvisning rättas i denna PR. Övriga identifierade områden är redaktionella bevakningspunkter för nästa korrektur eller den tekniska SQL-granskningen, inte blockerande pedagogiska motsägelser.

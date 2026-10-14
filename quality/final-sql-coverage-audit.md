# SQL-exempel – sista täckningsinventeringen

Datum: 2026-10-14. Omfattning: de 29 svenska manuskriptkapitlen i `content/sv/chapters/`.

Detta är en **statisk inventering av SQL-kodblock och kvarvarande risker**, inte ett påstående om att alla kodblock har körts. Kodblock har räknats efter språkmarkören `sql` i Markdown, oavsett om de är kompletta frågor, syntaxfragment eller illustrationer av fel. Det finns sammanlagt **242 SQL-kodblock**.

## Antal SQL-kodblock per kapitel

| Kapitel | Antal | Kapitel | Antal | Kapitel | Antal |
|---|---:|---|---:|---|---:|
| 01 | 1 | 11 | 9 | 21 | 16 |
| 02 | 0 | 12 | 9 | 22 | 0 |
| 03 | 9 | 13 | 8 | 23 | 9 |
| 04 | 3 | 14 | 3 | 24 | 9 |
| 05 | 12 | 15 | 19 | 25 | 5 |
| 06 | 14 | 16 | 10 | 26 | 7 |
| 07 | 11 | 17 | 10 | 27 | 11 |
| 08 | 13 | 18 | 7 | 28 | 5 |
| 09 | 10 | 19 | 10 | 29 | 4 |
| 10 | 13 | 20 | 5 | — | — |
| **Summa 01–10** | **86** | **11–20** | **90** | **21–29** | **66** |

Totalt **242 block**. Kapitel 02 och 22 saknar språkmarkerade `sql`-block; kapitel 22 använder applikationsexempel, som behöver en annan typ av test.

## Testad funktionalitet hittills

MySQL Actions verifierar representativa fall ur urval, filtrering, aggregering, relationer, subqueries, mängdoperationer, CTE, Views, fönsterfunktioner, DML/DDL, integritetsregler, transaktioner, index/`EXPLAIN`, analytisk SQL, JSON och geodata. Kontrollerna jämför faktiska databasresultat, men ska **inte likställas med att varje SQL-block är testat**.

## Konkreta korrigeringar

I kapitel 1 efterfrågades `city` direkt ur `customers`. Vår exempeldatabas lagrar orten i `addresses`. Det första SQL-exemplet är nu en **enkel fråga mot `addresses`**, med anpassad inledning så att eleverna inte behöver känna till `JOIN` innan den introducerats. Ett regressionstest har lagts till i MySQL-sviten.

## Återstående tekniska risker, prioriterade

| Prioritet | Kapitel | Risk och rekommenderad nästa kontroll |
|---|---|---|
| Hög | 03–10, 12–19 | Jämför **varje utlovad resultattabell** mot körning med rätt fixtur, och kontrollera att SQL-fragment/avsiktliga fel är markerade som sådana |
| Hög | 07 | Exempel med `registered_at` och `reservations` är hypotetiska, och ska inte presenteras som direkt körbara på grunddatabasen |
| Hög | 17–18 | Vissa exempel kräver en tidigare definierad View eller CTE; enstaka utdrag är inte fristående körbara |
| Hög | 23 | `CREATE USER`, `GRANT` och `REVOKE` bygger på användare och schema som inte finns i den nedladdningsbara grunddatabasen; granska säkerhet, privilegier och dialekt i separat isolerad miljö |
| Medel | 24 | Kvalitetsfrågor som jämför registrerade uppgifter med referensdata behöver ett explicit referensunderlag |
| Medel | 25 | Illustrativa orderrader skiljer sig från nedladdningsbar startdata; detta har förtydligats och särskild fixtur testas |
| Medel | 26 | Fördjupa testfall för saknade JSON-egenskaper, JSON `null` och SQL `NULL` |
| Medel | 27 | Testa `ST_Contains` med en explicit polygon-`delivery_areas`-fixtur och beteende på polygonens gräns |
| Medel | 28 | Två SQL Server-specifika syntaxexempel (`OFFSET ... FETCH` och `TOP`) ska inte köras av MySQL-testerna; kontrollera dem separat för den angivna dialekten |
| Medel | 29 | `CHECK`-utdrag är kodfragment, inte fristående SQL-satser |
| Låg | 21 | Vi kan verifiera att `EXPLAIN` kan köras, men inte kräva samma exekveringsplan för olika MySQL-versioner, statistik och tabellstorlekar |

## Metod för att avsluta kodverifieringen

1. Registrera varje block med **kapitel + ordningsnummer + kategori**: körbar grunddatabas, utökad fixtur, tillståndsförändring, fristående hypotetisk modell, avsiktligt ogiltigt exempel, kodfragment eller främmande SQL-dialekt.
2. För kompletta MySQL-block: jämför faktisk körning med bokens påstående och utskrivna resultat. Kör tillståndsförändringar mot kopior/återställbar testdatabas.
3. För fragment och hypotetiska modeller: kontrollera att boken tydligt talar om vilka förutsättningar som gäller i stället för att försöka exekvera dem som kompletta program.
4. För andra dialekter och applikationskod: verifiera i respektive miljö eller märk kontrollen som ännu ej utförd.
5. Avsluta först när varje block har en verifierad status; behåll en mindre, representativ uppsättning som regressionstester i GitHub Actions.

**Bedömning:** MySQL-testsviten täcker de centrala SQL-mekanismerna väl, men en exakt block-för-block-verifiering återstår. Den tekniska slutkontrollen bör därför ännu inte markeras som färdig.

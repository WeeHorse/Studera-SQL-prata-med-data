# Blockvis verifiering: kapitel 22–29

Denna omgång kompletterar MySQL-integrationstesterna för de avslutande kapitlen.

| Kapitel | Kontroll och avgränsning |
|---|---|
| 22 – SQL från applikationer | Kodexempel för applikationer, inte SQL-kodblock. Kräver separat granskning/test av värdspråket. |
| 23 – Säkerhet och åtkomst | Skapande av användare, roller och GRANT/REVOKE kräver särskild behörighetsfixtur, och textens `bookstore`-schema skiljer sig från nedladdningsfilens `studera_sql_bokhandel`. Körs **inte** i destruktivt SQL-integrationstest. |
| 24 – Datakvalitet | SQL för NULL, negativa saldon, dubbletter, e-postfullständighet samt avvikelse från fiktiv godkänd prislista. |
| 25 – Analys | Orderberäkningar redan täckta i tidigare testomgång. |
| 26 – JSON | Tre särskilda fall: SQL NULL, saknad egenskap i JSON-objektet och explicit JSON null. |
| 27 – Geografiska data | Polygon med en punkt inuti och en punkt på gränsen; testar `ST_Contains` mot plana geometriska fixturer med SRID 0. WGS84-avstånd och spatialt index täcks tidigare. |
| 28 – SQL-system | Kör endast MySQL-kompatibla exempel. SQL Server-specifika `TOP` och `OFFSET ... FETCH` måste verifieras med SQL Server, inte förväntas fungera i MySQL. |
| 29 – Avslutande reflektion | Kontroll av historiskt orderradsvärde. CHECK-utdrag är syntaxfragment, inte hela satser. |

### Återstående kvalitetssäkring

Detta kompletterar den tekniska täckningen, men är inte bevis för att **alla** 242 SQL-kodblock har körts ordagrant. För en slutlig block-för-block-matris behöver vi dessutom märka varje block som direkt exekverat, testat med anpassad fixtur, hypotetiskt, avsiktligt ogiltigt, fragment eller annan dialekt.

**Viktigt:** Kontrollera MySQL Actions för PR före merge. Testerna har inte körts i en riktig MySQL-instans här. Detta testskript återställer databasen `studera_sql_bokhandel` destruktivt och ska endast köras i avskild testmiljö.

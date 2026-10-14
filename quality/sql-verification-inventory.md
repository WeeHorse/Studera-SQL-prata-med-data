# Teknisk SQL-inventering – genomförande

Startad 2026-10-14. **Denna fil dokumenterar den första verifieringsomgången**, inte att samtliga SQL-exempel är körda.

## Klassificering för varje SQL-kodblock

1. **Direkt körbar läsfråga:** `SELECT`/CTE/SET-operation på grunddatabasen.
2. **Körbar mot utökad fixtur:** kräver data eller tabeller som presenteras i kapitlet, exempelvis tre extra adresser i kapitel 11.
3. **Tillståndsförändrande exempel:** `INSERT`/`UPDATE`/`DELETE`/`ALTER`/`DROP`; måste testas på isolerad kopia, i transaktion när det är lämpligt.
4. **Avsiktligt fragment:** visar syntax, en kolumndefinition eller den ändrade avslutningen av en Query.
5. **Avsiktligt felaktigt/avvisat:** illustrerar säkerhet, regler eller felmeddelanden.
6. **Dialekt-/versionsbundet:** exempelvis MySQL `INTERSECT`/`EXCEPT` kräver **8.0.31 eller senare**; spatiala funktioner och JSON kräver separat verifiering.

## Kontrollomgång 1

| Kapitel | Testfall | Fixtur |
|---|---|---|
| 5, 8, 9, 10, 14, 18 | Tidigare grundläggande kontroller | Nedladdningsbar grunddatabas |
| 10 | Subquery med produkter dyrare än genomsnittet | Grunddatabas |
| 11 | UNION, UNION ALL, INTERSECT, EXCEPT | Isolerad `quality_test_addresses` med de tre extra adresserna från texten |
| 17 | View över produkter och produkttyper | Tillfällig `quality_test_product_overview` |
| 19 | ROW_NUMBER och AVG-fönster | Grunddatabas |
| 12–15 | CHECK, främmande nyckel och unik primärnyckel | Grunddatabas |

Testkörningen återställer testdatabasen. En separat temporär testtabell gör att kapitel 11 kan använda sina egna kompletterande data **utan att ändra den fil läsaren laddar ner**.

**Kvar att verifiera:** resten av kodblocken och deras förväntade tabellresultat, transaktionsfallen i 15 och 20, ändrad databasstruktur i 16, avancerade fönster och CTE:er i 18–19, index/explain i 21, applikationskod i 22, rättigheter och säkerhet i 23, analytiska Queries i 25, JSON i 26 och spatiala data i 27. Utöver detta ska språk-/versionsnoteringar kontrolleras.

## Redaktionsrättning i samma PR

I kapitel 8 stod att vi *lägger till en produkt*, men tabellen visade redan exakt grunddatabasens fem produkter. Formuleringen är nu korrigerad; inget exempel ändras.

## Testmiljö

MySQL 8.0-service på GitHub Actions. För säker kontroll av SET-operationerna behöver **8.0.31+** säkerställas (nuvarande workflow använder `mysql:8.0`, som hämtar en uppdaterad 8.0-version). Integrationstesterna är ännu inte exekverade för denna PR; kontrollera grön Actions-körning före merge.

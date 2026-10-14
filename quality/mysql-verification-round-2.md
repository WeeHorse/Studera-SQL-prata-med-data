# Kontrollomgång 2 – förändringar, transaktioner och index

Utökar MySQL-integrationstesterna med kapitel 12–16, 20 och 21.

- **DML och DDL:** `quality_test_products` skapas med `CREATE TABLE ... LIKE` och fylls från `products`. `INSERT`, `UPDATE`, `DELETE`, `ALTER TABLE`, kolumnbyte och en kompatibilitets-View kontrolleras där. Tabellen och vyn raderas efteråt.
- **Transaktioner:** `START TRANSACTION`/`UPDATE`/`ROLLBACK` och motsvarande `COMMIT` utförs inom **samma MySQL-klientanrop och anslutning**. Efter COMMIT återställs originalets lagersaldo explicit.
- **Index:** verifierar att vanliga respektive sammansatta index skapas. `EXPLAIN` körs för syntax och exekverbarhet; själva planvalet är avsiktligt *inte* låst i testet eftersom fem rader är för få för meningsfull prestandabedömning.
- **Integritetsregler:** befintliga tester för `CHECK`, främmande nycklar och primärnycklar fortsätter att gälla.

Observera att MySQL ofta gör implicit commit vid DDL. Tabellen som används för schemaändringar är därför separat från originaltabellerna.

**Avgränsning:** Testerna är ett kontrollerat urval ur kapitlen, inte exekvering av varje kodblock. Körs i GitHub Actions mot en separat MySQL-service. Bekräfta grönt workflow innan merge. Testskriptet återställer som tidigare hela `studera_sql_bokhandel` och får aldrig köras på en server med värdefulla data under det namnet.

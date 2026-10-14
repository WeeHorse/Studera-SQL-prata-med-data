# Blockvis SQL-kontroll, omgång 1: kapitel 3, 5–7

Denna omgång kompletterar den tidigare funktionsorienterade MySQL-testsviten med exempel och förväntade resultat från bokens tidiga kapitel.

- **Kapitel 3:** enkel SELECT, WHERE, alias, äldre syntax för att kombinera kunder och adresser.
- **Kapitel 5:** datumintervall, IN, LIKE, LIMIT, NULL och villkor med olika parentesering. De två AND/OR-varianterna kan råka få samma antal rader i den lilla grunddatabasen; testerna är därför ingen fullständig demonstration av skillnaden för alla möjliga data.
- **Kapitel 6:** aritmetik, ROUND, CONCAT, UPPER, REPLACE, CASE och COALESCE.
- **Kapitel 7:** fasta datumintervall och DATEDIFF; värden som beror på CURRENT_DATE/TIMESTAMP bör inte jämföras med ett hårdkodat dagsresultat.

## Begränsning

Detta är en fortsättning mot blockvis täckning, men ingen fullständig automatisk exekvering av varje bokblock. Vissa kontroller sätter en aggregation runt bokens fråga för att jämföra resultatet entydigt. Kapitel 7:s exempel med `registered_at` och `reservations` gäller uttryckligen hypotetiska tabeller och är inte tillgängliga i grunddatabasen. Kapitel 3:s syntaxmall (`table_name`/`column_name`) är inte körbar i befintlig databas.

**Verifiering:** de tillagda testerna är ännu inte körda i denna session. Kontrollera MySQL-jobbet i GitHub Actions före merge.

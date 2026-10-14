# Teknisk kontrollomgång 3 – analys, JSON och geografiska data

Datum: 2026-10-14. Denna omgång utökar det befintliga MySQL-integrationsskriptet med kontroller hämtade från kapitel 25–27.

## Kapitel 25 – analys

- Kontrollera faktisk grunddata: en historisk orderrad om 249.00 kr, daterad oktober 2026.
- Skapa en tillfällig View för grupperad försäljning per produkt.
- Skapa en separat tabell med de tre **illustrativa** orderraderna från kapitel 25; kontrollera att order 102 blir 480.00 kr.
- Förtydliga i kapitlet att illustrationen inte är samma sak som nedladdningsfilens ursprungliga data.

## Kapitel 26 – semistrukturerade data

- Testa `ALTER TABLE ... JSON`, JSON-extraktion, filtrering, `JSON_SET()`, genererad kolumn och index.
- Använd en kopia av `products` så att ordinarie schema och grunddata lämnas orörda.

## Kapitel 27 – geografiska data

- Testa `ST_Length()` på plana linjer utan geografiskt SRID.
- Testa WGS 84-punkt med `ST_GeomFromText(..., 4326, 'axis-order=long-lat')`, sfäriskt avstånd, närhetssökning och spatialt index.
- Lås **inte** ett exakt avstånd i meter mellan två olika positioner till en viss numerisk precision. Avstånd på samma geografiska punkt bör vara noll.

## Avgränsning

Detta är ett urval av körbara exempel. Exempel med `delivery_areas` och `ST_Contains`, fler JSON-nullfall samt vidare analys av tidszoner och möjliga dialektskillnader kvarstår för sista täckningsinventeringen.

Testerna körs av GitHub Actions mot MySQL 8.0. De har **inte körts i författarens branch vid dokumentationstillfället**: kontrollera att `mysql-examples` blir grönt innan merge. Testmiljön är destruktiv mot databasen `studera_sql_bokhandel` och får bara användas i en isolerad testserver.

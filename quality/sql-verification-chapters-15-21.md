# Blockvis SQL-verifiering, omgång 3: kapitel 15–21

Den här omgången kompletterar befintliga MySQL-integrationstester med ytterligare exempel och särskilda testdata.

| Kapitel | Ny verifiering | Testprincip |
|---|---|---|
| 15 | Flera kolumner i UPDATE, INSERT med DEFAULT, riktad DELETE | Kopia av produkter |
| 16 | Schemaändringar | Redan täckta i tidigare omgång; ingen onödig dubblering |
| 17 | View med filtrering på lager | Tillfällig View |
| 18 | CTE i flera steg, jämförelse mot medellagervärde, rekursiv CTE | Grunddata + tillfällig kategorihierarki |
| 19 | Löpande summa, LAG, topprodukt per produkttyp | Grunddata |
| 20 | Order + orderrad + lagerändring i samma transaktion, ROLLBACK | Samma MySQL-anslutning |
| 21 | Indexdefinition och EXPLAIN | Indexkontroll, utan låst planval |

**Viktig avgränsning:** `SELECT`-utdrag ur CTE:er i kapitel 18 är inte fristående utan föregående `WITH`. Den rekursiva SQL-frågan förutsätter också en separat `categories`-tabell, varför testet skapar en egen kategori-fixtur. `EXPLAIN` får välja olika planer beroende på data och databashanterarens optimerare.

Transaktionstestet återkallar samtliga förändringar och kontrollerar därefter att inga testorder finns kvar och att lagersaldot är oförändrat. Detta kräver att flera SQL-satser körs inom **en och samma anslutning**.

De nya fallen är ännu inte exekverade här. Kontrollera att MySQL-workflowen i GitHub Actions är grön innan merge. Fortsatt blockvis täckning och granskning av kapitel 22–29 återstår.

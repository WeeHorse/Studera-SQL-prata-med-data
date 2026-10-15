# 15. Att lägga till och förändra data

Hittills har vi skapat en modell för bokhandelns information. Vi har bestämt vad kunder, produkter och författare är, vilka uppgifter de har och hur de förhåller sig till varandra.

Men en bokhandel förändras hela tiden. Nya kunder registreras, produkter läggs till, priser justeras och vissa uppgifter behöver rättas.

Vi behöver därför kunna förändra **informationen i tabellerna**, utan att förändra själva tabellernas struktur. Samtidigt behöver vi förstå vilken verklig förändring varje instruktion representerar.

## Grund

### Att lägga till en rad med INSERT

Vi börjar med bokhandelns produkttyper. Tabellen har två rader:

**product_types**

| id | name |
|---|---|
| 1 | Roman |
| 2 | Novellsamling |

Vi vill lägga till en ny typ: Facklitteratur.

```sql
INSERT INTO product_types (id, name)
VALUES (3, 'Facklitteratur');
```

`INSERT INTO` anger vilken tabell vi vill lägga till data i. Inom parentes anger vi kolumnerna och efter `VALUES` anger vi motsvarande värden.

Nu innehåller tabellen också:

| id | name |
|---|---|
| 3 | Facklitteratur |

Vi har skapat **en ny rad**, inte en ny kolumn eller tabell.

### Att lägga till flera rader

Vi kan lägga till flera produkttyper i samma instruktion:

```sql
INSERT INTO product_types (id, name)
VALUES
    (4, 'Biografi'),
    (5, 'Barnbok');
```

Varje parentes beskriver en ny rad. Värdena måste motsvara kolumnerna i den ordning vi har angett dem.

### Att lägga till en produkt

Vi har också en tabell `products` med kolumnerna `id`, `title`, `price`, `stock` och `product_type_id`.

```sql
INSERT INTO products (
    id, title, price, stock, product_type_id
)
VALUES (
    6, 'Kunskapens vägar', 199.00, 8, 3
);
```

Nu har vi lagt till en produkt som tillhör produkttypen Facklitteratur.

Eftersom `product_type_id` är en främmande nyckel behöver produkttypen med `id = 3` redan finnas. Det är ett exempel på hur vår datamodell och dess regler påverkar vilka förändringar databasen tillåter.

### DEFAULT och värden vi utelämnar

När vi skapade `products` bestämde vi att `stock` har standardvärdet `0`:

```sql
stock INTEGER NOT NULL DEFAULT 0
```

Vi behöver därför inte ange lagersaldo när vi registrerar en produkt:

```sql
INSERT INTO products (
    id, title, price, product_type_id
)
VALUES (
    7, 'Om databaser', 225.00, 3
);
```

Den nya produkten får `stock = 0`.

Det är en viktig skillnad mellan att **utelämna en kolumn med ett standardvärde** och att uttryckligen ange värdet `NULL`.

`NULL` betyder att ett värde saknas, och en kolumn med `NOT NULL` tillåter inte det. Att en kolumn har `DEFAULT` gör inte `NULL` till ett giltigt värde.

### Att förändra befintliga data med UPDATE

Anta att bokhandeln får fem nya exemplar av `Vägen hem`. Det gamla lagersaldot är `12`.

Vi kan ändra det med `UPDATE`:

```sql
UPDATE products
SET stock = 17
WHERE id = 1;
```

`UPDATE` anger tabellen och `SET` beskriver det nya värdet. `WHERE` anger **vilka rader** som ska förändras.

Men vi behöver inte alltid känna till det nya värdet i förväg. Vi kan utgå från det gamla:

```sql
UPDATE products
SET stock = stock + 5
WHERE id = 1;
```

Det här skulle öka lagersaldot med fem utifrån det värde som finns när instruktionen utförs. **Kör alltså inte båda exemplen efter varandra** om syftet är att registrera en och samma leverans. Exemplen visar två alternativa sätt att göra uppdateringen.

### Att förändra flera kolumner

Vi kan ändra flera attribut samtidigt:

```sql
UPDATE products
SET
    price = 210.00,
    stock = 15
WHERE id = 1;
```

Här förändras både pris och lagersaldo på produkten med `id = 1`.

Vi bör välja `WHERE`-villkoret med omsorg. Primärnyckeln är ofta praktisk när vi avser en bestämd rad.

### Vad händer utan WHERE?

Betrakta detta:

```sql
UPDATE products
SET price = 100.00;
```

Här saknas `WHERE`.

Det betyder inte att databasen väljer en godtycklig produkt. Det betyder att **alla rader i tabellen uppdateras**.

Det kan förstås vara avsiktligt. Men om vi bara tänkt ändra priset på en produkt är det ett allvarligt misstag.

Ett enkelt arbetssätt är att först kontrollera urvalet:

```sql
SELECT id, title, price
FROM products
WHERE id = 1;
```

Och sedan använda samma villkor i uppdateringen.

### Att ta bort rader med DELETE

Om en produkt inte längre ska finnas kvar i vårt sortiment kan vi ta bort dess rad:

```sql
DELETE FROM products
WHERE id = 7;
```

`DELETE FROM` tar bort rader ur en tabell.

Precis som för `UPDATE` är `WHERE` avgörande:

```sql
DELETE FROM products;
```

Den senare instruktionen försöker ta bort **alla rader** i tabellen. Den tar däremot inte bort tabellens struktur.

Det skiljer `DELETE` från `DROP TABLE`, som vi mötte i föregående kapitel.

### Vilka förändringar är tillåtna?

Våra tidigare beslut om datatyper och begränsningar gäller också när vi skriver data.

Exempelvis ska denna instruktion nekas om vi har definierat `CHECK (stock >= 0)`:

```sql
UPDATE products
SET stock = -5
WHERE id = 1;
```

På samma sätt kan databasen neka en ändring som bryter mot en primärnyckel, en unikhetsregel eller en främmande nyckel.

Det är därför vi skapar **regler i datamodellen**, och inte bara kontroller i de program som använder databasen.

## Avancerat

### INSERT ... SELECT – skapa rader från ett annat resultat

Ibland vill vi inte skriva värdena manuellt. Vi vill lägga till rader utifrån en annan fråga.

Anta att vi har skapat en separat tabell för en sammanställning av produkter:

```sql
CREATE TABLE product_snapshot (
    product_id INTEGER,
    title VARCHAR(200),
    price DECIMAL(10, 2)
);
```

Vi kan fylla den med information från `products`:

```sql
INSERT INTO product_snapshot (
    product_id, title, price
)
SELECT id, title, price
FROM products
WHERE stock > 0;
```

Här är det `SELECT` som bestämmer vilka rader som läggs till. Det är ett exempel på hur vi kan återanvända våra tidigare kunskaper om urval och beräkningar när vi förändrar data.

Tabellen `product_snapshot` är bara ett fristående exempel. Vi inför den inte som en permanent del av bokhandelns grundmodell.

### Att kontrollera vad som förändrades

Efter en `UPDATE` eller `DELETE` vill vi ofta kontrollera hur många rader som faktiskt påverkades.

Många databasklienter visar antalet påverkade rader. Vissa SQL-dialekter kan dessutom returnera de förändrade raderna direkt, exempelvis med `RETURNING` eller `OUTPUT`.[^returning]

[^returning]: PostgreSQL och SQLite stöder `RETURNING` vid flera datamanipulerande satser, medan SQL Server har `OUTPUT`. Stöd och syntax varierar mellan databassystem och versioner.

Detta är särskilt användbart när ett program vill avgöra om en uppdatering verkligen hittade den avsedda posten.

### När information måste bevaras

Att ta bort en produkt ur det aktuella sortimentet betyder inte nödvändigtvis att vi bör radera all information om den.

Om produkten tidigare har sålts behöver vi kanske fortfarande kunna se vad kunden köpte.

Vi kan då skilja mellan:

- Att **radera** produktens rad ur databasen.
- Att **markera** produkten som inaktiv, exempelvis med en kolumn `is_active`.

Det senare kallas ibland *soft delete* eller logisk radering.

Men att markera något som inaktivt är inte automatiskt bättre än att radera det. Det påverkar hur vi skriver våra frågor, hur vi bevarar historik och vilka uppgifter vi faktiskt behöver spara.

### När ett pris förändras

Anta att en bok kostar 200 kronor när en kund beställer den.

Nästa vecka ändrar bokhandeln priset till 225 kronor.

```sql
UPDATE products
SET price = 225.00
WHERE id = 1;
```

Det är helt rimligt att produktens **aktuella pris** förändras.

Men om vi senare tittar på en gammal beställning måste vi fortfarande kunna veta vilket pris kunden faktiskt betalade.

Därför kan en orderrad behöva spara `unit_price` – priset som gällde vid just den beställningen.

Vi har alltså två olika sakförhållanden: produktens pris *nu* och den genomförda försäljningens pris *då*.

Att bevara båda är inte ett misslyckande med normaliseringen. Det är ett uttryck för att informationen betyder olika saker.

### Flera förändringar som hör ihop

Föreställ dig att en kund köper två exemplar av en bok.

Då kanske vi behöver både registrera beställningen och minska lagersaldot.

Vad händer om beställningen registreras, men uppdateringen av lagersaldot misslyckas?

Databaser kan hantera flera förändringar som en sammanhängande **transaktion**:

```sql
START TRANSACTION;

UPDATE products
SET stock = stock - 2
WHERE id = 1 AND stock >= 2;

-- Ytterligare förändringar som hör till köpet

COMMIT;
```

Det här är bara en illustration, **inte ett färdigt och säkert orderflöde**. Ett verkligt system måste bland annat kontrollera att uppdateringen påverkade rätt rad och hantera fel innan transaktionen avslutas.

Om något går fel kan vi i en pågående transaktion använda `ROLLBACK` i stället för `COMMIT` för att ångra de förändringar som hör till transaktionen.[^transactions]

[^transactions]: `START TRANSACTION` används i MySQL. Andra databassystem kan exempelvis använda `BEGIN`. Transaktionsstöd och exakt beteende beror också på databasens lagringsmotor och inställningar.

Vi går igenom transaktioner, samtidighet och isolering på djupet i kapitel 20.

### Samtidiga uppdateringar

Anta att två anställda samtidigt försöker ändra lagersaldot.

Om båda först läser värdet `12` och sedan skriver tillbaka var sitt uträknade resultat riskerar en av ändringarna att gå förlorad.

En instruktion som:

```sql
UPDATE products
SET stock = stock + 5
WHERE id = 1;
```

låter databasen utföra beräkningen på det lagrade värdet inom själva uppdateringen. Det är ofta bättre än att först läsa värdet i en applikation och sedan skicka tillbaka ett nytt tal.

Men även då behöver vi förstå transaktioner och samtidighet när flera operationer tillsammans ska vara korrekta.

### Att ändra data är att ändra ett påstående

När vi skriver:

```sql
UPDATE customers
SET email = 'olof.new@example.com'
WHERE id = 2;
```

byter vi inte bara några tecken i en tabell.

Vi förändrar vad databasen **påstår** om kunden Olof.

Det kan vara en rättelse av felaktig information, eller en korrekt beskrivning av att något faktiskt har förändrats.

Skillnaden kan spela roll om vi senare behöver förstå historiken. En korrigering och en verklig förändring är inte alltid samma sak, även om båda råkar använda `UPDATE`.

## Reflektion

1. Vad är skillnaden mellan att ändra en produkts aktuella pris och att ändra prisuppgiften för en redan genomförd beställning?
2. När är det rimligt att radera en rad, och när behöver vi i stället bevara historiken?
3. Varför bör flera förändringar som beskriver en och samma verksamhetshändelse ibland genomföras som en transaktion?

# 19. Fönsterfunktioner

I kapitel 8 lärde vi oss att sammanfatta data. Med `GROUP BY` kan vi exempelvis ta reda på hur många böcker vi har i varje produkttyp eller vad deras sammanlagda lagervärde är.

Men ibland vill vi både se **varje enskild produkt** och samtidigt jämföra den med andra produkter.

Vi kanske vill veta hur en boks pris förhåller sig till genomsnittspriset i samma kategori, eller vilken plats den har i en prisordning. Då behöver vi inte nödvändigtvis slå ihop produkterna till en rad per grupp.

**Fönsterfunktioner** (*window functions*) låter oss göra beräkningar över en samling relaterade rader och ändå behålla de individuella raderna i resultatet.

## Grund

### Från grupper till fönster

Vi börjar med bokhandelns produkter:

**products**

| id | title | price | stock | product_type_id |
|---|---|---:|---:|---:|
| 1 | Vägen hem | 200.00 | 12 | 1 |
| 2 | Den blå staden | 150.00 | 0 | 1 |
| 3 | Vinterljus | 249.00 | 4 | 1 |
| 4 | Små historier | 120.00 | 25 | 2 |
| 5 | Mellan raderna | 180.00 | 9 | 2 |

Med `GROUP BY` kan vi beräkna genomsnittspriset per produkttyp:

```sql
SELECT
    product_type_id,
    AVG(price) AS average_price
FROM products
GROUP BY product_type_id;
```

| product_type_id | average_price |
|---|---:|
| 1 | 199.666667 |
| 2 | 150.000000 |

Här har vi fått **en rad per produkttyp**. Produktens titel och enskilda pris finns inte kvar som egna rader i resultatet.

Men tänk om vi vill visa varje produkt tillsammans med genomsnittet för just dess produkttyp?

### OVER – beräkna utan att slå ihop rader

Vi kan använda `AVG` som en fönsterfunktion:

```sql
SELECT
    title,
    price,
    product_type_id,
    AVG(price) OVER (
        PARTITION BY product_type_id
    ) AS average_price
FROM products
ORDER BY product_type_id, id;
```

| title | price | product_type_id | average_price |
|---|---:|---:|---:|
| Vägen hem | 200.00 | 1 | 199.666667 |
| Den blå staden | 150.00 | 1 | 199.666667 |
| Vinterljus | 249.00 | 1 | 199.666667 |
| Små historier | 120.00 | 2 | 150.000000 |
| Mellan raderna | 180.00 | 2 | 150.000000 |

Antalet rader är detsamma som i `products`, men varje rad har fått ett extra beräknat värde.

`OVER` talar om att funktionen ska beräknas över ett **fönster av rader**, i stället för att resultatet ska sammanfattas till en rad per grupp.

`PARTITION BY product_type_id` delar in raderna i olika fönster: ett för varje produkttyp.

Vi kan tänka oss att varje produkt får med sig ett mått som beskriver den grupp den tillhör.

### Att jämföra produkten med sin grupp

När genomsnittet finns tillgängligt på varje rad kan vi enkelt jämföra:

```sql
SELECT
    title,
    price,
    price - AVG(price) OVER (
        PARTITION BY product_type_id
    ) AS difference_from_average
FROM products
ORDER BY product_type_id, id;
```

En produkt med ett positivt värde ligger över genomsnittspriset för sin produkttyp. Ett negativt värde betyder att produkten ligger under genomsnittet.

Nu har vi inte bara beräknat ett mått. Vi har använt det som en **jämförelsepunkt för varje enskild produkt**.

### ROW_NUMBER – numrera rader

Fönsterfunktioner kan också ordna rader i en följd.

```sql
SELECT
    title,
    price,
    ROW_NUMBER() OVER (
        ORDER BY price DESC, id
    ) AS price_position
FROM products
ORDER BY price_position;
```

| title | price | price_position |
|---|---:|---:|
| Vinterljus | 249.00 | 1 |
| Vägen hem | 200.00 | 2 |
| Mellan raderna | 180.00 | 3 |
| Den blå staden | 150.00 | 4 |
| Små historier | 120.00 | 5 |

`ROW_NUMBER()` ger varje rad ett eget nummer.

Observera att `ORDER BY` **inne i** `OVER` anger i vilken ordning numren tilldelas. Den avslutande `ORDER BY` anger däremot hur resultatet ska presenteras.

Vi har lagt till `id` som andra sorteringskolumn för att få en entydig ordning om två produkter kostar lika mycket.

### Numrera inom varje grupp

Vi kan kombinera `PARTITION BY` med `ORDER BY`:

```sql
SELECT
    title,
    product_type_id,
    price,
    ROW_NUMBER() OVER (
        PARTITION BY product_type_id
        ORDER BY price DESC, id
    ) AS position_in_type
FROM products
ORDER BY product_type_id, position_in_type;
```

Nu börjar numreringen om för varje produkttyp.

Det är samma princip som när vi delade upp beräkningen av genomsnittspriser, men här använder vi fönstret till att skapa en **ordning inom varje grupp**.

### RANK och DENSE_RANK

`ROW_NUMBER()` ger unika radnummer även när flera produkter har samma pris.

I vissa sammanhang vill vi i stället att produkter med samma pris ska dela placering.

Då kan vi använda `RANK()`:

```sql
SELECT
    title,
    price,
    RANK() OVER (ORDER BY price DESC) AS price_rank,
    DENSE_RANK() OVER (ORDER BY price DESC) AS dense_price_rank
FROM products;
```

Skillnaden blir synlig om flera produkter har samma pris:

| Pris | RANK | DENSE_RANK |
|---:|---:|---:|
| 249 | 1 | 1 |
| 200 | 2 | 2 |
| 200 | 2 | 2 |
| 180 | 4 | 3 |

`RANK()` lämnar ett glapp efter en delad placering. `DENSE_RANK()` gör inte det.

Tabellen ovan är ett **illustrativt exempel med två lika priser**, inte det exakta resultatet från vår nuvarande produktlista.

## Avancerat

### Fönstret kan också bestå av en del av en grupp

Hittills har `PARTITION BY` avgränsat en grupp, och `ORDER BY` har skapat en ordning inom den.

Men vissa fönsterberäkningar kan också använda en **fönsterram** (*window frame*): vilka av de ordnade raderna som ingår i just den aktuella radens beräkning.

Vi kan exempelvis beräkna en löpande summa av lagerantalet:

```sql
SELECT
    id,
    title,
    stock,
    SUM(stock) OVER (
        ORDER BY id
        ROWS BETWEEN UNBOUNDED PRECEDING
             AND CURRENT ROW
    ) AS running_stock
FROM products
ORDER BY id;
```

| id | title | stock | running_stock |
|---:|---|---:|---:|
| 1 | Vägen hem | 12 | 12 |
| 2 | Den blå staden | 0 | 12 |
| 3 | Vinterljus | 4 | 16 |
| 4 | Små historier | 25 | 41 |
| 5 | Mellan raderna | 9 | 50 |

`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` betyder att beräkningen omfattar alla tidigare rader **i fönstrets ordning**, inklusive den aktuella raden.

Vi skriver ramen uttryckligen för att tydliggöra vad som räknas med.

### ROWS och RANGE

Det kan verka självklart att `ORDER BY` bestämmer vilka rader som räknas som tidigare och senare, men SQL skiljer mellan olika sätt att avgränsa ett fönster.

Med `ROWS` räknar vi **radpositioner i den ordning som fönstret anger**. Det handlar om ordningen i frågans resultat, inte om hur raderna är fysiskt lagrade i databasen.

Med `RANGE` kan rader med samma sorteringsvärde behandlas som en grupp av likvärdiga rader.

Därför kan standardramen för en aggregerande fönsterfunktion med `ORDER BY` ge oväntade resultat när flera rader har samma sorteringsvärde.

När vår avsikt är en löpande beräkning rad för rad använder vi gärna en uttrycklig `ROWS`-ram och en entydig sorteringsordning.[^frames]

[^frames]: SQL-dialekterna har delvis olika stöd för ramtyper och uttryck. En vanlig standardram vid `ORDER BY` är `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`. Den omfattar också likvärdiga sorteringsvärden (*peers*), vilket kan skilja sig från `ROWS`.

### LAG och LEAD – jämföra med andra rader

Ibland vill vi jämföra ett värde med raden före eller efter i en ordnad följd.

```sql
SELECT
    id,
    title,
    price,
    LAG(price) OVER (
        ORDER BY price, id
    ) AS previous_price
FROM products
ORDER BY price, id;
```

`LAG(price)` hämtar priset från föregående rad i den angivna ordningen. För den första raden finns inget föregående pris, så resultatet blir normalt `NULL`.

Motsvarigheten `LEAD(price)` hämtar värdet från nästa rad.

Sådana funktioner blir särskilt användbara när raderna beskriver exempelvis försäljning över tid, mätvärden eller andra händelser i följd.

### Filtrera på ett fönsterresultat

Anta att vi bara vill visa den dyraste produkten i varje produkttyp.

Det kan vara frestande att skriva:

```sql
-- Fungerar inte som avsett
SELECT
    title,
    product_type_id,
    ROW_NUMBER() OVER (
        PARTITION BY product_type_id
        ORDER BY price DESC, id
    ) AS position_in_type
FROM products
WHERE position_in_type = 1;
```

Problemet är att `WHERE` filtrerar rader **innan** fönsterfunktionerna beräknas. Aliaset `position_in_type` finns inte tillgängligt där.

Här får vi användning av CTE:er från kapitel 18:

```sql
WITH ranked_products AS (
    SELECT
        title,
        product_type_id,
        price,
        ROW_NUMBER() OVER (
            PARTITION BY product_type_id
            ORDER BY price DESC, id
        ) AS position_in_type
    FROM products
)
SELECT
    title,
    product_type_id,
    price
FROM ranked_products
WHERE position_in_type = 1
ORDER BY product_type_id;
```

| title | product_type_id | price |
|---|---:|---:|
| Vinterljus | 1 | 249.00 |
| Mellan raderna | 2 | 180.00 |

Vi beräknar först placeringen. Därefter kan den yttre Queryn filtrera på resultatet.

Det visar varför det är användbart att kunna kombinera **CTE:er och fönsterfunktioner**.

### Fönsterfunktioner och NULL

Precis som vanliga aggregeringar påverkas fönsterfunktioner av `NULL`.

`AVG(price)` räknar normalt bara med rader där `price` inte är `NULL`, medan `COUNT(*)` räknar rader oavsett om någon kolumn saknar värde.

`LAG` och `LEAD` kan däremot ge `NULL` därför att det saknas en föregående eller efterföljande rad.

Vi måste alltså fortfarande skilja mellan **ett saknat värde i informationen** och **avsaknaden av en jämförelserad**.

### Är fönsterfunktioner alltid effektivare?

Fönsterfunktioner kan ofta ersätta flera separata Queries, självkopplingar eller korrelerade subqueries.

Men de kräver ibland sortering och hantering av stora mängder rader. Resultatet beror på hur frågan ser ut, hur datan är fördelad, vilka index som finns och hur databashanteraren optimerar den.

Vi väljer därför inte en fönsterfunktion enbart för att den verkar avancerad, utan för att den uttrycker den beräkning vi faktiskt behöver.

Fönsterfunktioner stöds i moderna versioner av bland annat MySQL, PostgreSQL, SQLite och SQL Server, men detaljer och utökade funktioner varierar.[^dialects]

[^dialects]: MySQL har stöd för fönsterfunktioner från version 8.0. SQLite införde dem i version 3.25. PostgreSQL och SQL Server har haft stöd under lång tid. Funktioner och syntax för vissa fönsterramar kan skilja sig mellan systemen.

### Vilken rad beskriver vi?

Med `GROUP BY` förvandlar vi en samling produktposter till en sammanfattning: exempelvis **en rad per produkttyp**.

Med fönsterfunktioner behåller vi i stället **en rad per produkt**, men gör det möjligt att beskriva produkten i relation till en större samling.

Det är en grundläggande skillnad i **vilken information varje rad representerar**.

En produkt kan ha ett eget pris, tillhöra en produkttyp med ett genomsnittspris och ha en viss placering bland andra produkter. Alla tre är meningsfulla uppgifter – men de beskriver olika perspektiv på samma information.

## Reflektion

1. När är `GROUP BY` lämpligare än en fönsterfunktion, och när behöver vi bevara en rad för varje enskild produkt?
2. Varför kan två Queries med `RANK()` och `ROW_NUMBER()` ge olika sätt att beskriva samma placering?
3. Vad händer med vår tolkning av en beräkning när vi ändrar vilka rader som ingår i fönstret?

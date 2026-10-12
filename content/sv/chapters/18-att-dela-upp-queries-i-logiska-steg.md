# 18. Att dela upp Queries i logiska steg

När vi formulerar en Query kan vi ofta börja med en enkel fråga: vilka produkter finns i lager, eller vilka produkter kostar mer än genomsnittet?

Men ibland behöver vi flera steg för att få fram ett meningsfullt resultat. Vi kanske först vill beräkna lagervärdet för varje produkt, sedan sammanfatta det per produkttyp och slutligen välja ut de produkttyper som representerar störst värde.

Det går att skriva allt i en enda stor SQL-konstruktion. Men det är inte alltid det bästa sättet att **förstå vad vi gör**.

Med **Common Table Expressions (CTE:er)** kan vi ge olika delar av en Query namn och låta dem bygga vidare på varandra.

## Grund

### Common Table Expressions – WITH

Vi börjar med bokhandelns produkter:

**products**

| id | title | price | stock | product_type_id |
|---|---|---:|---:|---:|
| 1 | Vägen hem | 200.00 | 12 | 1 |
| 2 | Den blå staden | 150.00 | 0 | 1 |
| 3 | Vinterljus | 249.00 | 4 | 1 |
| 4 | Små historier | 120.00 | 25 | 2 |
| 5 | Mellan raderna | 180.00 | 9 | 2 |

Vi har tidigare beräknat lagervärdet för en produkt genom att multiplicera `price` med `stock`:

```sql
SELECT
    title,
    price * stock AS inventory_value
FROM products;
```

Om vi vill använda samma beräkning som ett eget mellanresultat kan vi skriva:

```sql
WITH product_values AS (
    SELECT
        title,
        price * stock AS inventory_value
    FROM products
)
SELECT *
FROM product_values;
```

| title | inventory_value |
|---|---:|
| Vägen hem | 2400.00 |
| Den blå staden | 0.00 |
| Vinterljus | 996.00 |
| Små historier | 3000.00 |
| Mellan raderna | 1620.00 |

`WITH` inleder definitionen. `product_values` är namnet vi valt för mellanresultatet och parenteserna innehåller den Query som skapar det.

Efter definitionen följer vår huvudsakliga Query. Den använder `product_values` som om det vore en tabell.

En CTE skapar normalt inte någon bestående tabell eller View. Namnet finns tillgängligt **inom den SQL-sats där det definieras**.

### Filtrera ett mellanresultat

Vi kan fortsätta arbeta med det beräknade värdet:

```sql
WITH product_values AS (
    SELECT
        title,
        price * stock AS inventory_value
    FROM products
)
SELECT title, inventory_value
FROM product_values
WHERE inventory_value > 2000
ORDER BY inventory_value DESC;
```

| title | inventory_value |
|---|---:|
| Små historier | 3000.00 |
| Vägen hem | 2400.00 |

Nu blir det tydligt att vi gör två olika saker:

1. Beräknar lagervärdet för varje produkt.
2. Väljer vilka beräknade värden vi är intresserade av.

Det är en liten skillnad i kod, men en viktig skillnad för läsbarheten.

### Flera namngivna steg

Nu vill vi sammanfatta lagervärdet per produkttyp.

Vi kan dela upp arbetet i två CTE:er:

```sql
WITH product_values AS (
    SELECT
        product_type_id,
        price * stock AS inventory_value
    FROM products
),
type_values AS (
    SELECT
        product_type_id,
        SUM(inventory_value) AS total_value
    FROM product_values
    GROUP BY product_type_id
)
SELECT product_type_id, total_value
FROM type_values
ORDER BY total_value DESC;
```

| product_type_id | total_value |
|---:|---:|
| 2 | 4620.00 |
| 1 | 3396.00 |

Den första CTE:n beräknar värden per produkt. Den andra sammanfattar dessa värden per produkttyp.

En CTE kan alltså använda en tidigare CTE inom samma `WITH`-del.

Här har vi byggt upp ett större informationsbehov som **en kedja av begripliga steg**.

### Kombinera CTE med JOIN

Nu vill vi också visa produkttypernas namn.

**product_types**

| id | name |
|---|---|
| 1 | Roman |
| 2 | Novellsamling |

```sql
WITH product_values AS (
    SELECT
        product_type_id,
        price * stock AS inventory_value
    FROM products
),
type_values AS (
    SELECT
        product_type_id,
        SUM(inventory_value) AS total_value
    FROM product_values
    GROUP BY product_type_id
)
SELECT
    t.name AS product_type,
    v.total_value
FROM type_values AS v
INNER JOIN product_types AS t
    ON t.id = v.product_type_id
ORDER BY v.total_value DESC;
```

| product_type | total_value |
|---|---:|
| Novellsamling | 4620.00 |
| Roman | 3396.00 |

Vi känner redan till alla delarna: uttryck, aggregering och `JOIN`. CTE:erna hjälper oss bara att **organisera dem**.

### CTE eller subquery?

I kapitel 10 lärde vi oss att en subquery kan användas som en del av en annan Query.

Vi kan exempelvis skriva:

```sql
SELECT product_type_id, SUM(inventory_value) AS total_value
FROM (
    SELECT
        product_type_id,
        price * stock AS inventory_value
    FROM products
) AS product_values
GROUP BY product_type_id;
```

Det fungerar också.

En CTE ger oss möjlighet att flytta ut det namngivna mellanresultatet till början av satsen, och kan göra det enklare att följa en Query med många steg.

Vi väljer den form som gör informationsbehovet tydligast – inte utifrån en regel om att den ena alltid skulle vara bättre.

## Avancerat

### En CTE är inte nödvändigtvis en tillfällig tabell

Det kan vara hjälpsamt att föreställa sig att databasen först skapar `product_values` och sedan läser från det.

Men det är en **logisk beskrivning**, inte nödvändigtvis hur frågan körs.

En databashanterare kan välja att slå samman CTE:n med resten av frågan, beräkna den som ett separat mellanresultat eller använda andra optimeringar.

CTE:er gör alltså inte automatiskt en Query snabbare eller långsammare. Beteendet varierar mellan databassystem, versioner och enskilda Queries.[^optimizer]

[^optimizer]: PostgreSQL kan exempelvis slå samman vissa CTE:er med omgivande Query och stöder `MATERIALIZED` och `NOT MATERIALIZED` i relevanta sammanhang. MySQL och SQL Server har andra optimeringsstrategier. Läsbarhet och faktisk exekveringsplan bör hållas isär.

### Återanvända samma mellanresultat

En namngiven CTE kan refereras från flera delar av samma SQL-sats.

Vi kanske vill jämföra varje produkt med genomsnittligt lagervärde:

```sql
WITH product_values AS (
    SELECT
        title,
        price * stock AS inventory_value
    FROM products
),
average_value AS (
    SELECT AVG(inventory_value) AS average_inventory_value
    FROM product_values
)
SELECT
    p.title,
    p.inventory_value,
    a.average_inventory_value
FROM product_values AS p
CROSS JOIN average_value AS a
WHERE p.inventory_value > a.average_inventory_value;
```

`average_value` ger en rad med ett värde, så en `CROSS JOIN` gör värdet tillgängligt på varje produktrad.

Vi ska inte anta att detta alltid innebär att databasen fysiskt räknar `product_values` exakt en gång. Det avgörs av frågeoptimeraren.

### Rekursiva CTE:er

Hittills har varje CTE byggt på redan definierade tabeller eller mellanresultat.

Men vissa problem är **rekursiva**. Tänk exempelvis på en hierarki av produktkategorier:

```text
Böcker
├── Skönlitteratur
│   ├── Romaner
│   └── Noveller
└── Facklitteratur
    └── Databaser
```

En kategori kan ha en överordnad kategori. Hierarkin kan ha flera nivåer, och vi kanske inte vet i förväg hur många.

Vi kan modellera den med en tabell:

**categories**

| id | name | parent_id |
|---|---|---|
| 1 | Böcker | NULL |
| 2 | Skönlitteratur | 1 |
| 3 | Facklitteratur | 1 |
| 4 | Romaner | 2 |
| 5 | Noveller | 2 |
| 6 | Databaser | 3 |

Detta är ett separat exempel på en möjlig framtida kategorimodell; den ersätter inte vår tidigare enkla tabell `product_types`.

Vi kan sedan använda en **rekursiv CTE**:

```sql
WITH RECURSIVE category_tree AS (
    SELECT
        id,
        name,
        parent_id,
        0 AS depth
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    SELECT
        c.id,
        c.name,
        c.parent_id,
        ct.depth + 1
    FROM categories AS c
    INNER JOIN category_tree AS ct
        ON c.parent_id = ct.id
)
SELECT name, depth
FROM category_tree
ORDER BY depth, id;
```

Resultat:

| name | depth |
|---|---:|
| Böcker | 0 |
| Skönlitteratur | 1 |
| Facklitteratur | 1 |
| Romaner | 2 |
| Noveller | 2 |
| Databaser | 2 |

### Hur fungerar rekursionen?

En rekursiv CTE har två delar:

**Startdel:** Den första `SELECT`-satsen väljer var vi ska börja, här de kategorier som inte har någon överordnad kategori.

**Rekursiv del:** Den andra `SELECT`-satsen hittar fler rader genom att använda resultatet från tidigare steg.

`UNION ALL` kombinerar delarnas resultat.

Vi kan tänka oss att databasen arbetar nivå för nivå tills det inte finns fler underkategorier att hitta. Detta är en förenklad förklaring av den logiska processen.

Det är viktigt att rekursionen faktiskt kan avslutas. Om vår hierarki innehåller cykler, exempelvis en kategori som indirekt pekar tillbaka på sig själv, behöver vi skydda oss mot obegränsad upprepning. Databassystem har olika säkerhetsgränser och möjligheter att hantera sådana situationer.[^recursive]

[^recursive]: MySQL och PostgreSQL stöder `WITH RECURSIVE`. SQLite stöder också rekursiva CTE:er. SQL Server använder rekursiva CTE:er men skriver normalt `WITH` utan nyckelordet `RECURSIVE` och har bland annat `MAXRECURSION` för att begränsa antal nivåer. Detaljer kring typning, djupgränser och cykelhantering varierar.

### Rekursion är inte bara för hierarkier

Samma princip kan användas för att följa relationer i flera led, exempelvis:

- Kategorier och underkategorier.
- Organisationsstrukturer.
- Beroenden mellan komponenter.
- Förbindelser i ett nätverk.

Men en rekursiv CTE är inte alltid bästa lösningen för varje grafproblem. Vi behöver fortfarande avgöra vad relationerna betyder, om cykler tillåts och vilka vägar som är relevanta.

### CTE, View och lagrad tabell

Vi har nu tre olika sätt att arbeta med ett resultat som liknar en tabell:

| Konstruktion | Var resultatet eller definitionen finns |
|---|---|
| **CTE** | Namngivet inom en enda SQL-sats |
| **View** | En sparad definition som kan användas av flera Queries |
| **Tabell** | En lagringsstruktur med egna rader och regler |

En CTE är praktisk när vi vill göra en enskild Query mer begriplig.

En View passar när flera användare eller applikationer behöver återanvända samma logiska representation.

En tabell passar när informationen faktiskt behöver lagras som egna poster, med egen identitet och integritetsregler.

Valet handlar alltså inte bara om hur vi skriver SQL, utan också om **hur länge och för vilket syfte representationen ska finnas**.

### Att namnge ett steg är att formulera en tanke

I vår Query om lagervärden valde vi namnen `product_values` och `type_values`.

Dessa namn berättar vad informationen betyder på olika nivåer: först produktens lagervärde, sedan produkttypens sammanlagda lagervärde.

Det är möjligt att skriva SQL som ger rätt resultat men är svårt att förstå. Men det är också möjligt att skriva SQL så att strukturen förklarar resonemanget bakom resultatet.

**En välskriven Query är inte bara korrekt. Den hjälper oss att förstå vilka informationssteg som leder fram till svaret.**

## Reflektion

1. När blir en Query lättare att förstå om vi delar upp den i flera namngivna steg?
2. Vad är skillnaden mellan en CTE och en View, även om båda kan se ut som en tabell när vi använder dem?
3. När kan en rekursiv CTE hjälpa oss att beskriva ett samband som sträcker sig över flera nivåer?

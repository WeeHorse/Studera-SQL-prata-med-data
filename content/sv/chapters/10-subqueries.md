# 10. Subqueries

En fråga till en databas behöver inte alltid besvaras i ett enda steg.

Vi kanske vill hitta böcker som kostar mer än genomsnittet i vårt sortiment. Men då behöver vi först veta vad genomsnittet är. Eller så vill vi hitta kunder som har en adress i en viss stad, utan att själva visa adressuppgifterna.

Vi skulle kunna ställa två frågor efter varandra. Men SQL låter oss också använda **en fråga som en del av en annan fråga**.

Det kallas en *subquery*, på svenska en **underfråga**.

## Grund

### En Query inuti en annan

Vi använder bokhandelns produkter:

**products**

| id | title | price | stock | product_type_id |
|---|---|---:|---:|---:|
| 1 | Vägen hem | 200.00 | 12 | 1 |
| 2 | Den blå staden | 150.00 | 0 | 1 |
| 3 | Vinterljus | 249.00 | 4 | 1 |
| 4 | Små historier | 120.00 | 25 | 2 |
| 5 | Mellan raderna | 180.00 | 9 | 2 |

Anta att vi vill hitta produkter som kostar mer än genomsnittet.

Vi kan börja med att beräkna genomsnittspriset:

```sql
SELECT AVG(price)
FROM products;
```

Resultatet är `179.80`.

Vi kan sedan använda resultatet i en annan fråga:

```sql
SELECT title, price
FROM products
WHERE price > 179.80;
```

Men då har vi skrivit in ett värde som kan förändras när sortimentet ändras.

I stället kan vi låta databasen beräkna värdet direkt:

```sql
SELECT title, price
FROM products
WHERE price > (
    SELECT AVG(price)
    FROM products
);
```

| title | price |
|---|---:|
| Vägen hem | 200.00 |
| Vinterljus | 249.00 |
| Mellan raderna | 180.00 |

Den inre frågan beräknar genomsnittspriset. Den yttre frågan använder det som gräns för att välja produkter.

Vi har alltså beskrivit ett informationsbehov som bygger på ett annat.

### Subqueries som ger ett enda värde

I vårt första exempel gav underfrågan ett enda värde: genomsnittspriset.

En underfråga som används som ett enskilt värde kallas en **skalär subquery**.

Vi kan också visa genomsnittet tillsammans med varje produkt:

```sql
SELECT
    title,
    price,
    (SELECT AVG(price) FROM products) AS average_price
FROM products;
```

Här blir genomsnittspriset detsamma på varje resultatrad.

En skalär underfråga måste ge högst en rad och en kolumn. Om den inte ger någon rad blir resultatet `NULL`; ger den fler än en rad uppstår normalt ett fel.

### Subqueries med flera värden: IN

Ibland är resultatet från den inre frågan inte ett enda värde, utan flera.

Anta att vi vill hämta alla kunder som har en adress i Storfors.

Vi känner redan till dessa tabeller:

**customers**

| id | name |
|---|---|
| 1 | Benjamin |
| 2 | Olof |
| 3 | Anaïs |
| 4 | Beatrice |
| 5 | Anna |

**addresses**

| id | customer_id | street | city |
|---|---|---|---|
| 1 | 1 | Hemmagatan 1 | Hemmavan |
| 2 | 1 | Storgatan 4 | Storfors |
| 3 | 2 | Parkvägen 2 | Storfors |
| 4 | 3 | NULL | Malmö |

Först kan vi ta fram de kund-id som förekommer på adresser i Storfors:

```sql
SELECT customer_id
FROM addresses
WHERE city = 'Storfors';
```

Resultatet blir `1` och `2`.

Det kan vi använda i en yttre fråga med `IN`:

```sql
SELECT name
FROM customers
WHERE id IN (
    SELECT customer_id
    FROM addresses
    WHERE city = 'Storfors'
);
```

| name |
|---|
| Benjamin |
| Olof |

`IN` frågar om ett värde finns bland värdena som underfrågan ger tillbaka.

Notera att vi bara hämtar en rad per kund, även om kunden skulle ha flera adresser i Storfors. Vi undersöker *vilka kunder* som matchar, inte hur många adresser de har.

### Subqueries och JOIN

Samma informationsbehov kan vi uttrycka med `JOIN`:

```sql
SELECT DISTINCT c.name
FROM customers AS c
INNER JOIN addresses AS a
    ON a.customer_id = c.id
WHERE a.city = 'Storfors';
```

Varför `DISTINCT`?

En `JOIN` kan skapa flera resultatrader för samma kund om kunden har flera matchande adresser. En fråga med `IN` utgår däremot från kundraderna och testar om deras id finns i en samling värden.

Ingen av metoderna är automatiskt bäst. Vi väljer bland annat efter **vad vi vill att varje rad i resultatet ska representera**.

### EXISTS – finns det minst en matchning?

Ibland vill vi inte ha något värde från underfrågan alls. Vi vill bara veta om en matchande rad **finns**.

Då kan vi använda `EXISTS`:

```sql
SELECT c.name
FROM customers AS c
WHERE EXISTS (
    SELECT 1
    FROM addresses AS a
    WHERE a.customer_id = c.id
      AND a.city = 'Storfors'
);
```

Resultatet blir återigen Benjamin och Olof.

`EXISTS` blir sant om underfrågan ger minst en rad. Vilka värden som står i underfrågans `SELECT` spelar ingen roll för själva existenskontrollen. Därför används ofta `SELECT 1`.

Detta exempel skiljer sig från de tidigare: den inre frågan använder `c.id` från den yttre frågan.

Vi tittar närmare på det under *Avancerat*.

## Avancerat

### Korrelerade subqueries

En **korrelerad subquery** hänvisar till värden från den omgivande frågan.

```sql
SELECT c.name
FROM customers AS c
WHERE EXISTS (
    SELECT 1
    FROM addresses AS a
    WHERE a.customer_id = c.id
);
```

För varje kund undersöker vi om det finns minst en adress som refererar till just den kundens id.

Det kan vara hjälpsamt att tänka att underfrågan prövas mot varje kundrad. Men det är en **logisk beskrivning**, inte ett krav på hur databashanteraren faktiskt ska utföra frågan. En SQL-optimerare kan välja en annan exekveringsplan.

### NOT EXISTS – när något saknas

Vi kan vända på frågan och leta efter kunder utan registrerade adresser:

```sql
SELECT c.name
FROM customers AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM addresses AS a
    WHERE a.customer_id = c.id
);
```

| name |
|---|
| Beatrice |
| Anna |

`NOT EXISTS` är användbart när vi söker efter *avsaknaden av en relation*.

Det kan till exempel senare användas för att hitta produkter som aldrig har förekommit på en orderrad, eller beställningar som saknar någon viss typ av information.

### NOT IN och NULL

Det är frestande att skriva om föregående exempel med `NOT IN`:

```sql
SELECT name
FROM customers
WHERE id NOT IN (
    SELECT customer_id
    FROM addresses
);
```

Om `addresses.customer_id` aldrig kan vara `NULL` fungerar detta som väntat.

Men om underfrågan innehåller `NULL` kan `NOT IN` ge överraskande resultat. SQL:s trevärdeslogik innebär att en jämförelse mot ett okänt värde kan bli *okänd* i stället för sann.

När vi vill uttrycka att **ingen matchande rad finns** är `NOT EXISTS` därför ofta ett tydligare val.

### Subqueries i FROM

En underfråga behöver inte stå i `WHERE`. Vi kan också använda den som en datakälla i `FROM`.

Anta att vi först vill räkna fram antalet produkter per produkttyp och därefter bara visa typer som har fler än två produkter.

```sql
SELECT
    summary.product_type_id,
    summary.product_count
FROM (
    SELECT
        product_type_id,
        COUNT(*) AS product_count
    FROM products
    GROUP BY product_type_id
) AS summary
WHERE summary.product_count > 2;
```

| product_type_id | product_count |
|---:|---:|
| 1 | 3 |

Här skapar den inre frågan ett **tabellformat resultat**, som den yttre frågan sedan behandlar som en datakälla.

Vi ger det tillfälliga resultatet aliaset `summary`.

Vi hade också kunnat lösa just detta med `HAVING`, som vi introducerade i kapitel 8. Men exemplet visar hur vi kan bygga vidare på ett mellanresultat.

En sådan konstruktion kallas ibland en *derived table* eller härledd tabell.

### Subqueries för jämförelser inom en grupp

Vi kan också jämföra varje produkt med genomsnittspriset för dess egen produkttyp:

```sql
SELECT
    p.title,
    p.price,
    p.product_type_id
FROM products AS p
WHERE p.price > (
    SELECT AVG(p2.price)
    FROM products AS p2
    WHERE p2.product_type_id = p.product_type_id
);
```

Här beräknar den inre frågan ett genomsnitt för just den produkttyp som den aktuella produkten tillhör.

Detta är ännu ett exempel på en korrelerad subquery.

Jämförelsen svarar alltså inte på frågan ”vilka böcker är dyrare än genomsnittsboken?”, utan på frågan **”vilka böcker är dyrare än genomsnittet inom sin egen typ?”**

Det är två olika sätt att tolka informationen.

### Subquery, JOIN eller CTE?

Flera SQL-konstruktioner kan ibland beskriva samma informationsbehov, men de är inte alltid utbytbara utan att resultatet förändras.

**När vi vill kombinera information från flera tabeller är `JOIN` ofta det naturliga förstahandsvalet.**

När vi i stället vill undersöka om en relation finns passar `EXISTS` eller `IN` ofta bättre. En `JOIN` kan ge flera resultatrader för samma kund om kunden har flera adresser, medan `EXISTS` bara testar om minst en matchning finns. En skalär subquery är också ett naturligt val när vi vill jämföra med exempelvis ett genomsnittspris.

Det finns ingen allmän regel om att subqueries är långsammare än `JOIN`. Moderna databashanterare kan ofta omvandla och optimera olika skrivsätt till liknande exekveringsplaner. När prestandan verkligen spelar roll bör vi undersöka frågans exekveringsplan, exempelvis med `EXPLAIN`, i stället för att dra slutsatser från syntaxen.

**Vår tumregel:** Välj i första hand den konstruktion som tydligast uttrycker vad varje rad i resultatet ska betyda. Använd gärna `JOIN` för att kombinera data och `EXISTS` eller `IN` för att pröva förekomsten av relaterade värden.

Senare kommer vi också att arbeta med `WITH` och så kallade **CTE:er** (*Common Table Expressions*). De låter oss namnge mellanresultat och strukturera större frågor.

### Att bygga en fråga av andra frågor

Med subqueries kan vi stegvis uttrycka mer sammansatta informationsbehov utan att skapa nya lagrade tabeller.

Vi kan exempelvis fråga efter produkter vars pris ligger över ett genomsnitt, kunder som har en viss relation eller produkttyper som uppfyller ett sammanfattande villkor.

I varje steg beskriver vi **vilket resultat vi behöver från föregående steg**.

Det är nära besläktat med tanken bakom Views: vi kan arbeta med nya logiska representationer av redan lagrad information.

Skillnaden är att en subquery är en del av den fråga vi skriver just nu, medan en View kan få ett eget namn och återanvändas i andra frågor.

## Reflektion

1. När kan en fråga inuti en annan fråga vara lättare att förstå än en enda fråga med flera kopplade tabeller?
2. Vad är den begreppsliga skillnaden mellan att fråga vilka kunder som har en adress och att fråga hur många adresser varje kund har?
3. Varför kan det vara värdefullt att dela upp ett informationsbehov i flera logiska steg även när databasen skulle kunna lösa det på andra sätt?

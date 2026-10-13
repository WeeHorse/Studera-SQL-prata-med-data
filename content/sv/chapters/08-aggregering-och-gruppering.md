# 8. Aggregering och gruppering

En bokhandel kan veta priset och lagersaldot för varje produkt. Men ibland är det inte den enskilda produkten vi vill undersöka.

Vi kanske vill veta hur många produkter vi säljer, vad de kostar i genomsnitt eller hur många exemplar vi har i lager totalt.

Då behöver vi gå från **enskilda värden till sammanfattningar**.

En sammanfattning kan göra stora mängder information begripliga. Men den innebär också att vi väljer bort detaljer. Ett genomsnittligt pris berättar något om sortimentet – men inte vilka böcker som är dyra och vilka som är billiga.

## Grund

### Flera rader blir ett resultat

Vi fortsätter med bokhandelns produkter. Vi lägger till en produkt i vår tabell:

**products**

| id | title | price | stock |
|---|---|---:|---:|
| 1 | Vägen hem | 200.00 | 12 |
| 2 | Den blå staden | 150.00 | 0 |
| 3 | Vinterljus | 249.00 | 4 |
| 4 | Små historier | 120.00 | 25 |
| 5 | Mellan raderna | 180.00 | 9 |

Om vi vill veta hur många produkter som finns i tabellen kan vi räkna raderna:

```sql
SELECT COUNT(*)
FROM products;
```

Resultat:

| COUNT(*) |
|---:|
| 5 |

`COUNT()` är en **aggregeringsfunktion**. Den använder värden från flera rader för att skapa ett sammanfattat resultat.

### Vanliga aggregeringsfunktioner

| Funktion | Vad den beräknar |
|---|---|
| `COUNT()` | Antal |
| `SUM()` | Summa |
| `AVG()` | Medelvärde |
| `MIN()` | Minsta värde |
| `MAX()` | Största värde |

Vi kan beräkna det totala antalet exemplar i lager:

```sql
SELECT SUM(stock) AS total_stock
FROM products;
```

| total_stock |
|---:|
| 50 |

Vi kan också beräkna sortimentets genomsnittliga pris med `AVG(price)`:

| average_price |
|---:|
| 179.80 |

Observera att vi nu får **ett värde** som sammanfattar flera produkter.

### Flera sammanfattningar samtidigt

Vi kan göra flera beräkningar i samma fråga:

```sql
SELECT
    COUNT(*) AS product_count,
    SUM(stock) AS total_stock,
    MIN(price) AS lowest_price,
    MAX(price) AS highest_price
FROM products;
```

| product_count | total_stock | lowest_price | highest_price |
|---:|---:|---:|---:|
| 5 | 50 | 120.00 | 249.00 |

Här beskriver resultatet hela produkttabellen, inte en enskild produkt.

### Vilka rader ska räknas?

Vi kan använda `WHERE` för att välja vilka rader som ska ingå **innan** vi gör beräkningen.

```sql
SELECT COUNT(*) AS available_products
FROM products
WHERE stock > 0;
```

| available_products |
|---:|
| 4 |

Vi räknar nu antalet olika produkter som faktiskt finns i lager.

Men om vi i stället frågar hur många **exemplar** som finns tillgängliga behöver vi `SUM(stock)`. Skillnaden mellan antal produkter och antal exemplar är en skillnad i *vad vi mäter*, inte bara i SQL-syntax.

### Gruppindelning med GROUP BY

Tänk dig att vi vill veta hur produkterna fördelar sig mellan olika kategorier.

Vi utökar därför tabellen med `product_type_id`, som pekar på en produkttyp.

**products**

| id | title | price | stock | product_type_id |
|---|---|---:|---:|---:|
| 1 | Vägen hem | 200.00 | 12 | 1 |
| 2 | Den blå staden | 150.00 | 0 | 1 |
| 3 | Vinterljus | 249.00 | 4 | 1 |
| 4 | Små historier | 120.00 | 25 | 2 |
| 5 | Mellan raderna | 180.00 | 9 | 2 |

Produkttyperna finns i en separat tabell, `product_types`: `1` betyder *Roman* och `2` betyder *Novellsamling*. Vi kommer senare att lära oss hämta typnamnet från den tabellen. Än så länge räcker identifierarna.

Om vi vill räkna antalet produkter per typ:

```sql
SELECT
    product_type_id,
    COUNT(*) AS product_count
FROM products
GROUP BY product_type_id;
```

| product_type_id | product_count |
|---:|---:|
| 1 | 3 |
| 2 | 2 |

`GROUP BY` delar in raderna i grupper utifrån ett eller flera värden. Därefter gör aggregeringsfunktionen en beräkning för varje grupp.

### Flera beräkningar per grupp

Vi kan också få både antalet produkter och det sammanlagda lagersaldot per typ:

```sql
SELECT
    product_type_id,
    COUNT(*) AS product_count,
    SUM(stock) AS total_stock
FROM products
GROUP BY product_type_id
ORDER BY product_type_id;
```

| product_type_id | product_count | total_stock |
|---:|---:|---:|
| 1 | 3 | 16 |
| 2 | 2 | 34 |

Resultatet innehåller en rad per grupp.

### Filtrera grupper med HAVING

Anta att vi bara är intresserade av produkttyper som innehåller fler än två olika produkter.

Vi kan inte använda `WHERE COUNT(*) > 2` för detta. `WHERE` filtrerar enskilda rader innan grupperingen är gjord.

I stället använder vi `HAVING`:

```sql
SELECT
    product_type_id,
    COUNT(*) AS product_count
FROM products
GROUP BY product_type_id
HAVING COUNT(*) > 2;
```

| product_type_id | product_count |
|---:|---:|
| 1 | 3 |

`HAVING` filtrerar **grupper efter aggregeringen**.

En sammanfattning av hur delarna samverkar:

```sql
SELECT product_type_id, COUNT(*) AS product_count
FROM products
WHERE price >= 150
GROUP BY product_type_id
HAVING COUNT(*) >= 2
ORDER BY product_type_id;
```

Här väljer vi först produkter som kostar minst 150, grupperar dem efter typ och behåller sedan bara grupper med minst två produkter.

## Avancerat

### Vad räknar COUNT egentligen?

Det finns en viktig skillnad mellan tre uttryck:

```sql
COUNT(*)
COUNT(price)
COUNT(DISTINCT price)
```

- `COUNT(*)` räknar rader.
- `COUNT(price)` räknar rader där `price` inte är `NULL`.
- `COUNT(DISTINCT price)` räknar antalet olika kända prisvärden.

Om varje produkt har ett pris är de två första lika stora. Men om vissa priser saknas blir resultatet annorlunda.

Att fråga ”hur många?” är alltså inte tillräckligt. Vi måste också bestämma **vad det är vi räknar**.

### NULL påverkar sammanfattningen

`SUM()` och `AVG()` ignorerar normalt `NULL`-värden.

Om vi har tre priser, `100`, `200` och `NULL`, blir medelvärdet `150`, inte `100`.

Det beror på att medelvärdet beräknas över de två kända priserna. Vi kan inte förutsätta att ett saknat pris är noll.

När vi tolkar ett medelvärde behöver vi därför ibland också fråga hur många värden som faktiskt ingick:

```sql
SELECT
    COUNT(*) AS products,
    COUNT(price) AS known_prices,
    AVG(price) AS average_price
FROM products;
```

### Att mäta lagervärde

Vi har hittills räknat antal produkter, antal exemplar och genomsnittligt pris.

Men vad är det totala lagervärdet, beräknat utifrån våra aktuella försäljningspriser?

För varje produkt behöver vi multiplicera priset med antalet exemplar. Därefter summerar vi:

```sql
SELECT SUM(price * stock) AS inventory_value
FROM products;
```

| inventory_value |
|---:|
| 8016.00 |

Detta är ett **beräknat värde utifrån aktuella priser och lagersaldon**, inte nödvändigtvis varornas bokförda lagervärde eller inköpsvärde.

Vi kan också beräkna lagervärdet per produkttyp:

```sql
SELECT
    product_type_id,
    SUM(price * stock) AS inventory_value
FROM products
GROUP BY product_type_id
ORDER BY product_type_id;
```

Detta visar hur aggregering och uttryck kan kombineras.

### Varför får vi inte välja vilken kolumn som helst?

Betrakta denna fråga:

```sql
SELECT product_type_id, title, COUNT(*)
FROM products
GROUP BY product_type_id;
```

Vi vill få en rad per produkttyp, men vad ska då `title` innehålla? Varje typ kan innehålla flera titlar.

Frågan är därför inte väldefinierad som den står. Normalt behöver de kolumner och uttryck vi väljer antingen ingå i grupperingen, vara aggregerade eller vara funktionellt beroende av grupperingskolumnerna.[^grouping]

[^grouping]: Vissa SQL-system accepterar särskilda undantag eller mer tillåtande grupperingsregler. MySQL använder exempelvis normalt `ONLY_FULL_GROUP_BY`, vilket begränsar tvetydiga frågor. SQLite tillåter vissa icke-grupperade kolumner men resultatet kan då bli missvisande. Vi håller oss till den tydligare, standardnära principen.

Det här är inte bara en teknisk regel. Det handlar om att vi måste bestämma **vad en rad i vårt resultat betyder**.

### Ett genomsnitt kan dölja skillnader

Två produkttyper kan ha samma genomsnittliga pris trots att den ena innehåller nästan enbart jämnt prissatta böcker och den andra både mycket billiga och mycket dyra.

Ett medelvärde är därför inte en fullständig beskrivning av en fördelning.

Vi kan ibland behöva komplettera `AVG()` med `MIN()`, `MAX()` och `COUNT()` – eller gå tillbaka och studera de enskilda värdena.

När vi senare arbetar med fönsterfunktioner kommer vi dessutom att kunna visa sammanfattningar utan att förlora varje enskild rad i resultatet.

### Från gruppering till en ny modell

Vår ursprungliga produkttabell beskriver **produkter**.

Men vår tidigare Query med `GROUP BY product_type_id`, `COUNT(*)` och `SUM(stock)` beskriver i stället **produkttypernas sammanlagda sortiment och lager**.

Vi har skapat en ny representation av redan lagrade data, med en annan betydelse för varje rad.

Den nya representationen behöver inte lagras som en egen tabell. Längre fram kommer vi att se hur en sådan fråga kan bli en **View** – en återanvändbar, logisk modell av samma information.

## Reflektion

1. Vad är skillnaden mellan att räkna antalet produkter och att summera antalet exemplar i lager?
2. När riskerar ett genomsnitt att dölja viktig information?
3. När vi grupperar produkter efter typ, vad är det egentligen som varje rad i resultatet representerar?

# 9. Att kombinera flera tabeller

En kund har ett namn. En adress har en gata och en stad. En produkt har ett pris och tillhör en produkttyp.

Vi har valt att lagra dessa uppgifter i olika tabeller eftersom de beskriver olika företeelser. Men när vi vill använda informationen behöver vi ofta se dem tillsammans.

En fråga som ”Vilka kunder har adresser i Storfors?” handlar inte enbart om kunder eller adresser. Den handlar om **sambandet mellan dem**.

Med SQL kan vi kombinera information från flera tabeller utan att först behöva lägga allting i samma tabell.

## Grund

### Två tabeller som hör ihop

Vi börjar med bokhandelns kunder och adresser.

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

Kolumnen `customer_id` i `addresses` talar om vilken kund adressen tillhör.

När `customer_id` är `2` syftar den på kunden med `id` lika med `2`, alltså Olof.

Vi behöver inte upprepa kundens namn på varje adressrad. I stället använder vi relationen mellan tabellerna.

### INNER JOIN – kombinera matchande rader

Vi vill se kundernas namn tillsammans med deras adresser:

```sql
SELECT
    c.name,
    a.street,
    a.city
FROM customers AS c
INNER JOIN addresses AS a
    ON a.customer_id = c.id;
```

Resultat:

| name | street | city |
|---|---|---|
| Benjamin | Hemmagatan 1 | Hemmavan |
| Benjamin | Storgatan 4 | Storfors |
| Olof | Parkvägen 2 | Storfors |
| Anaïs | NULL | Malmö |

`INNER JOIN` kombinerar rader där villkoret efter `ON` är uppfyllt.

I vårt exempel är villkoret att adressens `customer_id` ska motsvara kundens `id`.

<escape>Det är viktigt att lägga märke till att Benjamin förekommer två gånger. Det beror inte på att vi har två Benjamin i kundtabellen, utan på att han har två registrerade adresser.</escape>

### Varför använder vi alias?

Vi har tidigare sett hur vi ger tabeller kortare namn:

```sql
FROM customers AS c
INNER JOIN addresses AS a
```

När vi skriver `c.name` menar vi kolumnen `name` i tabellen som vi kallar `c`. `a.city` pekar på kolumnen `city` i `a`.

Det är särskilt användbart när två tabeller har kolumner med samma namn, till exempel `id`.

Utan prefixet skulle `SELECT id` vara tvetydigt i en fråga där båda tabellerna har en kolumn som heter `id`.

### JOIN och WHERE har olika uppgifter

Nu vill vi veta vilka kunder som har en adress i Storfors.

```sql
SELECT
    c.name,
    a.street,
    a.city
FROM customers AS c
INNER JOIN addresses AS a
    ON a.customer_id = c.id
WHERE a.city = 'Storfors';
```

| name | street | city |
|---|---|---|
| Benjamin | Storgatan 4 | Storfors |
| Olof | Parkvägen 2 | Storfors |

`ON` beskriver **hur tabellerna hör ihop**.

`WHERE` beskriver **vilka av de kombinerade raderna vi vill ha**.

Det är en användbar skillnad att hålla fast vid även när frågorna blir mer komplicerade.

### LEFT JOIN – behåll även rader utan matchning

En `INNER JOIN` visar bara kombinationer som har en matchning i båda tabellerna.

Men vad händer om vi vill se **alla kunder**, även dem som ännu inte har någon registrerad adress?

```sql
SELECT
    c.name,
    a.city
FROM customers AS c
LEFT JOIN addresses AS a
    ON a.customer_id = c.id
ORDER BY c.id, a.id;
```

| name | city |
|---|---|
| Benjamin | Hemmavan |
| Benjamin | Storfors |
| Olof | Storfors |
| Anaïs | Malmö |
| Beatrice | NULL |
| Anna | NULL |

`LEFT JOIN` behåller alla rader från den vänstra tabellen, `customers`. Där en matchande adress saknas får adresskolumnerna värdet `NULL` i resultatet.

Notera skillnaden mot Anaïs, vars adress finns men saknar gatuadress. `NULL` betyder alltså inte automatiskt att hela den relaterade raden saknas.

### Från id till begripligt namn

I kapitel 8 lade vi till `product_type_id` på produkterna.

**product_types**

| id | name |
|---|---|
| 1 | Roman |
| 2 | Novellsamling |

Nu kan vi visa produkternas titlar och deras produkttyp:

```sql
SELECT
    p.title,
    t.name AS product_type
FROM products AS p
INNER JOIN product_types AS t
    ON p.product_type_id = t.id
ORDER BY p.id;
```

| title | product_type |
|---|---|
| Vägen hem | Roman |
| Den blå staden | Roman |
| Vinterljus | Roman |
| Små historier | Novellsamling |
| Mellan raderna | Novellsamling |

Vi lagrar produkttypens namn på ett ställe, men kan visa det tillsammans med varje produkt när vi behöver det.

### JOIN tillsammans med gruppering

Vi kan också kombinera relationer och aggregering.

```sql
SELECT
    t.name AS product_type,
    COUNT(*) AS product_count
FROM products AS p
INNER JOIN product_types AS t
    ON p.product_type_id = t.id
GROUP BY t.id, t.name
ORDER BY t.id;
```

| product_type | product_count |
|---|---:|
| Roman | 3 |
| Novellsamling | 2 |

Det här liknar vår fråga från förra kapitlet, men resultatet har nu ett begripligt namn på varje grupp.

## Avancerat

### Vad händer om vi glömmer kopplingsvillkoret?

En äldre syntax för att kombinera tabeller är:

```sql
SELECT c.name, a.city
FROM customers AS c, addresses AS a
WHERE a.customer_id = c.id;
```

Den ger samma matchande kombinationer som vårt första `INNER JOIN`-exempel.

Men när tabellerna räknas upp med kommatecken och vi glömmer villkoret kombineras **varje kund med varje adress**.

Med fem kunder och fyra adresser ger det 20 kombinationer.

Det kallas en **kartesisk produkt** och kan också skrivas uttryckligen med `CROSS JOIN`:

```sql
SELECT c.name, a.city
FROM customers AS c
CROSS JOIN addresses AS a;
```

En kartesisk produkt är ibland avsiktlig, men ofta ett tecken på att vi har glömt beskriva hur informationen hör ihop.

Därför använder vi i regel tydlig `JOIN ... ON`-syntax när vi kombinerar relaterade tabeller.

### Villkor vid LEFT JOIN

Vid `INNER JOIN` kan villkor ibland flyttas mellan `ON` och `WHERE` utan att resultatet ändras.

Vid `LEFT JOIN` behöver vi vara mer försiktiga.

```sql
SELECT c.name, a.city
FROM customers AS c
LEFT JOIN addresses AS a
    ON a.customer_id = c.id
WHERE a.city = 'Storfors';
```

Här kommer kunder utan matchande adresser inte med, eftersom deras `a.city` blir `NULL` och inte uppfyller `WHERE`-villkoret.

Jämför med:

```sql
SELECT c.name, a.city
FROM customers AS c
LEFT JOIN addresses AS a
    ON a.customer_id = c.id
   AND a.city = 'Storfors';
```

Här behåller vi fortfarande **alla kunder** från vänstersidan, men kopplar bara på adresser i Storfors.

Det är två olika informationsbehov, och båda är möjliga att uttrycka korrekt.

### Fler än två tabeller

När vi börjar registrera beställningar kan vi ha en tabell `orders` som refererar till `customers` och en tabell `order_items` som refererar till `orders` och `products`.

Då kan en fråga koppla samman flera relationer:

```sql
SELECT
    o.id AS order_id,
    c.name AS customer_name,
    p.title,
    oi.quantity
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.id
INNER JOIN order_items AS oi
    ON oi.order_id = o.id
INNER JOIN products AS p
    ON oi.product_id = p.id;
```

Vi har ännu inte infört `orders` och `order_items` i vår praktiska modell. Exemplet visar vart relationerna kan leda.

Varje rad i resultatet beskriver här **en orderrad**, inte en hel order. En order med flera produkter kommer därför att förekomma på flera rader.

Det är avgörande när vi senare räknar och summerar.

### Varför en JOIN kan förändra antalet rader

En vanlig missuppfattning är att en `JOIN` bara lägger till kolumner.

Men när en kund har flera adresser ger kopplingen flera resultatrader för samma kund.

Om vi sedan skriver `COUNT(*)` räknar vi de kombinerade raderna, inte nödvändigtvis antalet unika kunder.

Det är ofta lämpligt att fråga: **Vad representerar en rad i det här resultatet?**

I våra exempel har den ibland representerat en kund, ibland en kundadress och ibland en orderrad.

### Olika slags JOIN

Utöver `INNER JOIN` och `LEFT JOIN` finns bland annat:

| JOIN | Princip |
|---|---|
| `INNER JOIN` | Bara matchande kombinationer |
| `LEFT JOIN` | Alla rader till vänster, plus matchningar |
| `RIGHT JOIN` | Alla rader till höger, plus matchningar |
| `FULL OUTER JOIN` | Alla rader från båda sidor, med matchningar där sådana finns |
| `CROSS JOIN` | Alla möjliga kombinationer |

Stödet varierar mellan databassystem. Till exempel har MySQL inget inbyggt `FULL OUTER JOIN`, och SQLite saknar `RIGHT JOIN` och `FULL OUTER JOIN` i äldre versioner.[^joins]

[^joins]: SQLite lade till `RIGHT JOIN` och `FULL OUTER JOIN` i version 3.39.0. MySQL har `LEFT JOIN` och `RIGHT JOIN` men inte ett direkt `FULL OUTER JOIN`-uttryck. Mer om detta i dialekthäftena.

### Från relationer till en ny modell av informationen

När vi skriver en Query som:

```sql
SELECT
    c.name AS customer_name,
    a.street,
    a.city
FROM customers AS c
INNER JOIN addresses AS a
    ON a.customer_id = c.id;
```

får vi en tabellformad representation som inte finns som en egen lagrad tabell.

Vår lagringsmodell består av `customers` och `addresses`, men resultatet beskriver i praktiken **kundadresser**.

Det är ett annat perspektiv på samma information.

Senare i boken kommer vi att använda **Views** för att ge sådana representationer egna namn och göra dem återanvändbara.

Därmed kan vi skilja mellan hur informationen organiseras för lagring och hur vi modellerar den för olika frågor och användare.

## Reflektion

1. Varför kan det vara bättre att lagra kundernas namn och adresser i olika tabeller, även när vi ofta vill visa dem tillsammans?
2. Vad representerar en rad efter att vi har kopplat en kund till flera adresser?
3. Hur skiljer sig en ny tabell från ett nytt sätt att betrakta informationen i flera befintliga tabeller?

# 21. Index och Query-prestanda

När vi skriver en Query beskriver vi vilken information vi vill ha. Vi säger inte nödvändigtvis exakt **hur** databashanteraren ska hitta den.

Det spelar kanske ingen större roll när bokhandeln har fem produkter och några kunder. Men vad händer om den får hundratusentals produkter, miljontals beställningar och många användare som söker samtidigt?

Samma Query kan fortfarande ge rätt resultat – men ta mycket olika lång tid att utföra.

För att förstå varför behöver vi skilja mellan **Queryns betydelse** och **databasens arbete med att utföra den**.

## Grund

### Hur hittar databasen en rad?

Vi börjar med vår bekanta tabell `products`:

| id | title | price | stock | product_type_id |
|---|---|---:|---:|---:|
| 1 | Vägen hem | 200.00 | 12 | 1 |
| 2 | Den blå staden | 150.00 | 0 | 1 |
| 3 | Vinterljus | 249.00 | 4 | 1 |
| 4 | Små historier | 120.00 | 25 | 2 |
| 5 | Mellan raderna | 180.00 | 9 | 2 |

Vi vill hämta en bestämd produkt:

```sql
SELECT *
FROM products
WHERE id = 3;
```

Databasen skulle kunna läsa varje rad och kontrollera om `id` är `3`.

Det kallas ofta en **tabellskanning** (*table scan*). Med fem rader är det knappast ett problem. Med fem miljoner rader kan det däremot bli dyrt.

Ett **index** ger databashanteraren en annan möjlighet att hitta rätt rader.

### Vad är ett index?

Vi kan jämföra ett databasindex med ett sakregister i en bok.

Om vi söker efter ordet *transaktion* kan vi slå upp det i registret och få en hänvisning till rätt sidor, i stället för att läsa hela boken från början.

Ett databasindex fungerar inte exakt som ett bokregister, men grundidén är densamma: **en extra struktur hjälper oss att hitta information utan att undersöka allt**.

Många vanliga databasindex bygger på trädstrukturer, ofta B-träd eller närbesläktade varianter. Exakt utformning varierar mellan databassystemen.

### Primärnyckeln har ofta redan ett index

Vi har tidigare bestämt att `id` är primärnyckel i `products`.

I många SQL-system skapas eller används ett index automatiskt för primärnyckeln.

Det innebär att vår Query med `WHERE id = 3` ofta redan kan använda ett index.

Vi ska därför **inte automatiskt skapa ännu ett index på `id`**.

Hur primärnyckeln lagras och vilka index som finns kan vi undersöka i databassystemets metadata.[^primary-index]

[^primary-index]: MySQL/InnoDB lagrar normalt tabellens data organiserade kring ett klustrat primärnyckelindex. PostgreSQL skapar ett unikt B-trädsindex för en primärnyckel, men tabellens rader lagras normalt separat. SQL Server kan använda klustrade eller icke-klustrade index.

### Skapa ett index med CREATE INDEX

Anta att bokhandelns personal ofta söker efter produkter utifrån titeln:

```sql
SELECT id, title, price
FROM products
WHERE title = 'Vägen hem';
```

Vi kan skapa ett index på `title`:

```sql
CREATE INDEX idx_products_title
ON products (title);
```

Nu finns det en indexstruktur som databashanteraren **kan välja** att använda för sökningar på titlar.

Att skapa ett index innebär inte att varje relevant Query alltid använder det. Databashanteraren väljer en exekveringsplan utifrån bland annat tabellstorlek, statistik och vad den uppskattar blir effektivast.

Med vår lilla övningstabell kan en fullständig skanning fortfarande vara enklare.

### Flera kolumner i ett index

Anta att vi ofta vill hitta tillgängliga produkter av en viss typ, sorterade efter pris:

```sql
SELECT title, price
FROM products
WHERE product_type_id = 1
  AND stock > 0
ORDER BY price;
```

Vi kan överväga ett sammansatt index:

```sql
CREATE INDEX idx_products_type_price
ON products (product_type_id, price);
```

Indexet är ordnat med `product_type_id` som första indexkolumn och `price` som andra.

Det kan vara användbart när vi filtrerar på produkttyp och därefter vill läsa produkterna i prisordning.

Men vårt villkor `stock > 0` kan fortfarande kräva ytterligare arbete. Ett index löser inte automatiskt alla delar av en Query.

### Ordningen i ett sammansatt index

Ordningen mellan indexkolumnerna spelar roll.

Ett index på:

```sql
(product_type_id, price)
```

är inte generellt likvärdigt med ett index på:

```sql
(price, product_type_id)
```

Det första är ofta mer användbart om vi börjar med att söka på en bestämd produkttyp.

Vi kan tänka på det som ett register sorterat först efter produkttyp, sedan efter pris inom varje produkttyp.

Det finns undantag och olika optimeringar i olika system, men ordningen är en viktig del av indexets utformning.

### Hur vet vi om ett index används?

För att undersöka hur databashanteraren planerar att köra en Query kan vi använda `EXPLAIN`:

```sql
EXPLAIN
SELECT id, title, price
FROM products
WHERE title = 'Vägen hem';
```

I MySQL kan resultatet bland annat ge information om vilka tabeller som läses, vilka index som skulle kunna användas och vilket index som valdes.

Vi kan också undersöka hur en Query planeras när vi filtrerar och sorterar:

```sql
EXPLAIN
SELECT title, price
FROM products
WHERE product_type_id = 1
ORDER BY price;
```

**En exekveringsplan** beskriver vilka operationer databasen tänker använda. Det är en möjlighet att förstå *hur* databasen försöker besvara Queryn, inte bara *vad* Queryn betyder.

Vi redovisar inget fast resultat från `EXPLAIN` här, eftersom det beror på databas, version, statistik, index och mängden data.[^explain]

[^explain]: MySQL, PostgreSQL, SQLite och SQL Server har verktyg för att se exekveringsplaner, men kommandon och presentationsformat varierar. MySQL och PostgreSQL använder exempelvis `EXPLAIN`, SQLite erbjuder `EXPLAIN QUERY PLAN` och SQL Server har egna sätt att visa uppskattade och faktiska exekveringsplaner.

## Avancerat

### Att uppskatta kostnaden för en Query

En databashanterare kan ofta välja mellan flera vägar till samma resultat.

Den kan läsa hela tabellen, följa ett index, kombinera olika index eller välja mellan flera sätt att genomföra en `JOIN`.

Optimeraren försöker uppskatta kostnaden för alternativen utifrån tillgänglig information, exempelvis:

- Hur många rader en tabell innehåller.
- Hur stor andel av raderna som sannolikt uppfyller ett villkor.
- Vilka index som finns och hur de är organiserade.
- Kostnaden för att läsa data, sortera och kombinera rader.

Det är viktigt att förstå att en plan kan bygga på **uppskattningar**, inte fullständig förhandskunskap om resultatet.

### Selektivitet – hur mycket väljer vi ut?

Anta att nästan alla produkter har `stock > 0`.

Ett index på `stock` kanske inte hjälper särskilt mycket för:

```sql
SELECT *
FROM products
WHERE stock > 0;
```

Om Queryn ändå ska hämta nästan hela tabellen kan det vara effektivare att läsa den direkt.

Men ett index på en kolumn som ofta används för att hitta **en mycket liten andel** av raderna kan vara värdefullt.

Det brukar beskrivas med begreppet **selektivitet**.

Samtidigt räcker det inte att en kolumn har många olika värden för att ett index alltid ska vara bra. Vi måste se till de faktiska sökningarna.

### Index hjälper även vid JOIN

Vi har kopplat produkter till produkttyper med `product_type_id`.

```sql
SELECT
    p.title,
    t.name AS product_type
FROM products AS p
INNER JOIN product_types AS t
    ON p.product_type_id = t.id;
```

Index på kolumner som används i relationsvillkor kan hjälpa databashanteraren att hitta matchande rader.

Men det betyder inte att varje `JOIN` alltid bör använda index. Om stora delar av tabellerna ändå behöver kombineras kan databasen välja andra strategier.

Index på främmande nycklar är därför ofta användbara, men vi ska inte utgå från att de skapas automatiskt i alla SQL-system.[^fk-index]

[^fk-index]: MySQL/InnoDB kräver index som stöd för främmande nyckelrelationer och kan skapa saknade stödindex automatiskt. PostgreSQL skapar däremot inte automatiskt index på den refererande kolumnen enbart för att en främmande nyckel definieras.

### Covering index – när indexet räcker

Titta på denna Query:

```sql
SELECT product_type_id, price
FROM products
WHERE product_type_id = 1
ORDER BY price;
```

Om vi har ett sammansatt index på `(product_type_id, price)` kan indexet i vissa system innehålla allt som behövs för att besvara Queryn.

Då behöver databashanteraren kanske inte läsa själva tabellraderna separat. Detta brukar kallas ett **covering index**, eller en index-only-liknande läsning.

Men en sådan optimering beror på indexets lagring, databassystemet och ibland synlighetsinformation om raderna.

### Varför fungerar inte alltid en indexerad sökning?

Ett index på `title` kan vara användbart när vi jämför en titel med ett exakt värde:

```sql
WHERE title = 'Vägen hem'
```

Det kan ibland också hjälpa för ett prefix:

```sql
WHERE title LIKE 'Vägen%'
```

Men en sökning med ett inledande jokertecken:

```sql
WHERE title LIKE '%vägen%'
```

kan ofta inte utnyttja ett vanligt B-trädsindex på samma sätt.

Vilket index som kan användas påverkas också av kollationer och databasens hantering av text.

Det här är ett exempel på att **hur vi uttrycker ett villkor** kan påverka vilka sökvägar databasen har tillgång till.

### När vi använder funktioner i villkor

Anta att vi vill jämföra ett omvandlat värde:

```sql
SELECT *
FROM products
WHERE LOWER(title) = 'vägen hem';
```

Ett vanligt index på `title` är inte nödvändigtvis direkt användbart för villkoret `LOWER(title)`.

Vissa databassystem erbjuder uttrycksindex eller andra lösningar för sådana fall. Men vi behöver undersöka vilket stöd den faktiska databasen har.

Det är alltså inte så att SQL-funktioner är problematiska i sig, utan att de kan förändra **vilket uttryck databasen behöver söka efter**.

### Index har en kostnad

Varje index tar lagringsutrymme.

När vi lägger till en produkt eller ändrar ett indexerat värde kan databasen också behöva uppdatera indexstrukturen.

Därför påverkar index inte bara läsningar utan även `INSERT`, `UPDATE` och `DELETE`.

Det skapar en avvägning:

| Fler index kan ge | Men innebär också |
|---|---|
| Snabbare sökningar för vissa Queries | Mer lagringsutrymme |
| Effektivare vissa `JOIN` och sorteringar | Mer arbete vid förändringar av data |
| Bättre stöd för vissa åtkomstmönster | Fler strukturer att underhålla och förstå |

Vi bör alltså inte skapa index på varje kolumn bara för säkerhets skull.

### Att undersöka en verklig prestandafråga

Anta att personalen upplever att en produktsökning blivit långsam.

Vi kan arbeta systematiskt:

1. **Beskriv problemet.** Vilken Query är långsam, hur ofta körs den och hur mycket data läser den?
2. **Studera planen.** Använd `EXPLAIN` och undersök tabellskanningar, sorteringar, index och uppskattade radantal.
3. **Formulera en hypotes.** Skulle exempelvis ett index på en viss kombination av kolumner hjälpa?
4. **Prova och mät.** Jämför samma Query och liknande data före och efter ändringen.
5. **Värdera helheten.** Förbättrades läsningen utan att skrivningar, lagringskostnad eller andra Queries påverkades orimligt mycket?

I flera databassystem går det också att mäta faktisk exekvering och jämföra uppskattade med verkliga radantal. Sådana mätningar behöver göras med omsorg: att köra en Query kan belasta systemet, och mätresultat påverkas av cache och parallella aktiviteter.[^analyze]

[^analyze]: PostgreSQL erbjuder `EXPLAIN ANALYZE` och nyare MySQL-versioner har `EXPLAIN ANALYZE`. De kör normalt Queryn och mäter exekveringen. För dataförändrande satser behöver detta särskild försiktighet eftersom själva förändringen kan utföras.

### Prestanda handlar också om modellering

Vi har tidigare lärt oss att tabeller ska beskriva tydliga företeelser och relationer.

Nu kan vi se att datamodellen påverkar vilka Queries som behöver skrivas och vilka index som är användbara.

En modell med tydliga nycklar och relationer gör det ofta lättare att förstå hur information ska kombineras. Men en väl normaliserad modell är inte automatiskt optimal för varje analytiskt informationsbehov.

I vissa system kan vi behöva komplettera den operativa modellen med Views, särskilda sammanställningar eller andra representationsformer.

Det betyder inte att vi ska överge våra principer om dataintegritet. Det betyder att vi måste förstå **vilken användning en viss modell är byggd för**.

### Rätt svar och rätt arbetsinsats

Två Queries kan ge exakt samma resultat men kräva olika mycket arbete av databashanteraren.

Och samma Query kan köras med olika exekveringsplaner när mängden data förändras.

Vi behöver därför kunna resonera på två nivåer:

**Vad betyder vår Query?** Vilken information beskriver resultatet?

**Hur kan databasen ta fram det?** Vilka strukturer, operationer och resurser behövs?

Att förstå båda nivåerna hjälper oss att skapa system som inte bara ger korrekta svar, utan också fungerar när verksamheten växer.

## Reflektion

1. Varför kan ett index vara mycket användbart för en Query men nästan värdelöst för en annan?
2. Varför skapar vi inte bara så många index som möjligt?
3. Vad är skillnaden mellan att förbättra en Querys logiska tydlighet och att förbättra dess faktiska exekveringsprestanda?

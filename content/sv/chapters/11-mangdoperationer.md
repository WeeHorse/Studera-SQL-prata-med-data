# 11. SET-operationer

I en bokhandel kan vi ställa frågor som handlar om två olika grupper av information.

Vilka kunder har en adress i Malmö **eller** Storfors? Vilka har adresser i **båda** städerna? Och vilka har en adress i den ena staden **men inte** i den andra?

Vi har redan använt `JOIN` för att kombinera tabeller och subqueries för att låta en fråga använda resultatet av en annan.

Nu ska vi kombinera **resultaten från flera frågor**. SQL har särskilda mängdoperationer för detta: `UNION`, `INTERSECT` och `EXCEPT`.

## Grund

### Två Queries med samma slags resultat

Vi fortsätter med kunderna och deras adresser. För att kunna undersöka överlappningar tänker vi oss att vi lägger till tre adresser (id 5–7). De ingår inte i den nedladdningsbara grunddatabasen, utan är ett utökat exempel för det här kapitlet.

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
| 5 | 1 | Strandgatan 7 | Malmö |
| 6 | 4 | Torget 3 | Malmö |
| 7 | 5 | Skolgatan 8 | Storfors |

Vi kan ta fram kundernas id för adresser i Storfors:

```sql
SELECT customer_id
FROM addresses
WHERE city = 'Storfors';
```

Resultat: `1`, `2`, `5`.

Och kunder med adresser i Malmö:

```sql
SELECT customer_id
FROM addresses
WHERE city = 'Malmö';
```

Resultat: `3`, `1`, `4`.

Båda frågorna ger samma **slags resultat**: en kolumn som innehåller kund-id. Därför kan vi kombinera dem med mängdoperationer.

### UNION – förena resultaten

Vi vill veta vilka kunder som har en adress i Storfors **eller** Malmö.

```sql
SELECT customer_id
FROM addresses
WHERE city = 'Storfors'

UNION

SELECT customer_id
FROM addresses
WHERE city = 'Malmö';
```

Resultatet innehåller kund-id `1`, `2`, `3`, `4` och `5`, var och en en gång.

`UNION` förenar resultat från flera frågor och tar som standard bort dubbletter.

Att Benjamin har adresser i båda städerna gör alltså inte att kund-id `1` visas två gånger.

### UNION ALL – behåll alla rader

Om vi i stället vill behålla alla resultatrader använder vi `UNION ALL`:

```sql
SELECT customer_id
FROM addresses
WHERE city = 'Storfors'

UNION ALL

SELECT customer_id
FROM addresses
WHERE city = 'Malmö';
```

Nu får vi sex rader. Kund-id `1` förekommer två gånger eftersom Benjamin har en adress i vardera staden.

Skillnaden är viktig:

- `UNION` ger ett resultat utan dubbletter.
- `UNION ALL` bevarar samtliga rader från frågorna.

Om vi behöver behålla information om antalet förekomster är `UNION ALL` det naturliga valet.

### INTERSECT – det som finns i båda resultaten

Vilka kunder har adresser i **både** Storfors och Malmö?

```sql
SELECT customer_id
FROM addresses
WHERE city = 'Storfors'

INTERSECT

SELECT customer_id
FROM addresses
WHERE city = 'Malmö';
```

Resultatet innehåller bara `1`, alltså Benjamin.

`INTERSECT` väljer de rader som förekommer i båda resultaten.

Vi kombinerar inte kolumner från två tabeller, som vid en `JOIN`. Vi jämför i stället två resultat med samma struktur.

### EXCEPT – det som finns i det ena men inte det andra

Vilka kunder har en adress i Storfors, men **inte** i Malmö?

```sql
SELECT customer_id
FROM addresses
WHERE city = 'Storfors'

EXCEPT

SELECT customer_id
FROM addresses
WHERE city = 'Malmö';
```

Resultatet innehåller `2` och `5`, alltså Olof och Anna.

`EXCEPT` väljer rader från det första resultatet som inte förekommer i det andra.

Ordningen mellan frågorna spelar därför roll. Om vi byter plats på dem får vi i stället kunder med adress i Malmö men inte i Storfors.

### Från id till kundnamn

Mängdoperationerna ovan ger kund-id. Men vi vill kanske se namn i stället.

Vi kan kombinera mängdoperationer med de konstruktioner vi redan kan:

```sql
SELECT name
FROM customers
WHERE id IN (
    SELECT customer_id
    FROM addresses
    WHERE city = 'Storfors'

    INTERSECT

    SELECT customer_id
    FROM addresses
    WHERE city = 'Malmö'
);
```

| name |
|---|
| Benjamin |

Här får `INTERSECT` först fram kund-id som förekommer i båda städerna. Den yttre frågan hämtar sedan kundernas namn.

### Krav på Queries och deras resultat

För att kombinera två frågor med `UNION`, `INTERSECT` eller `EXCEPT` måste de ge **samma antal kolumner**. Kolumnernas datatyper måste dessutom vara förenliga så att resultaten kan kombineras.

Vi kan exempelvis kombinera två frågor som båda ger `customer_id`.

Däremot kan vi inte utan vidare förena en fråga med en kolumn och en annan fråga med tre kolumner.

Kolumnernas namn i det sammansatta resultatet hämtas vanligtvis från den första frågan.

## Avancerat

### Mängder och rader

I matematiken innehåller en mängd varje element högst en gång.

Men SQL arbetar ofta med resultat där samma värden kan förekomma på flera rader.

Detta brukar beskrivas som en skillnad mellan **mängdsemantik** och **multimängdssemantik** (*bag semantics*).

`UNION`, `INTERSECT` och `EXCEPT` tar normalt bort upprepade resultatrader. `UNION ALL` behåller dem.

Vissa SQL-dialekter har även `INTERSECT ALL` och `EXCEPT ALL`, som tar hänsyn till antalet förekomster. Stödet varierar mellan databassystem.

### Dubbletter handlar om hela raden

Anta att två frågor ger en kunds namn och stad:

```sql
SELECT c.name, a.city
FROM customers AS c
INNER JOIN addresses AS a
    ON a.customer_id = c.id;
```

Då betraktas `('Benjamin', 'Malmö')` och `('Benjamin', 'Storfors')` som **olika rader**, trots att kundnamnet är samma.

När `UNION` tar bort dubbletter jämförs hela resultatraden, inte en enskild kolumn som vi själva tycker är viktig.

Det betyder också att två olika kunder med samma namn kan se ut som en dubblett om vi bara väljer `name`. Om kundernas identitet spelar roll bör vi också välja exempelvis `id`.

### Ordningen i resultatet

En mängdoperation garanterar inte vilken ordning raderna visas i.

Vill vi sortera det sammansatta resultatet skriver vi en `ORDER BY` efter hela konstruktionen:

```sql
SELECT customer_id
FROM addresses
WHERE city = 'Storfors'

UNION

SELECT customer_id
FROM addresses
WHERE city = 'Malmö'

ORDER BY customer_id;
```

Här sorterar vi det **gemensamma resultatet**.

### Prioritet och parenteser

När vi kombinerar flera mängdoperationer måste vi tänka på i vilken ordning de utvärderas.

`INTERSECT` har enligt SQL-standarden högre prioritet än `UNION` och `EXCEPT`, men vi bör inte förutsätta att alla dialekter hanterar sammansatta uttryck identiskt.

Med parenteser eller namngivna mellanresultat kan vi göra avsikten tydligare.

Det är ofta bättre att dela upp en svår mängdoperation i flera steg än att förlita sig på att läsaren känner till operatorernas prioritet.

### När använder vi JOIN, subqueries och mängdoperationer?

De tre konstruktionerna löser delvis överlappande, men olika slags problem.

| Konstruktion | Naturlig användning |
|---|---|
| `JOIN` | Kombinera relaterad information från flera tabeller |
| Subquery | Använda ett Query-resultat som del av en annan fråga |
| `UNION` | Förena resultatrader från flera frågor |
| `INTERSECT` | Hitta resultatrader som finns i båda frågorna |
| `EXCEPT` | Hitta resultatrader som finns i den första men inte den andra frågan |

Vi kan exempelvis använda `EXISTS` för att ta reda på om en kund har en adress i båda städerna. Resultatet kan bli detsamma som med `INTERSECT`.

Vi väljer då den konstruktion som tydligast beskriver vårt informationsbehov. Precis som för subqueries och `JOIN` bör vi inte anta att ett skrivsätt alltid är snabbare utan att undersöka exekveringsplanen.

### Dialektskillnader

`UNION` och `UNION ALL` har brett stöd.

`INTERSECT` och `EXCEPT` finns i SQL-standarden och stöds av bland annat PostgreSQL, SQLite och nyare MySQL-versioner. MySQL införde dessa operatorer i version 8.0.31.[^set-ops]

SQL Server stöder också `INTERSECT` och `EXCEPT`, men vissa andra delar av syntaxen och stödet för `ALL`-varianter skiljer sig åt.

[^set-ops]: Äldre MySQL-versioner saknar `INTERSECT` och `EXCEPT`. Exemplen i detta kapitel förutsätter en SQL-miljö som stöder dem. För äldre versioner behöver motsvarande informationsbehov uttryckas på andra sätt, till exempel med `EXISTS` och `NOT EXISTS`.

### Från flera frågor till ett begrepp

När vi tar fram ”kunder med adresser i både Malmö och Storfors” har vi definierat en grupp som inte finns lagrad som en egen tabell.

Gruppen uppstår genom villkoren i våra frågor.

Vi kan alltså skapa **meningsfulla kategorier ur befintlig information**, utan att behöva lagra ytterligare en kolumn på kunderna för varje möjlig kategori.

Det knyter an till vår tidigare diskussion om datamodellering och Views: vi kan skapa nya sätt att betrakta informationen genom att formulera frågor om den.

## Reflektion

1. Varför kan det vara viktigt att behålla dubbletter i vissa resultat men ta bort dem i andra?
2. Vad är skillnaden mellan att kombinera tabeller med `JOIN` och att kombinera Query-resultat med `UNION`?
3. När vi skapar en grupp som ”kunder med adresser i båda städerna”, är det då en egenskap hos kunden eller ett resultat av hur vi väljer att undersöka informationen?

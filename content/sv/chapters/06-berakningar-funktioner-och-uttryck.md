# 6. Beräkningar, funktioner och uttryck

Informationen i en databas behöver inte alltid presenteras exakt som den är lagrad.

En bokhandel lagrar exempelvis priset på en bok, men kanske vill visa priset inklusive en viss avgift eller beräkna ett rabatterat pris. Ett förnamn och ett efternamn kan behöva visas tillsammans. Vi kan också vilja beskriva ett lagersaldo som ”I lager” eller ”Slut i lager”.

Med SQL kan vi inte bara hämta information. Vi kan också **beräkna och presentera nya värden utifrån den information som redan finns**.

## Grund

### Uttryck i SELECT

Vi har hittills valt kolumner med `SELECT`:

```sql
SELECT name, email
FROM customers;
```

Men `SELECT` kan också innehålla **uttryck**. Ett uttryck är något som databasen kan beräkna till ett värde.

Vi kan börja helt utan en tabell, med `SELECT 10 + 5;`.

Resultatet blir `15`.

Vi kan använda vanliga räkneoperatorer:

| Operator | Betydelse |
|---|---|
| `+` | Addition |
| `-` | Subtraktion |
| `*` | Multiplikation |
| `/` | Division |

Precis som i vanlig matematik kan vi styra beräkningsordningen med parenteser: `SELECT (100 + 50) * 2;`.

### Beräkningar med kolumner

Nu utökar vi bokhandelns databas med en tabell för produkter.

**products**

| id | title | price | stock |
|---|---|---|---|
| 1 | Vägen hem | 200.00 | 12 |
| 2 | Den blå staden | 150.00 | 0 |
| 3 | Vinterljus | 249.00 | 4 |
| 4 | Små historier | 120.00 | 25 |

Här lagrar vi pris och lagersaldo för varje produkt.

Vi kan beräkna ett pris med 10 procent rabatt utan att ändra det lagrade priset:

```sql
SELECT title, price * 0.90
FROM products;
```

Beräkningen görs för varje rad i resultatet.

### Namnge beräknade kolumner

Resultatet blir tydligare om vi ger beräkningen ett namn:

```sql
SELECT
    title,
    price,
    price * 0.90 AS discounted_price
FROM products;
```

| title | price | discounted_price |
|---|---:|---:|
| Vägen hem | 200.00 | 180.00 |
| Den blå staden | 150.00 | 135.00 |
| Vinterljus | 249.00 | 224.10 |
| Små historier | 120.00 | 108.00 |

`AS` ger uttrycket ett **alias**, precis som vi tidigare kunde ge en kolumn ett annat namn.

Det är fortfarande samma tabell och samma lagrade värden. Vi har bara skapat en ny kolumn i vårt resultat.

### Funktioner

En **funktion** tar emot ett eller flera värden och ger oss ett resultat.

Vi kan exempelvis avrunda ett tal med `ROUND()`:

```sql
SELECT ROUND(12.345, 2);
```

Resultatet är `12.35`.

Vi kan också använda funktioner tillsammans med våra kolumner:

```sql
SELECT
    title,
    ROUND(price * 0.90, 2) AS discounted_price
FROM products;
```

En funktion kan alltså användas som en del av ett större uttryck.

### Textfunktioner

SQL har även funktioner för att arbeta med text.

`CONCAT()` sätter ihop flera textvärden:

```sql
SELECT CONCAT('Hej', ' ', 'Anna');
```

Resultatet blir `Hej Anna`.

Vi kan exempelvis skapa en kort produktbeskrivning:

```sql
SELECT CONCAT('Bok: ', title) AS description
FROM products;
```

Andra användbara textfunktioner är:

| Funktion | Användning |
|---|---|
| `CHAR_LENGTH(text)` | Antal tecken i en text |
| `UPPER(text)` | Gör text till versaler |
| `LOWER(text)` | Gör text till gemener |
| `SUBSTRING(text FROM start FOR antal)` | Hämtar en del av texten |
| `REPLACE(text, gammalt, nytt)` | Ersätter text |

Exempel:

```sql
SELECT UPPER('bokhandel');
```

ger `BOKHANDEL`.

Och:

```sql
SELECT REPLACE('Min bok', 'Min', 'Din');
```

ger `Din bok`.

Vissa funktioner har olika namn eller syntax i olika SQL-dialekter.[^strings]

[^strings]: `CHAR_LENGTH` används i MySQL och PostgreSQL; SQL Server använder exempelvis `LEN`, och SQLite använder `length`. Syntaxen för `SUBSTRING` varierar också. Exempelvis används ofta `SUBSTRING(text, start, antal)` i MySQL. Textsammanfogning med `CONCAT` eller `||` varierar mellan dialekterna.

### CASE – olika resultat beroende på villkor

Ibland vill vi att ett uttryck ska ge olika resultat beroende på ett villkor.

Vi kan exempelvis visa en text som beskriver om en produkt finns i lager:

```sql
SELECT
    title,
    stock,
    CASE
        WHEN stock > 0 THEN 'I lager'
        ELSE 'Slut i lager'
    END AS stock_status
FROM products;
```

| title | stock | stock_status |
|---|---:|---|
| Vägen hem | 12 | I lager |
| Den blå staden | 0 | Slut i lager |
| Vinterljus | 4 | I lager |
| Små historier | 25 | I lager |
| Mellan raderna | 9 | I lager |

`CASE` är ett **uttryck** som ger ett värde. Vi använder `WHEN` för att ange ett villkor, `THEN` för resultatet och `ELSE` för alternativet om inget villkor passar.

Vi kan också ha flera `WHEN`:

```sql
SELECT
    title,
    CASE
        WHEN stock = 0 THEN 'Slut'
        WHEN stock < 5 THEN 'Få kvar'
        ELSE 'I lager'
    END AS stock_status
FROM products;
```

Databasen väljer resultatet för det **första** villkor som är uppfyllt.

Det här är SQL:s sätt att skapa villkorade värden utan att behöva ändra informationen i tabellen.

## Avancerat

### NULL i beräkningar

Vad händer om vi inte känner till priset på en produkt?

Om `price` är `NULL` blir resultatet av exempelvis `price * 0.90` också `NULL`.

Det är rimligt: vi kan inte beräkna ett rabatterat pris om vi inte vet utgångspriset.

SQL har funktionen `COALESCE()`, som väljer det första argumentet som inte är `NULL`:

```sql
SELECT COALESCE(NULL, 100);
```

ger `100`.

Vi skulle kunna skriva:

```sql
SELECT
    title,
    COALESCE(price, 0) AS display_price
FROM products;
```

Men detta kräver eftertanke. Ett saknat pris betyder inte nödvändigtvis att produkten är gratis.

`COALESCE` kan alltså vara praktiskt för att hantera saknade värden, men vi behöver själva avgöra vad ett ersättningsvärde betyder.

### Datatyper påverkar beräkningen

Värdet `'100'` är text, medan `100` är ett tal.

Vissa databassystem försöker automatiskt omvandla värden mellan olika datatyper. Det kan fungera, men också ge oväntade resultat.

När vi behöver göra en uttrycklig omvandling kan vi använda `CAST`:

```sql
SELECT CAST('100' AS INTEGER);
```

Detta uttrycker tydligt att textvärdet ska tolkas som ett heltal.[^types]

[^types]: Datatypernas namn och reglerna för automatisk konvertering varierar mellan databassystem. Även stöd för och beteende hos `CAST` kan skilja sig mellan olika typer.

### Beräknade värden eller lagrade värden?

Vi kan tänka oss att lagra både `price` och `discounted_price` i produkttabellen.

Men om rabatten alltid är 10 procent och priset senare ändras, behöver vi komma ihåg att även uppdatera rabattpriset.

Ett alternativ är att bara lagra grundpriset och beräkna rabattpriset när vi behöver det.

Det finns samtidigt situationer där ett beräknat värde bör sparas. En faktiskt genomförd beställning behöver exempelvis kunna bevara vilket pris kunden betalade, även om produktens aktuella pris senare förändras.

Skillnaden handlar om **vad som är en aktuell beräkning och vad som är ett historiskt faktum**.

Vi återkommer till detta när bokhandeln får ordrar och orderrader.

### Logik i frågor är inte alltid affärslogik

Med `CASE` kan vi exempelvis avgöra om ett lagersaldo ska visas som ”Få kvar”.

Det är en enkel regel för hur vi presenterar information.

Men ska databasen också bestämma när varor ska beställas, vilken leverantör vi ska använda och vem som ska godkänna inköpet?

Det är en annan typ av problem. En beräkning eller klassificering av data behöver inte betyda att hela verksamhetsprocessen bör byggas in i databasen.

Vi kommer tillbaka till gränsen mellan informationshantering och processer i bokens avslutande kapitel.

### Funktioner på många rader

Funktionerna vi använt hittills arbetar med värden i enskilda uttryck eller rader.

Men vi kanske också vill veta det sammanlagda lagervärdet för alla produkter eller det genomsnittliga produktpriset.

Då behöver vi kunna göra beräkningar **över flera rader samtidigt**.

Det är vad aggregeringsfunktioner som `SUM`, `COUNT` och `AVG` används till. Dem behandlar vi längre fram i boken.

## Reflektion

1. När är det bättre att beräkna ett värde i en fråga än att lagra det i databasen?
2. Varför kan det vara problematiskt att ersätta ett okänt värde med noll?
3. Vad är skillnaden mellan att visa att en produkt är ”Slut i lager” och att bestämma hur den ska beställas hem?

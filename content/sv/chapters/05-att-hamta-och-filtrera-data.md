# 5. Att hämta och filtrera data

Att ha mycket information är inte samma sak som att hitta det man behöver.

En bokhandel kanske har tusentals kunder, men just nu behöver vi bara veta vilka som har ett namn som börjar på B. Eller vilka adresser som finns registrerade i en viss stad.

Vi behöver kunna avgränsa informationen. Med SQL beskriver vi vilka uppgifter som är relevanta och låter databashanteraren hämta dem.

## Grund

### Att välja information med SELECT

Vi fortsätter med bokhandelns kunder. Vi har nu registrerat ytterligare några och lagt till deras födelsedatum i kolumnen `birthday`:

**customers**

| id | name | email | birthday |
|---|---|---|---|
| 1 | Benjamin | benjamin@example.com | 1968-04-12 |
| 2 | Olof | olof@example.com | 1982-09-03 |
| 3 | Anaïs | anais@example.com | 1995-06-21 |
| 4 | Beatrice | beatrice@example.com | 2000-02-15 |
| 5 | Anna | anna@example.com | 1975-11-08 |

Vi har redan sett att `SELECT` väljer kolumner. För att välja *vilka rader* som ska komma med använder vi `WHERE`.

### Villkor med WHERE

```sql
SELECT *
FROM customers
WHERE id = 2;
```

Resultat:

| id | name | email | birthday |
|---|---|---|---|
| 2 | Olof | olof@example.com | 1982-09-03 |

`WHERE` följs av ett **villkor**. En rad kommer med i resultatet när villkoret är uppfyllt.

Vi kan jämföra både tal och text, exempelvis med villkoret `name = 'Anna'`.

### Jämförelseoperatorer

De vanligaste operatorerna är:

| Operator | Betydelse |
|---|---|
| `=` | Lika med |
| `<>` | Inte lika med |
| `>` | Större än |
| `<` | Mindre än |
| `>=` | Större än eller lika med |
| `<=` | Mindre än eller lika med |

Villkoret `birthday > '1970-01-09'` väljer kunder födda efter den 9 januari 1970.

När vi jämför textvärden behöver vi vanligtvis skriva värdet inom enkla citattecken, som i `name = 'Anna'`.

Vi använder `<>` för ”inte lika med”. I flera databassystem fungerar även `!=`, men `<>` är den standardiserade formen.

### Kombinera villkor med AND och OR

Vi kan ställa flera krav samtidigt.

```sql
SELECT name, birthday
FROM customers
WHERE birthday >= '1980-01-01'
  AND birthday < '2000-01-01';
```

Här måste **båda** villkoren vara uppfyllda. Vi får Olof och Anaïs, som är födda under perioden 1980–1999.

Med `OR` räcker det att **minst ett** villkor är uppfyllt, som i `name = 'Anna' OR name = 'Olof'`.

Vi kan också använda `NOT` för att förneka ett villkor, exempelvis `NOT name = 'Olof'`.

### Söka inom ett intervall

När vi vill hitta värden mellan två gränser kan vi använda `BETWEEN`:

```sql
SELECT name, birthday
FROM customers
WHERE birthday BETWEEN '1980-01-01' AND '1999-12-31';
```

Det motsvarar villkoret `birthday >= '1980-01-01' AND birthday <= '1999-12-31'`. **Båda gränserna ingår** i `BETWEEN`.

### Söka bland flera värden

Om vi vill hitta kunder med några särskilda id-värden kan vi använda `IN`:

```sql
SELECT *
FROM customers
WHERE id IN (1, 3, 5);
```

Det är ofta enklare att läsa än en lång serie villkor med `OR`.

### Söka efter delar av text

Vi kanske bara vet att kundens namn börjar med bokstaven B.

Då använder vi `LIKE`:

```sql
SELECT *
FROM customers
WHERE name LIKE 'B%';
```

Mönstret `'B%'` betyder att namnet börjar med B och kan följas av vilka tecken som helst.

| Mönster | Betydelse |
|---|---|
| `'B%'` | Börjar med B |
| `'%a'` | Slutar med a |
| `'%ann%'` | Innehåller ann |
| `'_n%'` | Har n som andra tecken |

`%` betyder noll eller fler tecken, medan `_` betyder exakt ett tecken.

Om stora och små bokstäver räknas som likvärdiga vid sökning beror bland annat på databassystemets inställningar för textjämförelser.[^like]

[^like]: Skiftlägeskänslighet hos `LIKE` varierar mellan databassystem och inställningar, exempelvis kollationer. Räkna därför inte med att `'B%'` alltid ger exakt samma träffar i alla miljöer.

### Sortera resultat med ORDER BY

SQL garanterar inte någon särskild radordning om vi inte uttryckligen begär den.

Vi kan sortera på namn:

```sql
SELECT *
FROM customers
ORDER BY name;
```

Vi kan variera sorteringen utan att ändra resten av frågan:

| Sortering | Betydelse |
|---|---|
| `ORDER BY name DESC` | Namn i fallande ordning |
| `ORDER BY name, id` | Först namn, sedan id när namn är lika |

`ASC` betyder stigande ordning och är normalt standardvalet.

### Begränsa antalet rader

Ibland vill vi bara få ett fåtal rader tillbaka.

I MySQL kan vi exempelvis skriva:

```sql
SELECT *
FROM customers
ORDER BY id
LIMIT 3;
```

Det ger de tre kunderna med lägst id.

Vill vi hoppa över de första två och sedan hämta tre byter vi sista raden mot `LIMIT 3 OFFSET 2`. I MySQL kan vi även skriva `LIMIT 2, 3`, där det första talet anger **hur många rader vi hoppar över** och det andra **hur många rader vi hämtar**.

Var uppmärksam på att talens ordning är omvänd mellan de två skrivsätten. Kommasyntaxen stöds även av SQLite, men inte av PostgreSQL. I den här boken föredrar vi normalt `LIMIT ... OFFSET ...` eftersom det tydligare visar vad talen betyder.

`LIMIT` används i flera populära SQL-dialekter, men är inte den standardiserade syntaxen.[^limit]

[^limit]: MySQL, PostgreSQL och SQLite använder `LIMIT`. Standard-SQL har bland annat `FETCH FIRST ... ROWS ONLY` och `OFFSET ... FETCH`. SQL Server har också `TOP`.

Att sortera innan vi begränsar resultatet är viktigt. Annars vet vi inte *vilka* tre rader vi får.

### Kombinera allt

Nu kan vi formulera mer specifika frågor:

```sql
SELECT name, email
FROM customers
WHERE name LIKE 'B%'
ORDER BY name
LIMIT 3;
```

Vi hämtar namn och e-postadress för de kunder vars namn börjar på B, sorterar dem alfabetiskt och tar högst tre rader.

Notera ordningen på klausulerna: `SELECT`, `FROM`, `WHERE`, `ORDER BY` och `LIMIT`. Vi kommer att bygga vidare på den strukturen genom hela boken.

## Avancerat

### NULL – när ett värde saknas

Anta att vi har adresser där vissa uppgifter ännu inte är registrerade.

**addresses**

| id | customer_id | street | postal_code | city |
|---|---|---|---|---|
| 1 | 1 | Hemmagatan 1 | 124 56 | Hemmavan |
| 2 | 1 | Storgatan 4 | 154 32 | Storfors |
| 3 | 2 | Parkvägen 2 | 154 32 | Storfors |
| 4 | 3 | NULL | NULL | Malmö |

`NULL` betyder att det saknas ett känt värde. Det är inte samma sak som noll eller en tom textsträng.

Vi kan inte söka efter `NULL` med vanlig likhet: `WHERE street = NULL` fungerar inte som avsett. Vi använder i stället `IS NULL`:

```sql
SELECT *
FROM addresses
WHERE street IS NULL;
```

För att hitta adresser där gatan är registrerad använder vi `WHERE street IS NOT NULL`.

Varför? I SQL kan ett jämförelseuttryck vara **sant**, **falskt** eller **okänt**. En jämförelse med `NULL` ger normalt det tredje alternativet.

`WHERE` väljer endast rader där villkoret är sant.

### Operatorprioritet och parenteser

När vi kombinerar flera villkor kan ordningen påverka resultatet.

```sql
SELECT *
FROM customers
WHERE name = 'Anna'
   OR name = 'Olof' AND id > 2;
```

`AND` har högre prioritet än `OR`. Frågan betyder därför `name = 'Anna' OR (name = 'Olof' AND id > 2)`.

Vill vi något annat behöver vi sätta parenteserna själva:

```sql
SELECT *
FROM customers
WHERE (name = 'Anna' OR name = 'Olof')
  AND id > 2;
```

Parenteser är ofta värdefulla även när de inte är tekniskt nödvändiga. De gör avsikten tydligare.

### DISTINCT – bara unika resultat

Vi kanske vill veta i vilka städer våra kunder har registrerade adresser. Med `SELECT city FROM addresses` kan samma stad förekomma flera gånger.

Om vi bara vill ha varje stad en gång:

```sql
SELECT DISTINCT city
FROM addresses;
```

`DISTINCT` tar bort upprepade resultatrader. Om vi väljer flera kolumner är det **kombinationen av kolumnvärdena** som avgör om två rader betraktas som dubbletter.

### Rader är inte automatiskt en ordnad lista

En tabell kan se ut som en lista, men SQL:s resultat har ingen garanterad ordning utan `ORDER BY`.

Det är särskilt viktigt när vi använder `LIMIT` och `OFFSET`.

Anta att vi bygger en sida som visar tio kunder åt gången. Vi kan hämta de första tio, sedan hoppa över tio och hämta nästa tio.

Men om nya kunder läggs till mellan frågorna kan en sådan sidindelning ge överlappningar eller missa poster. För stabilare sidindelning behöver vi bestämma en entydig sortering och ibland använda andra metoder än `OFFSET`.

Det tar vi upp mer utförligt när vi arbetar med prestanda och applikationer.

### Hur bör vi jämföra text?

Vi har använt villkoret `name = 'Anna'`. Men ska `Anna` och `anna` räknas som samma namn? Hur ska `Å`, `Ä` och `Ö` sorteras?

Det beror på språkregler och vilka inställningar som används för att jämföra text, ofta kallade **kollationer** (*collations*).

En och samma SQL-Query kan därför bete sig något olika i olika databasmiljöer.

Det är värt att komma ihåg: ett villkor som ser enkelt ut kan bygga på ganska många antaganden om informationens betydelse.

### Att filtrera data är också att välja perspektiv

När vi skriver en fråga bestämmer vi vilka uppgifter som ska ingå i resultatet.

En fråga som hämtar kunder med registrerade gatuadresser ger en annan bild än en fråga som också inkluderar kunder vars adresser är ofullständiga.

Båda kan vara korrekta. Men de besvarar inte riktigt samma fråga.

Det blir särskilt viktigt när vi använder SQL för rapportering och analys. En förutsättning för att kunna lita på resultatet är att vi förstår vilka uppgifter som valts bort.

## Reflektion

1. Vad är skillnaden mellan att information saknas och att information har värdet noll eller en tom sträng?
2. Varför behöver vi uttryckligen ange en sorteringsordning när vi vill hämta de första tio posterna?
3. Hur kan två SQL-Queries ge olika, men ändå korrekta, bilder av samma datamängd?

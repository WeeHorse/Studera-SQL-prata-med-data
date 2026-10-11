# 3. Att komma igång med SQL

Vi har organiserat bokhandelns information i tabeller. Men en databas blir inte särskilt användbar om vi måste läsa igenom alla tabeller för att hitta något.

Vi behöver kunna ställa frågor: Vilka kunder har vi? Vad heter de? Vilken information har vi registrerat om dem?

SQL låter oss beskriva vilken information vi vill ha, utan att vi behöver tala om exakt hur databashanteraren ska leta fram den.

## Grund

### Ett språk för databaser

**SQL** betyder *Structured Query Language* och är ett språk för att arbeta med framför allt relationella databaser.

Vi använder SQL för att läsa information, men också för att lägga till, förändra och ta bort data samt skapa själva databasstrukturen.

Vi börjar med att läsa information.

En **Query** (*databasfråga*) är en instruktion som ställer en fråga till databasen, exempelvis genom `SELECT`. Vi använder **Queries** för att hämta och bearbeta information. När vi talar om en *fråga* i vanligt språk menar vi däremot det informationsbehov vi vill få svar på.

En Query är en sorts **SQL-sats** (*statement*). SQL-satser kan även förändra data eller databasens struktur, exempelvis med `INSERT` eller `CREATE TABLE`.

### Vår första Query

Vi har sedan tidigare en tabell med bokhandelns kunder:

**customers**

| id | name | email |
|---|---|---|
| 1 | Benjamin | benjamin@example.com |
| 2 | Olof | olof@example.com |
| 3 | Anaïs | anais@example.com |

Om vi vill hämta kundernas namn skriver vi:

```sql
SELECT name
FROM customers;
```

Resultatet blir:

| name |
|---|
| Benjamin |
| Olof |
| Anaïs |

Vi kan läsa denna Query nästan som en vanlig mening:

- `SELECT name` – välj kolumnen `name`.
- `FROM customers` – från tabellen `customers`.

Semikolonet (`;`) markerar slutet på SQL-satsen. Det är vanligt att avsluta varje SQL-sats med semikolon, och nödvändigt när vi vill skilja flera satser åt i samma skript.

### Flera kolumner

Vill vi se både namn och e-postadress väljer vi båda kolumnerna:

```sql
SELECT name, email
FROM customers;
```

| name | email |
|---|---|
| Benjamin | benjamin@example.com |
| Olof | olof@example.com |
| Anaïs | anais@example.com |

Kolumnerna skiljs åt med kommatecken.

Vill vi hämta **alla kolumner** kan vi använda en asterisk (`*`):

```sql
SELECT *
FROM customers;
```

Det är praktiskt när vi utforskar en tabell. När vi vet vilka uppgifter vi behöver är det ofta bättre att ange just de kolumnerna.

### Att välja vissa rader

Ofta vill vi inte se alla kunder, utan bara de som uppfyller ett visst villkor.

```sql
SELECT name, email
FROM customers
WHERE id = 2;
```

| name | email |
|---|---|
| Olof | olof@example.com |

`WHERE` anger ett villkor som avgör vilka rader som ska ingå i resultatet.

Här letar vi efter kunden vars `id` är `2`. Som vi såg i förra kapitlet använder vi primärnyckeln för att identifiera en bestämd post.

Vi kan också jämföra text:

```sql
SELECT *
FROM customers
WHERE name = 'Olof';
```

Textvärden skrivs inom enkla citattecken. Tal skrivs normalt utan citattecken.

I nästa kapitel tittar vi närmare på villkor och hur vi kombinerar dem.

### SQL består av satser

En instruktion som databashanteraren kan utföra kallas en **SQL-sats** (*statement*).

`SELECT` är en sådan sats. Några andra vanliga satser är:

| Sats | Användning |
|---|---|
| `SELECT` | Läsa data |
| `INSERT` | Lägga till data |
| `UPDATE` | Ändra data |
| `DELETE` | Ta bort data |
| `CREATE TABLE` | Skapa en tabell |

De fyra första används ofta för att beskriva **CRUD**: *Create, Read, Update, Delete*.

Det är fyra grundläggande handlingar vi kan utföra på information: skapa, läsa, förändra och radera.

Vi ska arbeta mer med `INSERT`, `UPDATE` och `DELETE` längre fram. Tills vidare räcker det att känna igen deras syften.

### Läsbar SQL

SQL behöver inte skrivas med stora bokstäver:

```sql
select name from customers;
```

Men vi kommer att skriva SQL:s nyckelord med stora bokstäver och dela upp längre frågor på flera rader:

```sql
SELECT name, email
FROM customers
WHERE id = 2;
```

Det gör frågorna lättare att läsa, särskilt när de blir mer komplicerade.

Vi kan också lägga till kommentarer:

```sql
-- Hämta kunden med id 2
SELECT name, email
FROM customers;
```

En kommentar som börjar med `-- ` ignoreras av databashanteraren. [^comment]

Notera att kommentaren inte påverkar frågan: exemplet ovan hämtar fortfarande **alla** kunder. Kommentarer är beskrivningar, inte instruktioner.

[^comment]: För bästa kompatibilitet mellan olika SQL-miljöer skriver vi ett blanksteg efter `--`. MySQL kräver att `--` följs av ett blanktecken eller kontrolltecken, medan vissa andra databassystem är mindre restriktiva.

## Avancerat

### Vi beskriver resultatet, inte arbetsgången

SQL är i huvudsak ett **deklarativt språk**.

Det betyder att vi talar om *vad* vi vill få fram, medan databashanteraren bestämmer *hur* informationen ska hittas.

När vi skriver:

```sql
SELECT name
FROM customers
WHERE id = 2;
```

beskriver vi vårt önskade resultat. Vi säger inte att databashanteraren ska läsa rad ett, sedan rad två och därefter sluta.

Databashanteraren kan välja mellan olika sätt att hitta informationen, exempelvis med hjälp av ett index. Vi ska undersöka detta senare i boken.

### En Query följer en struktur

En SQL-Query kan innehålla flera delar. En enkel mall är:

```sql
SELECT column_name
FROM table_name
WHERE condition;
```

Delarna har olika roller:

- `SELECT` beskriver vilka kolumner eller uttryck som ska ingå.
- `FROM` anger varifrån informationen hämtas.
- `WHERE` väljer vilka rader som ska tas med.

Det är viktigt att skilja mellan **ordningen vi skriver delarna** och **hur frågan logiskt behandlas**.

Vi skriver `SELECT` först, men för att kunna välja kolumner från rätt rader behöver databassystemet också ta hänsyn till `FROM` och `WHERE`. I en förenklad logisk beskrivning bestäms först datakällan, sedan filtreras raderna och därefter formas resultatets kolumner.

Den skillnaden blir användbar när vi längre fram arbetar med gruppering, beräkningar och flera tabeller.

### Namn och alias

Vi kan ge en kolumn ett annat namn i resultatet med `AS`:

```sql
SELECT name AS customer_name
FROM customers;
```

| customer_name |
|---|
| Benjamin |
| Olof |
| Anaïs |

Detta förändrar inte namnet på kolumnen i databasen. Det påverkar bara hur resultatet presenteras.

Vi kan även ge tabeller kortare namn, så kallade **alias**:

```sql
SELECT c.name, c.email
FROM customers AS c;
```

Prefixet `c.` talar om att kolumnerna kommer från tabellen som vi kallat `c`. Detta blir särskilt användbart när vi hämtar information från flera tabeller:

```sql
SELECT c.name, c.email, a.street, a.city
FROM customers AS c, addresses AS a
WHERE a.customer_id = c.id;
```

Här kopplar vi samman kunderna med deras adresser genom att jämföra `addresses.customer_id` med `customers.id`. Vi går igenom hur sådana kopplingar fungerar längre fram.

### SQL är ett språk med olika dialekter

SQL är standardiserat, men databassystem som MySQL, PostgreSQL, SQLite och SQL Server har också egna tillägg och skillnader.

Grundläggande satser som våra `SELECT`-exempel fungerar i regel på samma sätt. Andra konstruktioner kan ha olika syntax.

Vi kommer att använda standardnära SQL i boken och kommentera viktiga skillnader i fotnoter. Mer omfattande skillnader samlar vi i separata referenshäften.

### En Query förändrar inte data

Vår `SELECT`-fråga läser data utan att ändra den.

Andra satser, exempelvis `UPDATE` och `DELETE`, kan däremot förändra eller ta bort information permanent om ändringarna sparas.

Det är en viktig skillnad mellan att **fråga efter information** och att **förändra den**.

När vi kommer till dessa operationer ska vi därför också prata om villkor, dataintegritet och hur vi undviker oavsiktliga ändringar.

## Reflektion

1. Varför kan det vara värdefullt att beskriva *vilket resultat* vi vill ha, i stället för att bestämma exakt *hur* databasen ska hitta det?
2. Vad är skillnaden mellan att läsa data och att förändra data?
3. När kan `SELECT *` vara praktiskt, och varför kan det ibland vara bättre att välja kolumnerna uttryckligen?

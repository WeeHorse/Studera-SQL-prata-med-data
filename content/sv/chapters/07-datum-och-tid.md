# 7. Datum och tid

En bokhandel behöver kunna beskriva inte bara *vad* som finns i databasen, utan också *när* något hände eller ska hända.

Vi vet exempelvis när en kund är född. Senare kanske vi vill veta när kunden registrerade sig, när en order lades och hur länge en reservation gäller.

Men tid är inte alltid ett enda slags värde. Ett födelsedatum är något annat än en exakt tidpunkt. En leveranstid kan vara en varaktighet, och en kampanj kan gälla under en viss period.

Att arbeta med datum och tid handlar därför först om att förstå **vilken sorts tidsinformation vi försöker beskriva**.

## Grund

### Datum – vilken dag?

I kapitel 4 introducerade vi datatypen `DATE`. Den beskriver ett datum, utan något klockslag.

Vi har redan kundernas födelsedatum i tabellen `customers`:

| id | name | birthday |
|---|---|---|
| 1 | Benjamin | 1968-04-12 |
| 2 | Olof | 1982-09-03 |
| 3 | Anaïs | 1995-06-21 |
| 4 | Beatrice | 2000-02-15 |
| 5 | Anna | 1975-11-08 |

Vi kan hämta namn och födelsedatum med `SELECT name, birthday FROM customers`. Vi kan också jämföra datumen:

```sql
SELECT name, birthday
FROM customers
WHERE birthday > '1980-01-01';
```

Det ger de kunder som är födda efter den 1 januari 1980.

Vi skriver datum i formen `ÅÅÅÅ-MM-DD`, exempelvis `'1982-09-03'`. I våra SQL-exempel använder vi ett citerat datumvärde som databashanteraren kan tolka i jämförelsen med en `DATE`-kolumn.

### Att sortera datum

Datum kan jämföras och sorteras precis som andra värden:

```sql
SELECT name, birthday
FROM customers
ORDER BY birthday;
```

Nu kommer den äldsta kunden först.

Vill vi i stället ha den yngsta först använder vi `ORDER BY birthday DESC`.

### Datumintervall

Vi kan hämta de kunder som är födda under 1990-talet:

```sql
SELECT name, birthday
FROM customers
WHERE birthday BETWEEN '1990-01-01' AND '1999-12-31';
```

`BETWEEN` inkluderar båda gränserna.

Samma fråga kan uttryckas så här:

```sql
SELECT name, birthday
FROM customers
WHERE birthday >= '1990-01-01'
  AND birthday < '2000-01-01';
```

Den senare formen är särskilt användbar när vi arbetar med datum *och klockslag*, eftersom vi inte behöver försöka beskriva dagens allra sista möjliga tidsvärde.

### Dagens datum

Ibland vill vi jämföra med dagens datum i stället för ett datum vi skriver själva.

```sql
SELECT CURRENT_DATE;
```

`CURRENT_DATE` ger dagens datum enligt databassystemets aktuella tidsinställningar.

Vi skulle exempelvis kunna leta efter födelsedatum som ligger i framtiden:

```sql
SELECT name, birthday
FROM customers
WHERE birthday > CURRENT_DATE;
```

En sådan fråga kan också hjälpa oss att upptäcka orimliga uppgifter.

### Datum och klockslag

Ett datum berättar vilken dag något hände, men inte vid vilken tid.

När vi senare börjar registrera beställningar behöver vi kanske spara både datum och klockslag:

```text
2026-10-11 14:35:00
```

SQL har bland annat typen `TIMESTAMP` för datum och tid tillsammans. Flera databassystem har även en typ som heter `DATETIME`.[^datetime]

[^datetime]: `DATETIME` finns i bland annat MySQL och SQL Server men är inte en gemensam typ med identiskt beteende i alla SQL-system. `TIMESTAMP` finns i SQL-standarden, men bland annat MySQL och PostgreSQL behandlar tidszoner olika. Vi går igenom den skillnaden under *Avancerat*.

Bokhandeln kan exempelvis komplettera kunduppgifterna med ett nytt attribut `registered_at`, som anger när kunden registrerades.

Vi skapar inte kolumnen i SQL ännu, men den kan senare användas så här:

```sql
SELECT name, registered_at
FROM customers
ORDER BY registered_at DESC;
```

Det skulle visa de senast registrerade kunderna först.

### Aktuell tidpunkt

`CURRENT_TIMESTAMP` ger ett aktuellt datum- och tidsvärde, exempelvis med `SELECT CURRENT_TIMESTAMP;`.

Det är användbart om vi exempelvis vill registrera när något inträffade.

En del databassystem har dessutom funktionen `NOW()` med liknande användning.[^now]

[^now]: MySQL och PostgreSQL har `NOW()`. `CURRENT_TIMESTAMP` är standardnära och stöds även av SQLite och SQL Server, men precision och exakt tidssemantik kan skilja sig åt.

### Tidpunkter och varaktighet

Anta att en bokhandel reserverar en vara i 30 minuter.

Då behöver vi skilja mellan två saker:

- **Tidpunkt:** Reservationen skapades klockan 14:35.
- **Varaktighet:** Reservationen gäller i 30 minuter.

Om vi även registrerar när reservationen upphör får vi en ny tidpunkt:

```text
reserved_at: 2026-10-11 14:35:00
expires_at:  2026-10-11 15:05:00
```

Det är ofta lättare att fråga om en reservation har gått ut när vi har en tydlig sluttid:

```sql
SELECT *
FROM reservations
WHERE expires_at < CURRENT_TIMESTAMP;
```

Här använder vi en framtida tabell, `reservations`, bara för att visa idén. Den ingår ännu inte i vår bokhandelsdatabas.

## Avancerat

### En dag är inte alltid ett klockslag

Ett födelsedatum hör normalt inte hemma i ett fält som också ska beskriva ett exakt klockslag. Vi är intresserade av vilken dag personen föddes, inte av när ett databasprogram råkade registrera uppgiften.

På samma sätt kan en kampanj ha ett startdatum och ett slutdatum utan att vi ännu behöver ange några klockslag.

Valet mellan `DATE` och ett datum- och tidsvärde handlar därför om **vilken precision informationen faktiskt behöver**.

Att lagra mer precision än vi har nytta av gör inte informationen bättre.

### Halvöppna intervall

När vi frågar efter händelser under en månad kan detta vara frestande:

```sql
SELECT *
FROM orders
WHERE ordered_at BETWEEN '2026-10-01' AND '2026-10-31';
```

Men om `ordered_at` innehåller klockslag riskerar den övre gränsen att utesluta beställningar senare under den 31 oktober. Ett datum utan klockslag kan i en sådan jämförelse tolkas som midnatt vid dagens början.

Ett säkrare uttryck är:

```sql
SELECT *
FROM orders
WHERE ordered_at >= '2026-10-01'
  AND ordered_at < '2026-11-01';
```

Det kallas ett **halvöppet intervall**: den nedre gränsen ingår, den övre gör det inte.

Vi kan använda det oavsett om databasen lagrar sekunder eller ännu högre precision.

Tabellen `orders` introduceras senare i boken. Här visar vi bara hur tidsvillkoret är uppbyggt.

### Att beräkna tidsskillnader

Vi kan behöva veta hur många dagar som gått mellan två datum.

Det låter enkelt, men exakt syntax varierar mellan SQL-dialekter. MySQL har exempelvis `DATEDIFF()`:

```sql
SELECT DATEDIFF('2026-10-11', '2026-10-01');
```

Resultatet är `10` dagar.[^datediff]

[^datediff]: Exemplet använder MySQL-syntax. PostgreSQL kan exempelvis subtrahera två `DATE`-värden direkt, SQL Server använder `DATEDIFF` med ett argument för tidsenheten och SQLite har andra funktioner för datumberäkningar. Se respektive dialektreferens.

Det finns också en skillnad mellan att beräkna **antal kalenderdagar** och **förfluten tid i timmar eller sekunder**. Skillnaden blir viktig vid exempelvis sommartidsomställningar.

### Ålder är inte bara två årtal

Det kan vara frestande att beräkna en kunds ålder så här:

```text
innevarande år - födelseår
```

Men då får vi fel svar om kunden inte har fyllt år ännu.

För att beräkna ålder korrekt måste vi även jämföra månad och dag. Vi behöver dessutom vara tydliga med vid vilket datum åldern ska gälla.

Detta visar varför tidsberäkningar kräver mer eftertanke än vanliga numeriska beräkningar.

### Tidszoner

Om bokhandeln bara finns på en ort kanske det verkar självklart vad klockan är.

Men om en kund lägger en beställning från en annan tidszon uppstår en fråga: vilken tid ska vi lagra och visa?

En **tidpunkt** är densamma oavsett var i världen vi befinner oss. Men den lokala klocktiden som beskriver tidpunkten är olika på olika platser.

Därför behöver vi skilja mellan:

- **En absolut tidpunkt**, som när en order faktiskt registrerades.
- **Ett lokalt datum eller klockslag**, som när en butik öppnar.
- **En tidszon**, som avgör hur ett lokalt klockslag förhåller sig till en absolut tidpunkt.

För händelser som ska kunna jämföras globalt är det ofta praktiskt att lagra eller normalisera tidpunkter till UTC och omvandla dem till lokal tid vid presentation.

Men det betyder inte att alla datum och tider bör behandlas som UTC. En butiks öppettid klockan 09:00 beskriver exempelvis en lokal regel, inte en och samma globala tidpunkt.

### TIMESTAMP betyder inte alltid samma sak

Det är lätt att tro att en datatyp som heter `TIMESTAMP` fungerar likadant överallt. Så är det inte.

I MySQL sker exempelvis tidszonsomvandling för `TIMESTAMP` utifrån sessionens tidszon, medan `DATETIME` beter sig annorlunda. PostgreSQL skiljer mellan `TIMESTAMP WITHOUT TIME ZONE` och `TIMESTAMP WITH TIME ZONE`.

SQLite har inte en separat, fast datum- och tidslagringstyp på samma sätt, utan kan representera tidsvärden i exempelvis text eller numeriska format.

Det här är en anledning till att tidszonshantering ofta behöver beskrivas i en dialektspecifik referens.

### När hände det, och när fick vi veta det?

Föreställ dig att en kund flyttade den 1 september, men att bokhandeln inte fick veta det förrän den 10 september.

Det ger oss två olika tidpunkter:

- När förändringen **gällde i verkligheten**.
- När förändringen **registrerades i vårt system**.

De är inte alltid samma sak.

I enkla system räcker det ofta att bara lagra den aktuella adressen. Men om vi behöver återskapa historiska förhållanden, exempelvis vilken leveransadress som gällde vid en viss beställning, behöver vi tänka mer noggrant kring historik.

Vi kommer att återvända till detta när vi behandlar transaktionsdata och datakvalitet.

## Reflektion

1. Varför är ett födelsedatum något annat än en exakt tidpunkt, även om båda handlar om tid?
2. När är det bättre att använda ett halvöppet intervall än `BETWEEN`?
3. Vad är skillnaden mellan när något hände i verkligheten och när det registrerades i databasen?

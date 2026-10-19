# 28. Att välja och förstå SQL-system

Vi har arbetat med SQL som ett språk för att beskriva, hämta och förändra information. Vi har skapat relationer, skrivit Queries och undersökt hur databasen upprätthåller regler och genomför transaktioner.

Men när vi installerar en databas installerar vi inte bara *SQL*. Vi väljer ett **databashanteringssystem** – en programvara som tolkar våra SQL-satser, lagrar data och ansvarar för hur de kan användas.

Det finns många sådana system. De har mycket gemensamt, men skiljer sig åt på sätt som påverkar både våra Queries och hur vi bygger applikationer.

Hur ska vi förstå skillnaderna utan att förlora det gemensamma?

## Grund

### SQL är ett språk – inte en databas

**SQL** (*Structured Query Language*) beskriver hur vi kan arbeta med relationella data.

**MySQL**, **PostgreSQL**, **SQLite** och **Microsoft SQL Server** är exempel på databashanteringssystem som använder SQL.

Vi kan jämföra skillnaden med ett språk och dess olika användningsmiljöer: två system kan förstå samma grundläggande SQL men ha olika utvidgningar, regler och sätt att arbeta.

En Query som:

```sql
SELECT title, price
FROM products
WHERE price > 200
ORDER BY price DESC;
```

fungerar i många SQL-system utan ändringar.

Men all SQL är inte lika portabel. Vi har redan mött exempel på skillnader i datumfunktioner, JSON-hantering och geografiska funktioner.

### SQL-standarden och dialekter

SQL har en internationell standard, ISO/IEC 9075, som utvecklas över tid (se [Referenser och vidare läsning](/sv/referenser.html)).

Standarden beskriver bland annat språkets grundläggande konstruktioner. Men den betyder inte att alla databassystem erbjuder exakt samma funktioner eller tolkar alla situationer på samma sätt.

En **SQL-dialekt** är ett visst systems sätt att stödja och ibland utöka SQL.

Vi har exempelvis använt:

```sql
SELECT *
FROM products
LIMIT 5 OFFSET 10;
```

Det här fungerar i MySQL, PostgreSQL och SQLite.

SQL-standardens sätt att uttrycka ett motsvarande urval kan i stället se ut så här:

```sql
SELECT *
FROM products
ORDER BY id
OFFSET 10 ROWS
FETCH NEXT 5 ROWS ONLY;
```

Men stödet för olika varianter skiljer sig. Därför behöver vi lära oss både **den gemensamma idén** och **den syntax som gäller där vi faktiskt arbetar**.

Vi bör dessutom ange `ORDER BY` när urvalet beror på vilka rader som kommer först. Utan uttrycklig sortering finns ingen garanterad ordning.

### Fyra vanliga SQL-system

| System | Typisk egenskap |
|---|---|
| **MySQL** | Vanligt i webbapplikationer och servermiljöer |
| **PostgreSQL** | Brett funktionsstöd och många möjligheter till utbyggnad |
| **SQLite** | Inbyggd databas som ofta används direkt av en applikation |
| **SQL Server** | Integrerat databassystem med omfattande drift- och administrationsfunktioner |

Det är exempel på användningsområden, **inte begränsningar**. Samma system kan användas i många olika sammanhang.

I vår bok har vi ofta använt MySQL som praktisk referens. Det innebär inte att MySQL alltid är det lämpligaste valet.

### Serverdatabas eller inbyggd databas

MySQL, PostgreSQL och SQL Server används ofta som **serverbaserade databashanterare**.

En databasserver kan ta emot anslutningar från flera program och användare. Den ansvarar för bland annat samtidighet, åtkomstkontroll och lagring.

SQLite används vanligtvis som en **inbyggd databas** i en applikation, där informationen lagras i en lokal databasfil.

Det betyder inte att SQLite saknar transaktioner eller relationsstöd. Men arkitekturen är annorlunda: vi har normalt ingen separat SQL-serverprocess som programmen ansluter till på samma sätt.

En lokal mobilapp och en stor webbhandel kan därför ha olika behov, även om de lagrar liknande information.

### Skillnader i syntax

Tänk att vi vill hämta de fem dyraste produkterna.

I MySQL, PostgreSQL och SQLite kan vi skriva:

```sql
SELECT title, price
FROM products
ORDER BY price DESC, id
LIMIT 5;
```

I SQL Server kan ett motsvarande exempel använda `TOP`:

```sql
SELECT TOP (5) title, price
FROM products
ORDER BY price DESC, id;
```

Vi försöker beskriva **samma informationsbehov**, men syntaxen skiljer sig.

Det är därför värdefullt att förstå `ORDER BY` och begränsning av rader som begrepp, i stället för att bara memorera en dialekts formuleringar.

### Datatyper är inte identiska överallt

Vi har arbetat med `INTEGER`, `DECIMAL`, `VARCHAR` och `DATE`.

De är vanliga datatyper, men detaljerna varierar.

Exempelvis har SQLite en särskild modell för typaffinitet och dynamisk typning, medan andra system i större utsträckning upprätthåller kolumnens deklarerade datatyp. SQLite kan också använda `STRICT`-tabeller för striktare typregler.

Även `BOOLEAN`, autogenererade identifierare och hur datum och tidszoner lagras skiljer sig mellan systemen.

Sådana skillnader påverkar inte bara **hur vi skriver SQL**, utan också **vilka garantier vi kan förvänta oss av datamodellen**.

## Avancerat

### Samma SQL kan ge olika praktiska förutsättningar

Att två databassystem accepterar samma Query betyder inte att de genomför den på samma sätt.

De kan ha olika strategier för index, optimering, transaktioner, låsning och radversionering.

Exempelvis kan:

- En viss `JOIN` planeras på olika sätt.
- Ett index byggas och användas annorlunda.
- Två samtidiga transaktioner påverka varandra på olika sätt.
- En schemaändring kräva olika mycket låsning eller driftplanering.

Därför är en Querys **logiska betydelse** inte samma sak som dess **faktiska exekvering**.

Vi mötte denna skillnad i kapitlen om transaktioner och Query-prestanda.

### Funktioner som utökar SQL

Databassystem kan erbjuda funktioner som går utöver den gemensamma SQL-kärnan.

Vi har redan sett exempel:

| Område | Exempel på skillnader |
|---|---|
| Datum och tid | `DATE_FORMAT()` i MySQL, `DATE_TRUNC()` i PostgreSQL |
| JSON | Olika typer, operatorer och JSON-funktioner |
| Geografiska data | Olika spatiala funktioner och tillägg |
| Fulltextsökning | Olika index, språkstöd och söksyntax |
| Programlogik i databasen | Skillnader i procedurer, funktioner och triggers |

Ett exempel är **PostGIS**, en utvidgning till PostgreSQL med omfattande funktioner för geografiska data.

Vi ska alltså inte anta att varje SQL-system erbjuder alla tekniker vi sett i boken på exakt samma sätt.

### Vad kan vi flytta mellan system?

En grundläggande Query som använder `SELECT`, `WHERE` och `JOIN` kan ofta flyttas ganska enkelt.

Men en faktisk applikation är beroende av mer än enskilda Queries:

- Datatyper, standardvärden och begränsningar.
- Identifierare och regler för autogenererade nycklar.
- Index, Views och eventuella databasfunktioner.
- Transaktionernas beteende och isoleringsnivåer.
- Behörigheter, användarkonton och roller.
- Drivrutiner, anslutningssträngar och migrationsskript.

Att byta databashanterare är därför inte alltid bara att ersätta anslutningssträngen.

Ju mer vi använder ett visst systems specialfunktioner, desto viktigare blir det att förstå hur beroendet påverkar möjligheten att byta system senare.

Men att undvika *alla* systemspecifika funktioner kan också innebära att vi avstår från användbara möjligheter. Portabilitet är en avvägning, inte ett självändamål.

### Hur väljer vi ett SQL-system?

I stället för att fråga vilket system som är *bäst* kan vi fråga vilka krav vår tillämpning faktiskt har.

| Fråga | Varför den spelar roll |
|---|---|
| Var ska programmet köras? | En lokal applikation har andra driftbehov än ett publikt system |
| Hur många ska använda det samtidigt? | Samtidighet, anslutningar och skrivbelastning påverkar arkitekturvalet |
| Hur viktig är tillgängligheten? | Drift, säkerhetskopiering och återställning behöver planeras |
| Vilka datatyper och funktioner krävs? | JSON, geografiska data och andra specialfunktioner kan skilja sig |
| Vilken kompetens finns? | Ett system behöver kunna utvecklas, felsökas och förvaltas |
| Vilka tekniska beroenden har vi? | Drivrutiner, molntjänster och integrationer påverkar valet |

Krav som prestanda, kostnad och skalbarhet behöver bedömas i den **faktiska miljön**, inte enbart utifrån allmänna påståenden om olika produkter.

### Ett exempel: bokhandeln växer

Anta att bokhandeln börjar som en liten lokal applikation för att hålla reda på produkter och lager.

En inbyggd databas som SQLite skulle kunna vara lämplig om allt hanteras i en och samma applikation och miljö.

När bokhandeln senare får en webbplats, flera butiker och många samtidiga användare kan en serverbaserad databas bli mer praktisk.

Men det betyder inte att SQLite automatiskt är otillräckligt så snart flera personer använder systemet, eller att en större serverdatabas alltid är bättre. Vi behöver undersöka arkitekturen och hur belastningen faktiskt ser ut.

Ett sådant byte påverkar också vårt arbetssätt. Vi behöver tänka på migrering av data, testning av Queries, behörigheter och hur programmen ansluter.

### Drift är en del av teknikvalet

Två system kan vara likvärdiga för de Queries vi skriver men ställa olika krav på drift.

Vi behöver ta ställning till exempelvis:

- Säkerhetskopiering och återställning.
- Övervakning, loggar och larm.
- Uppgraderingar och säkerhetsuppdateringar.
- Replikering och hantering av driftavbrott.
- Ansvar för servermiljö, åtkomst och tillgänglighet.

Det finns också hanterade databastjänster där en leverantör tar ansvar för delar av driften.

Det avlägsnar inte vårt ansvar för datamodell, behörigheter, kvalitetsregler och hur applikationen använder informationen.

### Standardisering och självständighet

En fördel med ett standardiserat språk är att vi kan ta med oss mycket av vår kunskap mellan olika system.

Men **standardisering av språk** är inte samma sak som **oberoende av teknikleverantörer**.

Vi kan använda SQL och ändå vara beroende av ett visst systems funktioner, verktyg eller driftsmiljö.

För vissa verksamheter är det viktigt att kunna flytta data och applikationer mellan miljöer. För andra väger integration, prestanda eller tillgång till viss funktionalitet tyngre.

Vi behöver därför kunna skilja mellan:

**Öppna principer** – idéer och standarder som kan användas i flera system.

**Systemspecifika möjligheter** – funktioner som gör ett visst system särskilt användbart.

**Praktisk flyttbarhet** – vad vi faktiskt kan överföra utan stora förändringar.

Det är tre relaterade men inte identiska saker.

### Att välja ett system är att välja förutsättningar

En databashanterare bestämmer inte vad en kund, produkt eller beställning betyder. Det är vårt arbete att modellera.

Men vårt val av databashanterare påverkar **hur modellen kan uttryckas, vilka regler som kan upprätthållas och vilka verktyg vi har för att arbeta med informationen**.

Det betyder att teknikvalet varken bör göras enbart utifrån favoritprodukter eller enbart utifrån en lista över SQL-funktioner.

Vi behöver förstå informationsbehovet, verksamhetens utveckling och vilka förutsättningar som måste finnas för att informationen ska förbli användbar över tid.

## Reflektion

1. Varför kan två databashanterare som båda använder SQL ändå kräva olika lösningar för samma applikation?
2. När är det rimligt att använda en systemspecifik funktion även om den gör det svårare att byta databashanterare?
3. Varför räcker det inte att jämföra SQL-syntax när vi ska välja vilket databassystem en verksamhet behöver?

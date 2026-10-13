# 17. Views och återanvändbara Queries

Vi har byggt bokhandelns databas med flera tabeller. Kunder, adresser, produkter, produkttyper och författare lagras var för sig, med relationer mellan dem.

Men den som arbetar i bokhandeln vill kanske inte tänka på hur informationen är uppdelad. Hen vill se vilka produkter som finns i lager, vilka författare de har eller vilka kunder som har adresser i en viss stad.

Vi har redan lärt oss att formulera sådana frågor med SQL. Men om vi behöver samma representation på många ställen kan det vara praktiskt att ge den ett eget namn.

En **View**, eller vy, låter oss beskriva **hur information ska betraktas**, utan att behöva skapa en ny vanlig tabell för den.

## Grund

### Från Query till View

Vi börjar med två tabeller vi redan känner:

**products**

| id | title | price | stock | product_type_id |
|---|---|---:|---:|---:|
| 1 | Vägen hem | 200.00 | 12 | 1 |
| 2 | Den blå staden | 150.00 | 0 | 1 |
| 3 | Vinterljus | 249.00 | 4 | 1 |
| 4 | Små historier | 120.00 | 25 | 2 |
| 5 | Mellan raderna | 180.00 | 9 | 2 |

**product_types**

| id | name |
|---|---|
| 1 | Roman |
| 2 | Novellsamling |

Vi vet redan hur en `JOIN` kan hämta produktens titel tillsammans med namnet på dess typ.

denna Query fungerar, men vi kanske vill återanvända den i flera rapporter och applikationer.

Då kan vi skapa en View:

```sql
CREATE VIEW product_overview AS
SELECT
    p.id,
    p.title,
    p.price,
    p.stock,
    t.name AS product_type
FROM products AS p
INNER JOIN product_types AS t
    ON p.product_type_id = t.id;
```

Nu har vi gett denna Query namnet `product_overview`.

### Att använda en View

Vi kan läsa från vyn nästan som från en tabell:

```sql
SELECT *
FROM product_overview;
```

| id | title | price | stock | product_type |
|---|---|---:|---:|---|
| 1 | Vägen hem | 200.00 | 12 | Roman |
| 2 | Den blå staden | 150.00 | 0 | Roman |
| 3 | Vinterljus | 249.00 | 4 | Roman |
| 4 | Små historier | 120.00 | 25 | Novellsamling |
| 5 | Mellan raderna | 180.00 | 9 | Novellsamling |

Vi kan också filtrera och sortera resultatet:

```sql
SELECT title, stock
FROM product_overview
WHERE product_type = 'Roman'
  AND stock > 0
ORDER BY title;
```

Vyn är alltså inte ett färdigt utskrivet resultat, utan en **namngiven Query** som vi kan fortsätta arbeta med.

### Lagrar en View data?

I en vanlig View lagrar databasen i huvudsak **definitionen av frågan**, inte en separat kopia av resultatraderna.

Om priset på `Vägen hem` ändras i `products` kommer nästa fråga mot `product_overview` normalt att visa det nya priset.

Vi har med andra ord inte skapat ännu en plats där priset behöver uppdateras.

Det här skiljer en vanlig View från en kopierad rapporttabell.

### En View behöver inte kombinera tabeller

En View kan också vara ett urval från en enda tabell.

Vi kan exempelvis definiera en vy för produkter som finns i lager:

```sql
CREATE VIEW available_products AS
SELECT id, title, price, stock
FROM products
WHERE stock > 0;
```

Och sedan använda den:

```sql
SELECT title, price
FROM available_products
ORDER BY price;
```

Om lagersaldot förändras påverkas även vilka produkter som visas genom vyn.

### Views för sammanfattningar

I kapitel 8 arbetade vi med `GROUP BY`. Även sådana resultat kan vi ge ett namn:

```sql
CREATE VIEW stock_by_product_type AS
SELECT
    t.id AS product_type_id,
    t.name AS product_type,
    COUNT(*) AS product_count,
    SUM(p.stock) AS total_stock
FROM product_types AS t
INNER JOIN products AS p
    ON p.product_type_id = t.id
GROUP BY t.id, t.name;
```

Vi har nu en vy där varje rad beskriver **en produkttyp**, inte en enskild produkt.

```sql
SELECT *
FROM stock_by_product_type;
```

| product_type_id | product_type | product_count | total_stock |
|---|---|---:|---:|
| 1 | Roman | 3 | 16 |
| 2 | Novellsamling | 2 | 34 |

Det är ett annat sätt att betrakta samma information.

### Att ta bort en View

Vi kan ta bort definitionen med:

```sql
DROP VIEW available_products;
```

Det tar bort vyn, **inte** produkterna i `products`.

Vi bör ändå vara försiktiga: andra frågor eller program kan vara beroende av vyn.

## Avancerat

### Lagringsmodell och logisk modell

Vår databas är organiserad så att varje företeelse har en tydlig plats. En produkt har sitt pris i `products` och en produkttyp har sitt namn i `product_types`.

Det är en modell som passar för **lagring och integritet**.

Men en anställd kanske vill se produktnamn, typnamn, pris och lagersaldo tillsammans. En rapport kanske vill ha en rad per produkttyp.

Views låter oss därför definiera **logiska modeller för olika informationsbehov** ovanpå samma lagringsmodell.

Vi kan tänka på tre nivåer:

| Nivå | Fråga |
|---|---|
| Lagringsmodell | Hur organiserar och skyddar vi informationen? |
| View | Vilken representation behöver vi för ett visst syfte? |
| Användare eller applikation | Vilka frågor behöver vi kunna besvara? |

Det betyder inte att en View alltid är en komplett modell i sig. Men den kan fungera som ett namngivet, återanvändbart perspektiv på vår information.

### När varje rad får en ny betydelse

I `products` representerar en rad en produkt.

I `product_overview` representerar varje rad fortfarande en produkt, men med uppgifter från flera tabeller.

I `stock_by_product_type` representerar varje rad i stället en **produkttyp med sammanfattad lagerinformation**.

Det är värt att fundera över vad vi faktiskt har definierat. Vi har inte bara sparat ett stycke SQL. Vi har gett ett namn åt **vilken sorts information resultatet beskriver**.

Det anknyter till vår tidigare diskussion om datatyper och datamodellering: vi kan skapa meningsfulla strukturer utan att varje struktur behöver motsvara en egen, lagrad entitet.

### Views som stabila gränssnitt

I förra kapitlet diskuterade vi hur databasstrukturer förändras över tid.

Anta att vi byter namn på en intern kolumn från `title` till `product_title`. Applikationer som använder den gamla kolumnen kan då sluta fungera.

Om de i stället frågar en View kan vi i vissa fall bevara ett stabilt gränssnitt:

```sql
CREATE VIEW product_catalog AS
SELECT
    id,
    product_title AS title,
    price
FROM products;
```

Här förutsätter vi att den underliggande kolumnen redan har bytt namn.

Vyn kan erbjuda det kolumnnamn applikationen förväntar sig, även när lagringsmodellen ser annorlunda ut.

Detta kräver planering: vi måste hantera beroenden, behörigheter och hur vyn uppdateras under migrationen. Vyn förändrar inte automatiskt sig själv när tabellen ändras.

### Views som avgränsning av information

En View kan också visa bara de kolumner som behövs i ett visst sammanhang.

Anta att bokhandelns interna kundtabell innehåller namn, e-postadress och födelsedatum, men att en viss rapport bara behöver namn och kund-id.

```sql
CREATE VIEW customer_names AS
SELECT id, name
FROM customers;
```

Vi har därmed definierat en mer begränsad representation.

Det kan vara en del av en säkerhets- och behörighetsmodell om användaren får åtkomst till vyn men inte till den underliggande tabellen. **Vyn ensam är däremot ingen garanti för att känslig information skyddas.** Databassystemets rättigheter och vyernas exekveringsregler måste också vara korrekt konfigurerade.[^permissions]

[^permissions]: MySQL har exempelvis vyer med `SQL SECURITY DEFINER` eller `INVOKER`, och PostgreSQL har andra regler och möjligheter för säkerhetskontext. Vi återkommer till åtkomstkontroll i säkerhetskapitlet.

### Kan vi använda UPDATE på en View?

Vissa Views går att uppdatera, så att en ändring genom vyn påverkar den underliggande tabellen.

En enkel vy som väljer kolumner från en tabell kan i många databassystem vara uppdateringsbar.

Men en vy med `GROUP BY` eller aggregeringar, som `stock_by_product_type`, är normalt inte direkt uppdateringsbar. Vad skulle det exempelvis innebära att ändra gruppens `total_stock` till `100`? Vilka produktposter skulle vi förändra?

Även en `JOIN`-vy kan ha begränsningar. De exakta reglerna varierar mellan SQL-dialekter.[^updatable]

[^updatable]: Vissa databassystem erbjuder särskilda mekanismer, exempelvis `INSTEAD OF`-triggers, för att definiera hur skrivningar genom mer komplexa vyer ska hanteras. Vilka vyer som automatiskt kan uppdateras skiljer sig åt.

Vi bör därför se en View som en **läsmodell i första hand**, om vi inte uttryckligen har bestämt och testat hur uppdateringar ska fungera.

### Views och prestanda

En vanlig View lagrar normalt inte resultatet i förväg. När vi använder den behöver databashanteraren fortfarande behandla frågan som vyn beskriver.

Databasen kan i många fall optimera genom att kombinera vydefinitionen med vår yttre fråga. Men en View gör inte automatiskt en komplicerad fråga snabbare.

En del databassystem stöder också **materialiserade vyer**, där ett frågeresultat lagras och uppdateras eller förnyas enligt särskilda regler.

Det kan förbättra prestanda vid upprepade analyser, men ger oss en ny fråga: **Hur aktuellt är det lagrade resultatet?**

Stödet skiljer sig mellan SQL-system.[^materialized]

[^materialized]: PostgreSQL har inbyggt stöd för materialiserade vyer med `CREATE MATERIALIZED VIEW` och `REFRESH MATERIALIZED VIEW`. SQL Server har indexerade vyer med särskilda krav. MySQL har inte motsvarande allmänna inbyggda materialiserade vyfunktion, utan liknande lösningar byggs vanligtvis på annat sätt.

### Views, subqueries och CTE:er

Vi har nu flera sätt att skapa nya representationer av information:

| Teknik | Hur vi använder den |
|---|---|
| Subquery | Ett frågeresultat används inuti en annan fråga |
| View | Vi ger en fråga ett bestående namn i databasen |
| CTE | Vi namnger ett mellanresultat inom en enskild SQL-sats |

En View är alltså inte bara en subquery med ett namn. Den blir ett **databasobjekt** som andra frågor kan referera till, med egna beroenden och eventuellt egna åtkomsträttigheter.

I nästa kapitel går vi vidare med CTE:er och undersöker hur vi kan göra stora frågor mer begripliga genom att namnge olika steg.

### En modell är också ett perspektiv

Vi kan beskriva samma bokhandel på många sätt.

För lagring behöver vi veta vilka kunder, produkter och adresser som finns och hur de hör ihop.

För personalen i butiken behöver vi kanske visa vilka produkter som finns tillgängliga.

För ledningen behöver vi kanske se sammanfattningar av lager och försäljning.

Dessa perspektiv behöver inte konkurrera med varandra. De kan bygga på en gemensam modell där informationens betydelse och relationer är tydliga.

**En View är därför både ett tekniskt verktyg och ett uttryck för vilket informationsperspektiv vi vill erbjuda.**

## Reflektion

1. Vad är skillnaden mellan en tabell som lagrar produkter och en View som presenterar en produktöversikt?
2. Varför kan en View vara användbar när databasens interna struktur behöver förändras?
3. När vi skapar en View som sammanfattar lagersaldo per produkttyp, vad har vi då egentligen modellerat?

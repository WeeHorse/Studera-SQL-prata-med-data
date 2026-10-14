# 25. SQL för analys och dataplattformar

När en kund köper en bok behöver bokhandelns system genomföra beställningen korrekt. Det ska kontrollera lagret, registrera ordern och bevara priset kunden betalade.

Men bokhandeln behöver också kunna ställa andra frågor: Vilka böcker säljer bäst? Hur utvecklas omsättningen från månad till månad? Vilka produkttyper växer snabbast?

Det är fortfarande samma verksamhet vi vill förstå, men nu använder vi informationen för ett annat syfte.

Vi går från **att registrera vad som händer** till **att undersöka vad som har hänt**.

## Grund

### Operativ data och analytisk data

Vår bokhandel har nu bland annat dessa tabeller:

- `customers` – kunder.
- `products` och `product_types` – sortiment och produkttyper.
- `orders` – beställningar.
- `order_items` – produkter och priser vid en beställning.

Tabellerna är utformade för att representera verksamhetens företeelser och relationer. När någon gör ett köp vill vi skapa och uppdatera ett litet antal poster på ett tillförlitligt sätt.

Detta brukar kallas **transaktionsorienterad datahantering**, ofta förkortat **OLTP** (*Online Transaction Processing*).

När vi i stället analyserar många beställningar samtidigt talar vi ofta om **OLAP** (*Online Analytical Processing*).

| OLTP – operativt arbete | OLAP – analys |
|---|---|
| Registrera ett köp | Summera försäljning per månad |
| Ändra en kundadress | Undersöka geografiska mönster |
| Uppdatera lagersaldo | Jämföra omsättning per produkttyp |
| Många små förändringar | Frågor över stora mängder historiska data |

Detta är olika **användningsmönster**, inte två helt åtskilda former av SQL. En mindre verksamhet kan utföra både operativa och analytiska Queries i samma databas.

### Från orderrader till omsättning

Vi har tidigare introducerat en förenklad tabell `order_items`. Här använder vi ett **utökat, illustrativt orderunderlag med tre orderrader** för att visa beräkningarna. Den nedladdningsbara grunddatabasen innehåller ännu bara en historisk orderrad; tabellen nedan är alltså ett separat exempel:

| id | order_id | product_id | quantity | unit_price |
|---|---|---|---:|---:|
| 1001 | 101 | 1 | 2 | 200.00 |
| 1002 | 102 | 4 | 1 | 120.00 |
| 1003 | 102 | 5 | 2 | 180.00 |

Här beskriver `unit_price` priset **vid beställningen**, inte produktens aktuella pris.

Vi kan beräkna orderradernas försäljningsvärde:

```sql
SELECT
    order_id,
    product_id,
    quantity * unit_price AS line_amount
FROM order_items;
```

| order_id | product_id | line_amount |
|---|---|---:|
| 101 | 1 | 400.00 |
| 102 | 4 | 120.00 |
| 102 | 5 | 360.00 |

Om vi vill summera per order använder vi `GROUP BY`:

```sql
SELECT
    order_id,
    SUM(quantity * unit_price) AS order_amount
FROM order_items
GROUP BY order_id;
```

Vi återanvänder alltså SQL vi redan kan. Skillnaden ligger i **vilket perspektiv på informationen vi söker**.

Beräkningen är förenklad. En verklig omsättningsmodell behöver också ta ställning till exempelvis rabatter, moms, returer och orderstatus. Vi kan inte avgöra vad som ska räknas som omsättning enbart utifrån dessa tre kolumner.

### Analys över tid

Vi kan kombinera `orders` och `order_items` för att undersöka beställningsvärden per månad.

I MySQL kan vi skriva:

```sql
SELECT
    DATE_FORMAT(o.ordered_at, '%Y-%m') AS order_month,
    SUM(oi.quantity * oi.unit_price) AS ordered_value
FROM orders AS o
INNER JOIN order_items AS oi
    ON oi.order_id = o.id
GROUP BY DATE_FORMAT(o.ordered_at, '%Y-%m')
ORDER BY order_month;
```

Här grupperar vi beställningarna efter månad.

Det är viktigt att kalla måttet **beställt värde**, inte automatiskt bokförd omsättning. En order kan ha avbrutits eller returnerats och vi har ännu inte modellerat dessa händelser.

Funktionen `DATE_FORMAT()` hör till MySQL. Andra SQL-system använder exempelvis `DATE_TRUNC()` eller andra datumfunktioner.[^dates]

[^dates]: PostgreSQL har bland annat `DATE_TRUNC('month', ...)`; SQL Server har andra möjligheter att gruppera på år och månad. Hur datum och tidszoner tolkas kan också påverka resultatet.

### Varför en egen analysmiljö?

Med några tusen beställningar kanske vi kan analysera direkt i bokhandelns operativa databas.

Men om vi får mycket data, komplexa sammanställningar och många samtidiga användare kan analysen behöva skiljas från systemet som registrerar köp.

En stor Query kan kräva omfattande skanningar, sorteringar och grupperingar. Den kan konkurrera om resurser med operativa transaktioner.

Vi kan därför föra över information till en särskild **analysmiljö**.

En sådan miljö kan vara utformad för att läsa stora datamängder effektivt, bevara historik och sammanföra information från flera system.

### ETL och ELT

När data flyttas och bearbetas möter vi ofta två begrepp:

**ETL – Extract, Transform, Load**

Vi hämtar data från källsystemen, bearbetar dem och läser in resultatet i analysmiljön.

**ELT – Extract, Load, Transform**

Vi hämtar data, läser in dem i en dataplattform och genomför bearbetningarna där.

Båda metoderna kan använda SQL för transformationer.

Skillnaden är inte att den ena metoden alltid är modernare eller bättre. Det handlar bland annat om var bearbetningen utförs och vilka resurser och krav miljön har.

### Ett första steg i en analytisk modell

Vi kan skapa en återanvändbar sammanställning över försäljning per produkt:

```sql
CREATE VIEW product_sales AS
SELECT
    oi.product_id,
    SUM(oi.quantity) AS units_ordered,
    SUM(oi.quantity * oi.unit_price) AS ordered_value
FROM order_items AS oi
GROUP BY oi.product_id;
```

Vyn ger oss ett **analytiskt perspektiv** på orderraderna.

Vi kan sedan kombinera den med `products` för att visa produktnamn:

```sql
SELECT
    p.title,
    s.units_ordered,
    s.ordered_value
FROM product_sales AS s
INNER JOIN products AS p
    ON p.id = s.product_id
ORDER BY s.ordered_value DESC;
```

Precis som i kapitel 17 kan en View skapa ett logiskt gränssnitt mot data. Men här ser vi också dess begränsning: resultatet är beroende av hur våra transaktionstabeller ser ut och vilka historiska uppgifter de faktiskt innehåller.

## Avancerat

### Dataplattformar och olika lagringsformer

En analysmiljö kan byggas på flera sätt.

Ett **datalager** (*data warehouse*) är vanligtvis organiserat för analytiska Queries, sammanställningar och rapportering.

En **datasjö** (*data lake*) kan samla stora mängder data i olika format, ofta inklusive filer som ännu inte har omvandlats till en gemensam relationsmodell.

En **lakehouse-arkitektur** försöker kombinera flexibla filbaserade lagringsformer med funktioner som gör informationen mer tillförlitlig och användbar för analys.

Dessa begrepp beskriver olika arkitekturval. De är inte garantier för att data blir korrekt eller att en Query går snabbt.

### Stjärnschema – en modell för analys

I en operativ databas organiserar vi ofta tabeller utifrån verksamhetens företeelser och deras relationer.

I en analytisk modell kan vi i stället utgå från **vad vi vill mäta**.

Tänk att vi vill analysera försäljningen.

Då kan vi ha en **faktatabell** med försäljningens mätvärden, exempelvis antal och orderradsvärde:

**fact_sales**

| order_item_id | date_id | product_id | quantity | ordered_value |
|---|---|---|---:|---:|
| 1001 | 20261012 | 1 | 2 | 400.00 |
| 1002 | 20261012 | 4 | 1 | 120.00 |

Och **dimensionstabeller** som beskriver produkten och datumet:

- `dim_product` – produktnamn, produkttyp och andra produktegenskaper.
- `dim_date` – datum, månad, kvartal och år.

Det brukar kallas ett **stjärnschema**.

Faktatabellens rader innehåller sådant vi vill mäta, medan dimensionerna ger oss olika sätt att gruppera och tolka mätvärdena.

Detta är en **alternativ analytisk modell**, inte nya tabeller vi lägger till direkt i vår operativa bokhandel.

### Vad representerar en rad?

När vi bygger en faktatabell behöver vi bestämma dess **kornighet** (*grain*): vad varje enskild rad representerar.

Ska en rad beskriva:

- En orderrad?
- En hel beställning?
- Försäljningen av en viss produkt under en viss dag?

Alla tre är möjliga modeller, men de ger olika beräkningsmöjligheter.

Om varje rad representerar en orderrad kan vi summera upp till ordernivå eller månadsnivå.

Om vi bara sparar totalsummor per månad förlorar vi möjligheten att senare undersöka enskilda orderrader utifrån samma tabell.

**Kornighet är alltså ett beslut om vilken detaljnivå vi bevarar**, inte bara ett val av antal kolumner.

### Egen data och främmande data

Vi har tidigare diskuterat att viss data beskriver den egna verksamhetens händelser, medan annan data kommer från externa källor.

Bokhandelns orderrader är ett exempel på information om egna transaktioner.

En förlagskatalog med författare, ISBN och boktitlar kan däremot vara information vi tar emot utifrån.

När vi sammanför dem behöver vi identifiera vilka uppgifter som ska betraktas som **auktoritativa**.

Om förlaget ändrar stavningen av en titel kanske vi bör uppdatera kataloginformationen. Men ett gammalt orderpris bör inte automatiskt ändras när katalogens aktuella produktpris förändras.

Analysmodellen behöver alltså bevara **betydelsen och ursprunget** för uppgifterna, även när de förs samman.

### Att bevara historiska förändringar

Anta att en bok i oktober kategoriseras som `Roman` men senare flyttas till en annan produkttyp.

När vi analyserar försäljningen i oktober behöver vi bestämma om den ska visas enligt:

- Produktens **nuvarande** kategori.
- Den kategori som gällde **när försäljningen skedde**.

Båda kan vara relevanta, men de besvarar olika frågor.

I datalager kan man hantera sådana förändringar med olika strategier för **långsamt föränderliga dimensioner**, ofta kallade *Slowly Changing Dimensions* (SCD).

En enkel strategi är att ersätta det gamla värdet. En annan är att bevara flera versioner med giltighetsperioder.

Det här är ett exempel på hur **tid blir en del av datamodellens betydelse**.

### Transformationer behöver kvalitetskontroller

Vi kan inte utgå från att en datapipeline producerar korrekta data bara för att varje SQL-sats körts utan fel.

Exempel på relevanta kontroller är:

- Har alla orderrader fått en giltig produktreferens?
- Har vi råkat läsa in samma händelser flera gånger?
- Stämmer antalet rader och summan av relevanta mätvärden mellan källa och mål?
- Saknas datum eller viktiga dimensioner?

Vi behöver också veta hur vi ska hantera sena uppdateringar, rättelser och återkörningar.

En transformation bör om möjligt vara **idempotent**: om samma inläsning upprepas av misstag ska den inte skapa dubbla försäljningshändelser.

Hur vi uppnår det kan bero på stabila händelseidentifierare, unika nycklar, inläsningslogik och transaktioner.

### Att mäta utan att missförstå

Anta att vi tar fram en rapport över de produkter som har högst försäljningsvärde.

Det låter enkelt, men först måste vi bestämma vad resultatet betyder.

Ska vi räkna:

- Lagda beställningar eller genomförda försäljningar?
- Priser före eller efter rabatt?
- Värden inklusive eller exklusive moms?
- Returer som negativa försäljningar eller som separata händelser?

SQL kan summera de värden vi har lagrat. Men SQL kan inte avgöra **vilken verksamhetsdefinition vi borde använda**.

Här möts datakvalitet, datamodellering och analys.

### SQL som gemensamt språk

SQL är inte bara användbart för små transaktionstabeller.

Samma grundläggande idéer – urval, filtrering, JOIN, aggregering, CTE:er och fönsterfunktioner – återkommer i många analysplattformar.

Olika system har olika SQL-dialekter och olika sätt att hantera stora datamängder. Men principen att beskriva **vilket resultat vi vill få** i stället för exakt hur det ska beräknas är fortfarande central.

Vi kan alltså använda kunskaper från de tidigare kapitlen i ett större sammanhang, även när lagringen inte längre sker i en enda traditionell SQL-databas.

### Från händelser till kunskap

Bokhandelns operativa databas hjälper oss att veta **vad som hände i en viss beställning**.

En analysmodell kan hjälpa oss att förstå **hur många liknande händelser som skett**, hur de förändras över tid och hur de förhåller sig till andra delar av verksamheten.

Men mer data ger inte automatiskt mer kunskap.

När vi sammanställer information behöver vi hela tiden förstå vad varje rad representerar, var uppgifterna kommer ifrån och vilka antaganden våra beräkningar bygger på.

En bra dataplattform är därför inte bara en plats där vi samlar data. Den behöver också hjälpa oss att bevara och förklara **informationens betydelse när vi använder den på nya sätt**.

## Reflektion

1. Vad är skillnaden mellan att registrera en beställning och att använda samma beställning som underlag för analys?
2. Varför behöver vi bestämma vad en rad i en faktatabell representerar innan vi kan avgöra vilka analyser som är möjliga?
3. Hur kan två rapporter över samma försäljning ge olika men ändå rimliga resultat beroende på hur vi definierar måttet?

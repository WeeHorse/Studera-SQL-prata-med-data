# 4. Datatyper och värden

Ett värde betyder inte särskilt mycket utan ett sammanhang.

Talet `123` kan vara ett antal, ett pris, ett postnummer eller en identifierare. Samma värde kan representera helt olika saker beroende på vad vi har bestämt att det ska betyda.

En **datatyp** beskriver vilka slags värden vi kan hantera och vilka operationer som är möjliga med dem. Men det är sammanhanget som talar om vad värdet *betyder*.

Vissa datatyper är enkla, exempelvis heltal och text. Andra representerar mer sammansatt information, exempelvis datum, geografiska positioner eller JSON-strukturer. Och när vi bygger en datamodell kan vi själva beskriva mer komplexa företeelser, som en kund eller en produkt.

Att välja datatyper handlar därför inte bara om lagring. Det handlar också om **hur vi beskriver verkligheten**.

## Grund

### Samma tecken, olika betydelse

Titta på dessa värden:

```text
123
'123'
```

Det första kan vi behandla som ett tal och det andra som text. De ser nästan likadana ut, men vi vill kunna göra olika saker med dem.

Med talet `123` kan vi räkna:

```sql
SELECT 123 + 10;
```

Det ger `133`.

Men om `'123'` är början på ett telefonnummer eller ett artikelnummer kanske det inte är meningsfullt att addera 10.

En datatyp hjälper oss att skilja mellan olika slags värden. **Vilken datatyp vi väljer ska bero på hur informationen ska användas, inte bara hur den ser ut.**

### Några vanliga datatyper

SQL har många datatyper. Vi börjar med några av de viktigaste.

| Datatyp | Används för | Exempel |
|---|---|---|
| `INTEGER` | Heltal | `12` |
| `DECIMAL` | Exakta decimaltal | `199.90` |
| `VARCHAR` | Text av varierande längd | `'Vägen hem'` |
| `CHAR` | Text med bestämd längd | `'SE'` |
| `BOOLEAN` | Sant eller falskt | `TRUE` |
| `DATE` | Datum | `'2001-05-12'` |

Vi kommer att arbeta med fler datatyper efter hand, men dessa räcker långt.

Datatypernas exakta namn och implementationer varierar mellan olika databassystem. Det gäller särskilt `BOOLEAN`.[^boolean]

[^boolean]: PostgreSQL har en boolesk datatyp. I MySQL är `BOOLEAN` ett alias för `TINYINT(1)`, och SQLite representerar vanligtvis booleska värden med heltalen 0 och 1. SQL Server använder `BIT`. Vi använder `BOOLEAN` som ett begripligt, standardnära begrepp här.

### Heltal och decimaltal

Antalet böcker i lager är ett heltal:

```text
stock: 12
```

Ett pris kan däremot innehålla decimaler:

```text
price: 199.90
```

Därför behöver vi skilja mellan heltal, exakta decimaltal och approximativa tal.

Vanliga typer är:

- `INTEGER` för heltal.
- `DECIMAL(10, 2)` för exakta decimaltal med upp till tio siffror, varav två efter decimaltecknet.
- `FLOAT` och `DOUBLE` för approximativa flyttal.

Vi brukar föredra `DECIMAL` framför flyttal när vi lagrar pengar eftersom vissa decimaltal inte kan representeras exakt som binära flyttal.

### Text är inte bara bokstäver

Vi lagrar namn och boktitlar som text:

```text
title: Vägen hem
```

Men även uppgifter som bara består av siffror kan vara text.

Ett postnummer, exempelvis `01234`, är ingen storhet vi ska räkna med. Nollan i början är en del av beteckningen och får inte försvinna.

Detsamma gäller ofta telefonnummer, ISBN och andra identifierare.

För text använder vi bland annat `VARCHAR` och `CHAR`. Om vi exempelvis behöver lagra en titel med högst 200 tecken kan vi ange `VARCHAR(200)`.

Vi återkommer till hur detta används när vi börjar skapa tabeller.

### Datum och booleska värden

En kunds födelsedatum är inte bara en godtycklig textsträng. Vi vill kunna jämföra datum och beräkna tidsavstånd.

Därför använder vi en datumtyp, exempelvis `DATE`.

```text
birthday: 1982-09-03
```

På samma sätt kan ett påstående vara sant eller falskt:

```text
active: TRUE
```

Datatypen `BOOLEAN` uttrycker just detta.

Vi behöver inte gå in på datumformat, tidszoner eller datumberäkningar ännu. Det gör vi i kapitlet om datum och tid.

### NULL – när värdet saknas

I en databastabell kanske vi ännu inte känner till kundens födelsedatum.

SQL använder `NULL` för att ange att ett värde saknas.

Det är viktigt att skilja på dessa exempel:

```text
age: 0
name: ''
birthday: NULL
```

`0` är ett tal. `''` är en tom textsträng. `NULL` betyder att det inte finns något känt värde i kolumnen.

Detta får betydelse när vi söker och räknar med data. Vi kommer tillbaka till `NULL` i kommande kapitel.

### Från värden till attribut

I bokhandeln vill vi beskriva en produkt med namn, pris och antal i lager:

```text
Produkt:
    Titel: Vägen hem
    Pris: 200.00
    Lagersaldo: 12
```

Vi har då valt vilken information som ska höra till en produkt.

Det kan representeras som en tabell:

**products**

| id | title | price | stock |
|---|---|---:|---:|
| 1 | Vägen hem | 200.00 | 12 |
| 2 | Den blå staden | 150.00 | 0 |
| 3 | Vinterljus | 249.00 | 4 |

Varje kolumn behöver en datatyp:

| Attribut | Datatyp | Vad värdet betyder |
|---|---|---|
| `id` | `INTEGER` | Produktens identifierare |
| `title` | `VARCHAR(200)` | Produktens titel |
| `price` | `DECIMAL(10, 2)` | Produktens pris |
| `stock` | `INTEGER` | Antalet exemplar i lager |

Här har vi inte bara valt datatyper. Vi har också skapat en **modell av vad en produkt är** i just vår bokhandel.

### En giltig datatyp räcker inte

Datatypen `INTEGER` kan representera negativa tal. Men innebär det att ett lagersaldo på `-12` är rimligt?

Inte om vi bestämt att lagersaldot beskriver antalet exemplar som faktiskt finns tillgängliga.

Vi kan därför skilja mellan tre nivåer:

1. **Datatyp:** `INTEGER` – vi tillåter heltal.
2. **Betydelse:** `stock` – värdet beskriver antal exemplar.
3. **Regel:** Lagersaldot får inte vara negativt.

Vi skulle senare kunna uttrycka regeln i databasen med en begränsning, exempelvis `CHECK (stock >= 0)`.

Det visar en viktig skillnad: **Ett värde kan vara tekniskt giltigt för sin datatyp, men ändå vara felaktigt i verksamhetens sammanhang.**

## Avancerat

### Enkla och sammansatta värden

Ett heltal eller en textsträng är exempel på värden som vi vanligtvis behandlar som en enda enhet. De brukar kallas **skalära värden**.

Andra datatyper rymmer en tydligare intern struktur.

Exempelvis kan ett JSON-värde innehålla flera namngivna uppgifter:

```json
{
  "street": "Hemmagatan 1",
  "postalCode": "124 56",
  "city": "Hemmavan"
}
```

En geografisk punkt kan beskrivas med koordinater. Ett datum har också en meningsfull intern uppbyggnad, även om `DATE` i SQL normalt används som ett skalärt värde.

Det är alltså inte alltid en skarp gräns mellan *enkel* och *komplex* information. Vi behöver skilja mellan hur människor uppfattar värdet, hur det representeras och hur databassystemet behandlar typen.

JSON, geometriska typer och andra utökningar varierar mellan SQL-dialekter. Vi kommer att undersöka dem mer ingående längre fram.

### Har vi skapat datatypen Produkt?

När vi bestämmer att en produkt har `title`, `price` och `stock` har vi i en begreppslig mening definierat en egen **sammansatt typ: Produkt**.

Vi har bestämt vilka egenskaper den har och vilka värden som kan vara rimliga.

Det betyder däremot inte att `CREATE TABLE products` automatiskt skapar en ny användardefinierad SQL-datatyp med namnet `Produkt`.

I SQL skiljer vi på datatyper, tabeller och de regler som hör till tabellernas kolumner. Vissa databassystem har dessutom särskilt stöd för egna sammansatta datatyper.[^custom-types]

[^custom-types]: PostgreSQL stöder exempelvis sammansatta typer (*composite types*). Detta är något annat än att bara skapa en tabell som representerar en entitet.

Den viktiga poängen är att datamodellering också handlar om att definiera **vilka slags saker** vårt system ska kunna beskriva.

### Precision och ungefärliga värden

Ett pris som `199.90` bör kunna representeras på ett förutsägbart sätt.

Med `DECIMAL(10, 2)` beskriver vi ett exakt decimaltal med en bestämd precision och skala. Med `FLOAT` eller `DOUBLE` arbetar vi däremot med approximativa värden, vilket ofta är praktiskt för mätningar och vetenskapliga beräkningar.

Inget av alternativen är automatiskt bäst. Vi väljer efter vad värdet betyder och vad vi behöver kunna göra med det.

### När databasen omvandlar värden

Vi kan ibland behöva omvandla information från en datatyp till en annan.

```sql
SELECT CAST('123' AS INTEGER);
```

Här ber vi databasen att tolka texten `'123'` som ett heltal.

En del SQL-system gör även automatiska typomvandlingar. Det är bekvämt, men kan ibland dölja fel eller ge oväntade resultat.

Därför är det bra att förstå vilken datatyp ett värde har, även när databashanteraren verkar kunna gissa rätt.

### När samma värde får olika betydelse

Tänk dig att vi har dessa två attribut:

```text
product_id: 123
stock: 123
```

Båda kan lagras som heltal. Men de beskriver olika saker.

Det ena är en **identifierare**, det andra en **kvantitet**.

Det är meningsfullt att beräkna `stock + 10`, men knappast att beräkna `product_id + 10` för att beskriva något om produkten.

Den skillnaden syns inte alltid i själva SQL-datatypen. Den finns i vår modell och i hur vi använder informationen.

### När regler blir en del av modellen

En produkt kanske måste ha en titel, ett pris som inte är negativt och ett lagersaldo som inte understiger noll.

Vi kan uttrycka flera sådana krav med datatyper och begränsningar:

```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock INTEGER NOT NULL,
    CHECK (price >= 0),
    CHECK (stock >= 0)
);
```

Vi behöver inte behärska `CREATE TABLE` ännu. Exemplet visar bara hur våra beslut om informationens betydelse senare kan bli **regler som databasen själv kontrollerar**.

Det betyder inte att alla verksamhetsregler hör hemma i databasen. Men regler som avgör vilka datatillstånd vi accepterar är ofta naturliga att uttrycka nära informationen.

Vi återkommer till detta när vi skapar tabeller och när vi diskuterar skillnaden mellan informationshantering och processer.

## Reflektion

1. Varför kan ett postnummer behöva lagras som text, trots att det bara innehåller siffror?
2. Är `-12` ett felaktigt heltal eller ett felaktigt lagersaldo? Vad är skillnaden?
3. Vad har vi egentligen bestämt när vi säger att vår datamodell innehåller en *Produkt* med titel, pris och lagersaldo?

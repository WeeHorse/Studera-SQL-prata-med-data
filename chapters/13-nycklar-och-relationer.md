# 13. Nycklar och relationer

En bokhandel kan ha flera kunder med samma namn, flera böcker med samma titel och flera adresser på samma gata. Hur vet vi då vilken kund, produkt eller adress vi menar?

Vi behöver kunna identifiera en bestämd post. Men vi behöver också kunna beskriva hur olika poster hör ihop: vilken kund en adress tillhör, eller vilken produkttyp en bok har.

En nyckel är inte bara ett tekniskt nummer. Den hjälper oss att uttrycka **identitet och samband** i vår modell.

## Grund

### Primärnyckeln identifierar en rad

Vi har tidigare arbetat med kunderna:

**customers**

| id | name |
|---|---|
| 1 | Benjamin |
| 2 | Olof |
| 3 | Anaïs |

Kolumnen `id` är vår **primärnyckel**, eller *primary key*.

Den identifierar varje rad i tabellen. Två kunder kan heta Olof, men de ska inte ha samma `id`.

```sql
CREATE TABLE customers (
    id INTEGER PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(200),
    birthday DATE
);
```

En primärnyckel ska vara **unik** och får inte vara `NULL`. När vi skriver:

```sql
SELECT *
FROM customers
WHERE id = 2;
```

menar vi den bestämda kundrad vars `id` är `2`, oavsett om andra kunder råkar ha samma namn.

### Varför räcker inte namnet?

Vi skulle kunna försöka använda kundens namn som identifikation, men namn är inte säkert unika. De kan dessutom förändras.

Samma problem gäller exempelvis boktitlar: olika böcker kan heta samma sak och en bok kan få en annan titel i en ny utgåva.

Därför använder vi ofta en separat identifierare, som `id`, i stället för ett beskrivande attribut.

Det är ett modelleringsbeslut: vi skiljer mellan **vem eller vad något är** och **hur vi beskriver det**.

### Främmande nycklar uttrycker samband

Vi har också tabellen `addresses`:

| id | customer_id | street | city |
|---|---|---|---|
| 1 | 1 | Hemmagatan 1 | Hemmavan |
| 2 | 1 | Storgatan 4 | Storfors |
| 3 | 2 | Parkvägen 2 | Storfors |

`customer_id` anger vilken kund adressen hör till. Det är en **främmande nyckel**, eller *foreign key*.

En främmande nyckel innehåller ett värde som refererar till en nyckel i en annan tabell.

```sql
CREATE TABLE addresses (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    street VARCHAR(200),
    postal_code VARCHAR(20),
    city VARCHAR(100),
    FOREIGN KEY (customer_id)
        REFERENCES customers(id)
);
```

Detta uttrycker att värdet i `addresses.customer_id` måste referera till en existerande rad i `customers`.

Om en adress har `customer_id = 2` pekar den på Olofs kundrad, inte på adressen med `id = 2`.

### Referensintegritet

Tänk att vi försöker registrera en adress som har `customer_id = 99`, men att det inte finns någon kund med `id = 99`.

Utan en främmande nyckel skulle databasen kunna acceptera referensen, trots att sambandet inte går att följa.

Med `FOREIGN KEY` kan databasen kontrollera att relationen är giltig. Det kallas **referensintegritet**.

En främmande nyckel behöver alltså inte ha ett unikt värde. Benjamin kan ha två adresser, båda med `customer_id = 1`. Det är precis vad vår en-till-många-relation innebär.

### En relation mellan produkter och produkttyper

Vi har organiserat produktens typ i en egen tabell:

**product_types**

| id | name |
|---|---|
| 1 | Roman |
| 2 | Novellsamling |

Varje produkt innehåller då ett `product_type_id` som hänvisar till produkttypen.

```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    product_type_id INTEGER,
    CHECK (price >= 0),
    CHECK (stock >= 0),
    FOREIGN KEY (product_type_id)
        REFERENCES product_types(id)
);
```

Vi kan nu använda `JOIN` för att visa produkterna tillsammans med namnen på deras typer, utan att behöva lagra typnamnet på varje produkt.

Notera att `product_type_id` här får vara `NULL`: vi har inte skrivit `NOT NULL`. Vi tillåter alltså att en produkt ännu saknar registrerad typ.

### UNIQUE – en annan sorts unikhet

En tabell har en primärnyckel, men kan ha andra kolumner som också behöver innehålla unika värden.

Exempelvis kanske varje produkttyp ska ha ett eget namn:

```sql
CREATE TABLE product_types (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);
```

`UNIQUE` förhindrar att samma värde förekommer flera gånger i kolumnen enligt databasens jämförelseregler.

Skillnaden är att **primärnyckeln identifierar raden**, medan `UNIQUE` kan skydda ytterligare värden från att upprepas.

Reglerna för `NULL` i en `UNIQUE`-kolumn skiljer sig mellan databassystem.[^unique]

[^unique]: Många SQL-system tillåter flera `NULL`-värden i en `UNIQUE`-kolumn eftersom okända värden inte behandlas som identiska. SQL Server har andra standardregler för enkla unika begränsningar. Kollationer kan dessutom påverka om olika textvärden räknas som samma.

### När vi skapar tabellerna spelar ordningen roll

Om `addresses` ska referera till `customers` behöver kundtabellen normalt finnas när vi definierar den främmande nyckeln.

En lämplig ordning är alltså:

1. Skapa `customers`.
2. Skapa `addresses` med en främmande nyckel till `customers`.

Detsamma gäller `product_types` före `products` när produkterna har en främmande nyckel till typerna.

Vi har därmed skapat en struktur som kan ta emot data och samtidigt kontrollera några av relationerna mellan den.

## Avancerat

### Vad händer när en relaterad rad tas bort?

Anta att Benjamin har registrerade adresser. Vad ska hända om hans kundrad tas bort?

Databasen kan inte gissa vad verksamheten vill.

När vi skapar den främmande nyckeln kan vi ange en regel, exempelvis:

```sql
FOREIGN KEY (customer_id)
    REFERENCES customers(id)
    ON DELETE RESTRICT
```

Det innebär att vi inte kan ta bort kunden så länge adresser refererar till honom.

Ett annat alternativ är:

```sql
FOREIGN KEY (customer_id)
    REFERENCES customers(id)
    ON DELETE CASCADE
```

Då tas även de adresser som refererar till kunden bort när kundraden tas bort.

Andra alternativ kan bland annat innebära att referensen sätts till `NULL` om kolumnen tillåter det.

Det här är **inte bara syntaxval**. Olika alternativ uttrycker olika regler om relationens betydelse, och `CASCADE` kan få stora konsekvenser när många poster hör ihop.[^actions]

[^actions]: Stödet för referensåtgärder och detaljerna kring `RESTRICT`, `NO ACTION`, `SET NULL` och `CASCADE` skiljer sig något mellan SQL-system. I MySQL behöver tabellerna bland annat använda en lagringsmotor som stöder främmande nycklar, exempelvis InnoDB.

### När flera kolumner tillsammans är en nyckel

En primärnyckel måste inte bestå av en enda kolumn.

Föreställ dig att vi har en tabell som anger vilka författare som hör till vilka produkter:

**product_authors**

| product_id | author_id |
|---|---|
| 1 | 4 |
| 1 | 7 |
| 2 | 4 |

En produkt kan ha flera författare, och en författare kan vara knuten till flera produkter.

Här kan **kombinationen** av `product_id` och `author_id` vara unik:

```sql
CREATE TABLE product_authors (
    product_id INTEGER NOT NULL,
    author_id INTEGER NOT NULL,
    PRIMARY KEY (product_id, author_id),
    FOREIGN KEY (product_id)
        REFERENCES products(id),
    FOREIGN KEY (author_id)
        REFERENCES authors(id)
);
```

Vi förutsätter här att tabellen `authors` redan finns. Vi bygger ut den modellen ordentligt i nästa kapitel.

Den sammansatta primärnyckeln förhindrar att vi registrerar samma produkt–författare-koppling två gånger.

### Identitet är inte alltid ett löpnummer

Vi använder oftast `id` som ett heltal i exemplen eftersom det är lätt att läsa.

Men i verkliga system kan en identifierare exempelvis vara en UUID eller bestå av flera attribut.

En identifierare behöver inte heller alltid vara automatiskt genererad. Det avgörande är att vi kan lita på dess identitet och reglerna kring den.

Vi ska skilja mellan en **naturlig nyckel** – ett identifierande värde från verksamheten – och en **surrogatnyckel** som skapas för databasmodellen, exempelvis ett löpnummer.

Vilket alternativ som passar bäst beror på hur stabilt det identifierande värdet är och hur modellen ska användas.

### Främmande nyckel är inte samma sak som normalisering

Vi har nu lärt oss att uttrycka att en adress hör till en kund eller att en produkt har en produkttyp.

Men bara för att vi använder främmande nycklar betyder det inte att vår modell automatiskt är väl organiserad.

Vi kan fortfarande lagra samma information på flera ställen, välja attribut som hör till fel entitet eller skapa beroenden som gör uppdateringar svåra.

Främmande nycklar skyddar **relationernas giltighet**. Normalisering hjälper oss att undersöka **var informationen hör hemma** och vilka beroenden som finns mellan attribut.

Det är nästa steg.

### Egen information och information om någon annan

Tänk dig en produkt med följande attribut:

```text
title: Vägen hem
author_name: Anna Svensson
product_type_name: Roman
```

Titeln beskriver själva produkten. Men `author_name` beskriver en författare och `product_type_name` beskriver en produkttyp.

Vi kan fråga: **Vilken företeelse äger egentligen den här informationen?**

Det är inte alltid så enkelt som att varje attribut bara har en självklar hemvist. Men frågan hjälper oss att upptäcka upprepningar och möjliga relationer.

I nästa kapitel använder vi denna tanke som ingång till datamodellering och normalformerna.

## Reflektion

1. Varför kan vi behöva en primärnyckel även när varje kund redan har ett namn?
2. Vad innebär det för verksamheten att välja `ON DELETE CASCADE` i stället för att förhindra borttagningen?
3. Vad är skillnaden mellan att en relation är giltig och att informationen är organiserad på ett bra sätt?

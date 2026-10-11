# 12. Att skapa tabeller

Hittills har vi arbetat med bokhandelns kunder, adresser och produkter som om tabellerna redan fanns.

Men om vi faktiskt bygger databasens tabeller, vilka uppgifter ska en produkt ha? Vilka värden ska vi tillåta? Vilka begränsningar och regler vill vi ha – vad händer om någon försöker registrera en produkt utan titel?

När vi skapar en tabell går vi från vår **idé om informationen** till en struktur för praktisk användning.

## Grund

### Från modell till tabell

Vi har beskrivit bokhandelns produkter med fyra attribut:

| Attribut | Betydelse | Datatyp |
|---|---|---|
| `id` | Identifierar produkten | `INTEGER` |
| `title` | Produktens titel | `VARCHAR(200)` |
| `price` | Produktens pris | `DECIMAL(10, 2)` |
| `stock` | Antalet exemplar i lager | `INTEGER` |

Nu kan vi skapa tabellen med `CREATE TABLE`:

```sql
CREATE TABLE products (
    id INTEGER,
    title VARCHAR(200),
    price DECIMAL(10, 2),
    stock INTEGER
);
```

Vi anger tabellens namn och därefter kolumnerna inom parentes. Varje kolumn har ett namn och en datatyp. Kommatecken skiljer kolumndefinitionerna åt.

Kommandot skapar själva **strukturen**, inte produkterna. Tabellen är fortfarande tom.

### En tabell behöver inte innehålla data

Vi kan kontrollera att en tom tabell finns genom att försöka läsa den:

```sql
SELECT *
FROM products;
```

Resultatet innehåller inga rader, men tabellen har fortfarande sina fyra kolumner.

Det är samma skillnad som mellan att bestämma vad en produkt *kan vara* och att faktiskt registrera en produkt.

Att lägga till själva produkterna gör vi med `INSERT` i nästa kapitel.

### Att välja rätt datatyper

Vi känner redan till `INTEGER`, `VARCHAR` och `DECIMAL`. Nu använder vi dem för att bestämma vilka värden kolumnerna ska kunna representera.

Exempelvis:

```sql
title VARCHAR(200)
price DECIMAL(10, 2)
```

Det betyder att titeln är text med högst 200 tecken och priset ett exakt decimaltal med tio siffrors precision och två decimalplatser.

Vi bör välja datatyp efter uppgiftens **betydelse**, inte bara efter hur den råkar skrivas. Ett postnummer kan exempelvis vara text trots att det består av siffror.

### NOT NULL – när en uppgift krävs

En produkt utan titel är kanske inte en giltig produkt i vår bokhandel.

Vi kan därför ange att kolumnen inte får sakna värde:

```sql
CREATE TABLE products (
    id INTEGER,
    title VARCHAR(200) NOT NULL,
    price DECIMAL(10, 2),
    stock INTEGER
);
```

`NOT NULL` säger att kolumnen måste innehålla ett värde som inte är `NULL`.

Det betyder däremot inte att texten är meningsfull. En tom sträng `''` kan fortfarande vara möjlig att lagra. Regeln hindrar ett saknat värde, inte varje tänkbart kvalitetsproblem.

### PRIMARY KEY – att identifiera en rad

Vi har tidigare använt `id` för att hitta en bestämd kund eller produkt.

När vi skapar tabellen kan vi ange att `id` är dess **primärnyckel**:

```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    price DECIMAL(10, 2),
    stock INTEGER
);
```

En primärnyckel identifierar varje rad. Dess värde ska vara unikt och får inte vara `NULL`.

Vi ska senare ägna ett helt kapitel åt nycklar och begränsningar. Här räcker det att se hur ett av våra viktigaste modelleringsbeslut blir en del av tabellen.

### DEFAULT – ett förvalt värde

Anta att vi registrerar en produkt men ännu inte har några exemplar av den i lager.

Vi kan ange ett standardvärde för `stock`:

```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0
);
```

`DEFAULT 0` betyder att databasen använder värdet noll när vi skapar en rad utan att ange något lagersaldo.

Observera att `DEFAULT` inte hindrar andra värden. Regeln avgör bara vad som används när ett värde utelämnas.

### CHECK – tillåt bara rimliga värden

Datatypen `INTEGER` tillåter negativa tal. Men vår modell säger att lagersaldot inte får vara negativt.

Vi kan uttrycka det med `CHECK`:

```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    CHECK (price >= 0),
    CHECK (stock >= 0)
);
```

Om någon försöker registrera ett negativt lagersaldo ska databasen neka ändringen.

Vi har nu uttryckt tre olika beslut:

- `INTEGER`: värdet är ett heltal.
- `NOT NULL`: värdet måste finnas.
- `CHECK (stock >= 0)`: värdet får inte vara negativt.

Tillsammans gör de vår modell mer precis.

### Att skapa fler tabeller

Vi kan använda samma princip för bokhandelns kunder:

```sql
CREATE TABLE customers (
    id INTEGER PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(200),
    birthday DATE
);
```

Vi kräver ett namn, men tillåter att e-postadress och födelsedatum saknas.

Och för produkttyperna:

```sql
CREATE TABLE product_types (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);
```

Produkttyperna representerar **referensdata**: en begränsad uppsättning kategorier som vi använder när vi beskriver produkter.

Produkterna kan sedan hänvisa till en typ med `product_type_id`. Exakt hur vi säkrar den relationen återkommer vi till i kapitlet om främmande nycklar.

## Avancerat

### Databasstruktur som ett kontrakt

När vi skapar tabellen beskriver vi inte bara hur vi tänker använda informationen. Vi anger också regler som databasen ska tillämpa på framtida förändringar.

Det fungerar som ett **kontrakt** mellan datamodellen och de program eller personer som skriver data.

Om priset inte får vara negativt behöver inte varje program uppfinna sin egen version av den grundläggande kontrollen.

Men databasen kan inte automatiskt avgöra alla verksamhetsfrågor. Vad ett rimligt pris är, om en bok bör säljas och vem som får ändra priset är andra slags beslut.

### Kolumnbegränsningar och tabellbegränsningar

Vi kan skriva vissa regler direkt efter en kolumn:

```sql
price DECIMAL(10, 2) NOT NULL
```

Andra regler kan stå som separata begränsningar:

```sql
CHECK (price >= 0)
```

En tabellbegränsning kan även omfatta flera kolumner. Föreställ dig att vi längre fram registrerar både ett startdatum och ett slutdatum för en kampanj:

```sql
CHECK (ends_on >= starts_on)
```

Då uttrycker regeln ett förhållande mellan två attribut.

### Beroenden mellan tabeller

Vi har organiserat produkttypens namn i `product_types` och låter produkten lagra `product_type_id`.

En möjlig definition är:

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

Nu uttrycker vi även **relationen** mellan produkterna och deras typer. En produkt kan inte hänvisa till en produkttyp som saknas i referenstabellen.

Vi behöver skapa `product_types` före `products` om tabellen ska referera till den direkt.

Hur främmande nycklar fungerar och vilka regler vi vill ha för relationer behandlar vi mer utförligt längre fram.

### Datatyper och SQL-dialekter

Exemplen i kapitlet är avsiktligt standardnära, men databassystemen skiljer sig åt.

Särskilt skapandet av automatiskt genererade id-värden varierar. MySQL använder ofta `AUTO_INCREMENT`, PostgreSQL har bland annat identitetskolumner och SQL Server använder `IDENTITY`.

Vi har därför inte låtit databasen generera id-värden automatiskt i exemplen. Vi återkommer till detta när vi lägger till data.[^ids]

[^ids]: En del databasimplementationer har dessutom särskilda regler kring primärnycklar, `NULL` och begränsningar. Exempelvis kräver vissa SQLite-tabellformer en uttrycklig `NOT NULL` för att en icke-heltals-primärnyckel alltid ska avvisa `NULL`. Det här kapitlet beskriver den avsedda, standardnära modellen.

Även `CHECK` stöds och tillämpas olika i äldre databassystem. Exempelvis började MySQL tillämpa `CHECK`-begränsningar från version 8.0.16.[^checks]

[^checks]: I äldre MySQL-versioner kunde `CHECK`-syntax accepteras utan att villkoren upprätthölls. Kontrollera version och databassystem när reglerna är kritiska.

### Att förändra en befintlig struktur

Vad händer om vi vill lägga till `product_type_id` när tabellen redan finns?

Då behöver vi ändra strukturen i stället för att skapa tabellen på nytt. SQL har bland annat `ALTER TABLE`:

```sql
ALTER TABLE products
ADD COLUMN product_type_id INTEGER;
```

Vi går igenom förändringar av befintliga tabeller mer ordentligt i ett senare kapitel. Där tar vi också upp vad som händer när tabellen redan innehåller data.

### DROP TABLE – att ta bort strukturen

Vi kan också ta bort en tabell:

```sql
DROP TABLE products;
```

Detta tar normalt bort både tabellstrukturen och dess data.

Kommandot är därför något helt annat än att ta bort en enskild produkt. Vi ska skilja noga mellan att förändra **databasens struktur** och att förändra **raderna i en tabell**.

### Modellen är alltid ett urval

Vi har bestämt att en produkt har en titel, ett pris och ett lagersaldo.

Men en verklig bokhandel skulle kanske också behöva ISBN, författare, språk, upplaga, leverantörer och flera olika lagerplatser.

Modellen är alltså inte en fullständig beskrivning av allt som en produkt *kan vara*. Den är en beskrivning av den information vi för tillfället behöver kunna hantera på ett kontrollerat sätt.

När behoven ändras kan modellen behöva utvecklas. Det är en anledning till att vi skiljer mellan datamodellering, databasstruktur och applikationernas arbetssätt.

## Reflektion

1. Vad är skillnaden mellan att en kolumn har datatypen `INTEGER` och att vi kräver att dess värde ska vara större än eller lika med noll?
2. Vilka regler bör databasen själv upprätthålla, och vilka beslut kan behöva fattas någon annanstans?
3. När vi skapar tabellen `products`, har vi då beskrivit vad en produkt *är*, eller vad vi just nu behöver *veta om* en produkt?

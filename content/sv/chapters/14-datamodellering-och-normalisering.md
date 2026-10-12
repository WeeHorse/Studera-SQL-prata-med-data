# 14. Datamodellering och normalisering

En bokhandel behöver veta vilka produkter den säljer, vilka författare som skrivit böckerna och vilka produkttyper böckerna tillhör.

Vi skulle kunna lagra all information på varje produktrad. Då blir den lätt att läsa på ett ställe. Men om samma författare förekommer på hundra böcker behöver vi också skriva samma författarinformation hundra gånger.

Vad händer när författaren byter namn? Eller om vi vill registrera en författare som ännu inte har någon produkt i sortimentet?

När vi modellerar data behöver vi därför fråga oss: **Vilken information hör till vilken företeelse?**

Normalisering syftar till att undvika onödig dubbellagring av data, skapa god dataintegritet och göra databasen lättare att förändra och bygga ut. Om vi lagrar ett sakförhållande på flera ställen kan vi behöva ändra det överallt – och riskerar att missa något.

Det finns flera **normalformer**. Varje normalform ställer ytterligare krav på hur informationen organiseras. Målet är inte att skapa så många tabeller som möjligt, utan att varje uppgift ska ha en tydlig plats och att samband ska kunna beskrivas utan onödig upprepning.

## Grund

### Egen information och information om något annat

Tänk dig att vi börjar med en enda tabell för böcker:

**products**

| id | title | price | author_name | author_email | product_type |
|---|---|---:|---|---|---|
| 1 | Vägen hem | 200.00 | Anna Svensson | anna@authors.example | Roman |
| 2 | Den blå staden | 150.00 | Erik Lund | erik@authors.example | Roman |
| 3 | Vinterljus | 249.00 | Anna Svensson | anna@authors.example | Roman |
| 4 | Små historier | 120.00 | Erik Lund | erik@authors.example | Novellsamling |

Här blandar vi tre slags information:

- Produktens egen information: titel och pris.
- Information om en annan företeelse: författarens namn och e-postadress.
- En klassificering: produkttypen.

Tabellen fungerar för våra fyra böcker. Men vissa uppgifter upprepas.

Att skilja mellan **egen data och främmande data** är en användbar första tanke när vi förbättrar modellen. Det är dock inte en fullständig definition av normalisering. För att förstå varför vi ska dela upp informationen behöver vi också undersöka beroenden mellan värden.

### När information upprepas

Anna Svenssons namn och e-postadress förekommer på två produktrader.

Det kan skapa flera problem:

**Uppdateringsproblem:** Om Anna byter e-postadress måste vi ändra informationen på flera ställen. Missar vi ett av dem får databasen motstridiga uppgifter.

**Infogningsproblem:** Om vi vill registrera en ny författare innan vi har en bok att koppla till författaren finns ingen naturlig rad att lägga informationen på.

**Borttagningsproblem:** Om vi tar bort den sista boken av Erik Lund riskerar även den enda lagrade informationen om honom att försvinna.

Detta brukar kallas *anomalier*. De är tecken på att vår struktur kan behöva förändras.

### Ge författaren en egen identitet

Vi kan börja med att skapa en egen tabell för författare:

**authors**

| id | name | email |
|---|---|---|
| 1 | Anna Svensson | anna@authors.example |
| 2 | Erik Lund | erik@authors.example |

Då behöver vi inte skriva författarens namn och e-postadress på varje produkt.

Men hur kopplar vi produkten till författaren?

Vi skulle kunna lagra `author_id` i `products`. Det fungerar om varje produkt alltid har exakt en författare.

I vår bokhandel vill vi däremot kunna hantera böcker med flera författare.

### En kopplingstabell för flera-till-flera

I stället skapar vi `product_authors`:

**product_authors**

| product_id | author_id |
|---|---|
| 1 | 1 |
| 2 | 2 |
| 3 | 1 |
| 4 | 2 |

Den innehåller relationer mellan produkter och författare.

Om en bok skrivits av två författare registrerar vi helt enkelt två kopplingar till samma produkt.

Med SQL kan vi uttrycka tabellen så här:

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

Nu kan en författare finnas oberoende av produkterna, samtidigt som en produkt kan ha flera författare.

Vi har alltså inte bara *flyttat kolumner*. Vi har gjort relationen mellan företeelserna tydligare.

### Referensdata har också en egen plats

Vi har tidigare skapat tabellen `product_types`:

| id | name |
|---|---|
| 1 | Roman |
| 2 | Novellsamling |

I `products` lagrar vi därför `product_type_id`, inte typnamnet på varje rad.

Produkttypen är här **referensdata**: en kategori som används för att beskriva produkterna.

En författare är däremot inte bara ett tillåtet kategorivärde. Författaren är en självständig företeelse med egna attribut och en egen identitet.

Det är en av anledningarna till att samma sorts relationsteknik kan användas för olika informationsbegrepp.

### Vår uppdelade modell

Den modell vi nu använder kan beskrivas så här:

```text
products
    id
    title
    price
    stock
    product_type_id  → product_types.id

product_types
    id
    name

authors
    id
    name
    email

product_authors
    product_id       → products.id
    author_id        → authors.id
```

En produkt har en produkttyp, och en produkttyp kan beskriva flera produkter.

En produkt kan ha flera författare, och en författare kan vara kopplad till flera produkter.

Vi kan sedan använda `JOIN` för att visa informationen tillsammans:

```sql
SELECT
    p.title,
    a.name AS author_name
FROM products AS p
INNER JOIN product_authors AS pa
    ON pa.product_id = p.id
INNER JOIN authors AS a
    ON a.id = pa.author_id;
```

Att informationen är uppdelad betyder alltså inte att vi förlorat möjligheten att använda den som en helhet.

### Normalformerna – från enkla regler till tydligare struktur

Vi kan beskriva de första tre normalformerna med tre korta frågor:

| Normalform | Fråga |
|---|---|
| **1NF** | Innehåller varje cell ett enskilt värde, eller har vi grupperat flera värden i samma kolumn? |
| **2NF** | Hör alla icke-nyckelattribut till **hela** nyckeln, eller beskriver något bara en del av den? |
| **3NF** | Beror ett attribut direkt på nyckeln, eller beskriver det egentligen något som bestäms av ett annat attribut? |

Vi börjar med denna praktiska förståelse och undersöker sedan hur kraven kan beskrivas mer exakt.

### Första normalformen: en uppgift per värde

Anta att vi registrerar författare så här:

| product_id | title | authors |
|---|---|---|
| 1 | Vägen hem | Anna Svensson, Erik Lund |

Kolumnen `authors` innehåller här en kommaseparerad lista av författare.

Det verkar praktiskt, men det blir svårt att identifiera varje författare och kontrollera relationerna mellan produkter och författare.

Vi vill i stället representera författarna var för sig och lagra varje koppling som en egen rad i `product_authors`.

Det här illustrerar **första normalformen (1NF)**: varje cell ska innehålla ett **atomärt värde** – inte en lista av flera författare som vi förväntas behandla var för sig.

Vad som räknas som atomärt avgörs av datamodellen och vilka operationer vi behöver kunna utföra. En textsträng eller ett datum kan exempelvis vara ett enda värde även om det går att dela upp i tecken eller datumdelar.

### Andra normalformen: beroende på hela nyckeln

Tänk att vi skapar följande tabell:

| product_id | author_id | product_title | author_name |
|---|---|---|---|
| 1 | 1 | Vägen hem | Anna Svensson |
| 1 | 2 | Vägen hem | Erik Lund |

Vi antar att kombinationen `(product_id, author_id)` identifierar varje rad.

Men `product_title` beror bara på `product_id`. Och `author_name` beror bara på `author_id`.

Informationen hör alltså inte till *hela kombinationen*. Den hör till varsin företeelse.

Genom att flytta titel till `products` och namn till `authors` och behålla `product_authors` som en ren koppling kan vi undvika dessa **partiella beroenden**.

Det är grundidén bakom **andra normalformen (2NF)**: ett icke-nyckelattribut ska beskriva något som hör till **hela** nyckeln.

Som praktisk tumregel kan vi fråga oss om tabellen verkligen beskriver en och samma företeelse eller relation. Men 2NF handlar mer specifikt om **partiella beroenden av sammansatta kandidatnycklar**. En tabell kan uppfylla 2NF och ändå innehålla information om andra företeelser som gör att den bryter mot 3NF.

### Tredje normalformen: beroenden via andra attribut

Anta att vi har:

| product_id | title | product_type_id | product_type_name |
|---|---|---|---|
| 1 | Vägen hem | 1 | Roman |
| 3 | Vinterljus | 1 | Roman |
| 4 | Små historier | 2 | Novellsamling |

Vi har `product_id` som primärnyckel.

Produkttypens namn bestäms av `product_type_id`. Det finns alltså ett beroende från produktens identifierare till typ-id, och vidare från typ-id till typnamnet.

Vi kan undvika upprepningen genom att lägga `product_type_name` i `product_types` och bara lagra `product_type_id` i `products`.

Det är grundtanken bakom **tredje normalformen (3NF)**: en uppgift ska inte vara indirekt beroende av nyckeln via ett annat icke-nyckelattribut.

Produktens typ-id beskriver vilken typ produkten tillhör. Typens namn beskriver däremot själva produkttypen, inte produkten. Vi lagrar därför namnet i `product_types`.

Detta är en användbar förenkling. Den mer exakta definitionen, som också tar hänsyn till kandidatnycklar, följer under *Avancerat*.

## Avancerat

### Funktionella beroenden

För att förstå normalisering mer noggrant behöver vi begreppet **funktionellt beroende**.

Vi skriver:

```text
product_id → title, price, stock
```

Det betyder att ett bestämt `product_id` avgör vilka värden `title`, `price` och `stock` har i vår modell.

Vi kan också skriva:

```text
author_id → name, email
```

Det betyder inte att en författare aldrig kan byta namn eller e-postadress. Det betyder att varje identifierad författare vid en given tidpunkt har ett bestämt värde för de attribut som vi modellerar.

Ett funktionellt beroende handlar alltså om de regler vi förutsätter för vår information, inte bara om vilka råkar vara de aktuella värdena i databasen.

### Kandidatnycklar och en mer precis syn på normalformerna

En **kandidatnyckel** är en minimal uppsättning attribut som kan identifiera en rad unikt.

En tabell kan ha flera kandidatnycklar. Den vi väljer som primärnyckel är bara en av dem.

I mer formell terminologi handlar 2NF om att varje attribut som inte ingår i någon kandidatnyckel är fullt funktionellt beroende av varje kandidatnyckel.

3NF kräver dessutom att för varje icke-trivialt funktionellt beroende `X → A` gäller att `X` är en supernyckel eller att `A` är ett *primattribut*, alltså ingår i någon kandidatnyckel.

Det innebär att den vanliga minnesregeln om ”beroende av nyckeln och inget annat än nyckeln” är användbar, men inte en fullständig definition.

### Boyce–Codd och högre normalformer

**Boyce–Codd-normalformen (BCNF)** skärper kravet på funktionella beroenden: varje determinant i ett icke-trivialt funktionellt beroende ska vara en supernyckel.

**Fjärde normalformen (4NF)** tar upp situationer där flera *oberoende flervärdesfakta* lagras tillsammans. Anta exempelvis att en produkt kan ha flera författare och samtidigt finnas i flera språkversioner, och att relationerna är oberoende av varandra. Om vi lagrar alla kombinationer av författare och språk i en enda tabell kan vi skapa onödig upprepning. Då kan separata relationer vara bättre.

**Femte normalformen (5NF)** handlar om relationer där **tre eller fler samband tillsammans** avgör vilka kombinationer som är giltiga.

Föreställ dig att bokhandeln har flera butiker och leverantörer. Vi vill beskriva vilka leverantörer som kan leverera vilka produkter till vilka butiker. Vi börjar med en tabell:

| supplier_id | product_id | store_id |
|---|---|---|
| 1 | 10 | 1 |
| 1 | 10 | 2 |
| 1 | 20 | 1 |

Varje rad beskriver en kombination av *leverantör, produkt och butik*.

Anta nu att verksamheten har en bestämd regel: **Om en leverantör kan leverera en produkt, leverantören samarbetar med en butik och butiken tar emot produkten, då gäller också kombinationen av alla tre.**

Då beskriver vår tabell egentligen tre slags samband:

- Vilka **produkter** varje **leverantör** kan leverera.
- Vilka **butiker** varje **leverantör** samarbetar med.
- Vilka **produkter** varje **butik** tar emot.

Vi skulle kunna lagra dessa samband i tre separata tabeller. En `JOIN` mellan samtliga tre kan då återskapa exakt de giltiga kombinationerna av leverantör, produkt och butik. Om vi behåller allt i samma tabell upprepar vi i stället samband som redan bestäms av de andra.

Det kallas ett **joinberoende**: en relation kan återskapas fullständigt genom att kombinera flera mindre relationer, utan att vi förlorar information eller skapar ogiltiga kombinationer.

Det avgörande är **verksamhetsregeln**. Om bokhandeln i stället avtalar varje enskild kombination av leverantör, produkt och butik separat, kan vi inte härleda alla kombinationer från de tre parvisa sambanden. Då skulle uppdelningen kunna skapa leveranser som aldrig avtalats.

5NF hjälper oss alltså att upptäcka när en komplex relation i själva verket kan beskrivas av flera mindre, oberoende relationer – **men bara när vi vet att uppdelningen är giltig för alla tillåtna datatillstånd**, inte bara för de exempelrader vi råkar ha just nu.

Det är alltså inte korrekt att 4NF bara betyder ”använd en kopplingstabell” eller att 5NF betyder ”ha flera kopplingar mellan samma entiteter”. Båda handlar om vilka beroenden som faktiskt gäller i informationen.

I de flesta praktiska databasprojekt är en genomtänkt modell som uppfyller 3NF en bra utgångspunkt, även om högre normalformer och medveten denormalisering ibland behöver övervägas.

För en mer utförlig men fortfarande pedagogisk förklaring av normalformerna rekommenderas William Kents *A Simple Guide to Five Normal Forms in Relational Database Theory*.[^kent]

[^kent]: William Kent, *A Simple Guide to Five Normal Forms in Relational Database Theory*, Communications of the ACM 26(2), 1983, s. 120–125. Tillgänglig på https://knowledge.kitchen/content/courses/database-design/normal-forms-simple-guide/.

### Normalisering är inte bara att dela upp tabeller

En modell med fler tabeller är inte automatiskt bättre normaliserad.

Om vi delar upp information utan att förstå beroendena kan vi skapa onödig komplexitet.

Vi kan också få problem om vi delar upp något som i verksamheten faktiskt är ett sammanhängande värde, eller om vi skapar otydliga identiteter och relationer.

Normalisering handlar om att **bevara informationens betydelse och beroenden** när vi organiserar den.

Ett bra mål är att en förändring av ett sakförhållande normalt ska behöva göras på ett enda logiskt ställe.

### När relationen har egna attribut

Föreställ dig att vi vill veta i vilken ordning författarna ska visas på en bok.

Då räcker det inte att bara veta vilka författare som hör till produkten. Vi behöver också beskriva **relationen**.

Vi kan lägga till `author_order` i `product_authors`:

```sql
CREATE TABLE product_authors (
    product_id INTEGER NOT NULL,
    author_id INTEGER NOT NULL,
    author_order INTEGER NOT NULL,
    PRIMARY KEY (product_id, author_id),
    FOREIGN KEY (product_id)
        REFERENCES products(id),
    FOREIGN KEY (author_id)
        REFERENCES authors(id),
    CHECK (author_order > 0),
    UNIQUE (product_id, author_order)
);
```

`author_order` beskriver inte författaren som person och inte heller produkten ensam. Det beskriver författarens plats **i förhållande till en viss produkt**.

Det är ett exempel på att även en relation kan ha egna meningsfulla attribut.

### Normalisering och historisk information

Anta att vi kopplar en orderrad direkt till produktens aktuella pris.

Om priset ändras i `products` skulle en senare fråga kunna ge intryck av att kunden betalade det nya priset vid den tidigare beställningen.

Därför kan vi behöva lagra **priset vid köptillfället** på orderraden, även om produktens aktuella pris redan finns i en annan tabell.

Det är inte nödvändigtvis onödig dubbellagring. Det är två olika sakförhållanden:

- Aktuellt pris på en produkt.
- Avtalat pris på en orderrad vid en viss tidpunkt.

Att lagra båda kan därför vara helt förenligt med en genomtänkt datamodell.

Normalisering betyder inte att alla värden som ser likadana ut måste lagras på exakt ett ställe. Vi behöver först förstå **vad de olika värdena betyder**.

### Normalisering och praktisk prestanda

Det kan finnas skäl att skapa särskilda, beräknade eller duplicerade representationer för rapportering och prestanda.

Det brukar kallas **denormalisering** när vi medvetet inför redundans eller förenklar en struktur för att stödja ett visst användningssätt.

Men först behöver vi veta vilken grundmodell och vilka beroenden vi utgår från. Annars är det svårt att avgöra vilka avvikelser vi gör och vilka problem de kan skapa.

I senare kapitel kommer vi att använda Views och andra tekniker för att erbjuda enklare representationer utan att alltid behöva förändra lagringsmodellen.

## Reflektion

1. Hur kan vi avgöra om en uppgift beskriver produkten själv, författaren eller relationen mellan dem?
2. När är upprepade värden ett problem, och när kan två lika värden representera olika sakförhållanden?
3. Varför bör vi förstå informationens beroenden innan vi bestämmer hur många tabeller modellen ska innehålla?

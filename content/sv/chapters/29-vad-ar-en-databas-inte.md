# 29. Vad är en databas inte?

Vi började den här boken med en enkel uppgift: att hålla reda på information.

En kund har ett namn. En bok har en titel. En beställning hör till en kund och innehåller produkter. Genom att bestämma vad dessa uppgifter betyder och hur de hör ihop har vi byggt en databas som kan besvara allt mer avancerade frågor.

Vi har också sett hur en databas kan hjälpa oss att upprätthålla regler, bevara historik och hantera förändringar.

Men ju mer vi lär oss att göra med SQL, desto viktigare blir en annan fråga:

**Vad kan en databas inte göra åt oss?**

## Grund

### Databasen är inte verkligheten

Vi kan börja med en rad ur bokhandelns produkttabell:

| id | title | price | stock |
|---|---|---:|---:|
| 1 | Vägen hem | 200.00 | 12 |

Raden säger att produkten med id `1` heter `Vägen hem`, kostar 200 kronor och har ett lagersaldo på 12 exemplar.

Men den **är inte boken**. Den är en representation av något i bokhandelns verksamhet.

Om en anställd hittar ytterligare fem exemplar på lagret förändras inte databasen automatiskt. Någon eller något behöver registrera förändringen.

Och om databasen säger att det finns 12 exemplar trots att det bara finns 11 på hyllan är det verkligheten och databasen som inte längre stämmer överens.

Det här är ingen liten teknisk detalj. Det är en grundläggande skillnad mellan **ett sakförhållande** och **vår beskrivning av det**.

### En datatyp bestämmer inte betydelsen

Vi kan lagra priset som `DECIMAL(10, 2)` och lagersaldot som `INTEGER`.

Det hjälper oss att bestämma vilka slags värden kolumnerna kan innehålla.

Men det talar inte om för oss vad **pris** egentligen betyder.

Är det priset inklusive moms? Gäller det i butik eller på webbplatsen? Är det ordinarie pris eller kampanjpris?

På samma sätt kan `stock = 12` betyda tolv fysiska exemplar på lagret – men kanske inte tolv exemplar som är tillgängliga för nya beställningar. Några kan redan vara reserverade.

Datatyper beskriver hur värden kan representeras och behandlas. **Betydelsen behöver vi definiera utifrån sammanhanget.**

### En Query kan ge rätt svar på fel fråga

Vi har lärt oss att skriva Queries som räknar, filtrerar och sammanfattar.

Anta att bokhandeln vill veta sin omsättning.

Vi kan skriva:

```sql
SELECT
    SUM(quantity * unit_price) AS total_amount
FROM order_items;
```

SQL kan beräkna summan utan problem.

Men vad har vi egentligen räknat?

Vi har summerat orderradernas registrerade värden. Vi har inte undersökt om beställningarna betalats, avbrutits eller returnerats. Vi har inte heller bestämt hur rabatter och moms ska hanteras.

Beräkningen kan vara **tekniskt korrekt** och ändå besvara en annan fråga än den verksamheten avsåg.

Databasen kan utföra den beräkning vi beskriver. Den kan inte själv avgöra vilken definition av omsättning vi borde använda.

### Databasen är inte applikationen

Vi har använt databasen för att registrera beställningar och minska lagersaldon.

Men ett köp är mer än dessa förändringar.

Kunden ska kunna välja varor, förstå priset, genomföra betalning och få besked om vad som händer. Bokhandeln kan behöva kontakta leverantörer, organisera leverans och hantera returer.

Delar av detta innebär att läsa eller förändra data. Andra delar handlar om **arbetsflöden, beslut och kommunikation med människor eller andra system**.

En databas kan stödja sådana processer. Det betyder inte att alla processer bör byggas in i databasen.

Det är ofta bättre att låta databasen ansvara för informationens struktur och integritet, medan applikationen organiserar hur verksamhetens handlingar genomförs.

Gränsen är inte absolut. Vi har redan sett att en verksamhetsregel ibland behöver uttryckas i både applikationen och databasen.

### Databasen är inte en garanti för sanningen

Vi kan skydda en kolumn med `NOT NULL`, `UNIQUE` och `CHECK`.

Det ger viktiga garantier, men bara för de regler vi faktiskt har formulerat.

Vi kan exempelvis förhindra ett negativt lagersaldo:

```sql
CHECK (stock >= 0)
```

Ändå kan databasen innehålla ett felaktigt positivt värde.

En databas kan kontrollera att data följer en modell. Den kan inte på egen hand kontrollera att **modellen och uppgifterna motsvarar verkligheten**.

Därför behöver vi också människor, källor, rutiner och kvalitetsarbete.

## Avancerat

### Modellen väljer vad vi ser

I en databasmodell behöver vi bestämma vilka företeelser som ska ha egna tabeller, vilka egenskaper de har och vilka relationer som är viktiga.

Det innebär också att vi väljer bort något.

Bokhandelns modell beskriver kunder, produkter, författare och beställningar. Den säger däremot mycket lite om varför en kund väljer en viss bok, vad läsaren upplever eller hur en anställd bedömer en bok som litteratur.

Det är inte nödvändigtvis en brist. Modellen är byggd för vissa ändamål.

Men vi bör komma ihåg att **det som inte finns i modellen inte automatiskt är oviktigt**.

En databas är alltid en avgränsad beskrivning av verkligheten.

### Verksamhetsregler är inte alltid databasregler

Vi kan uttrycka många regler med nycklar och begränsningar:

```sql
CHECK (quantity > 0)
```

Det säger att en orderrad ska innehålla ett positivt antal.

Men tänk att bokhandeln har regeln att en kund får reservera högst tre exemplar av en efterfrågad bok under en kampanj.

Gäller begränsningen per beställning, per kund, per dygn eller för hela kampanjperioden? Räknas tidigare annullerade beställningar?

Innan vi kan implementera regeln måste vi förstå vad den betyder.

Vissa regler kan uttryckas direkt i databasens struktur. Andra behöver kontroller över flera händelser eller sammanhang och måste hanteras i transaktioner, applikationslogik eller särskilda processer.

Databasen kan hjälpa oss att upprätthålla ett beslut. Den kan inte fatta alla **begreppsliga beslut** åt oss.

### Historik är inte samma sak som en ändrad rad

Vi har sett att en produkt kan få ett nytt pris:

```sql
UPDATE products
SET price = 225.00
WHERE id = 1;
```

Nu beskriver `products.price` det aktuella priset.

Men instruktionen säger inte varför priset förändrades, vem som fattade beslutet eller vilket pris som gällde vid en tidigare tidpunkt.

För att besvara sådana frågor behöver vi **modellera historiken**: exempelvis orderradens pris vid köptillfället, tidsperioder för en prislista eller en logg över förändringar.

Historik uppstår alltså inte automatiskt bara för att vi använder ett databassystem som kan spara och förändra data.

Vi behöver bestämma **vilka förändringar som är meningsfulla att bevara**.

### En View är ett perspektiv, inte en ny verklighet

Vi lärde oss att Views kan ge namn åt återanvändbara Queries och fungera som logiska modeller.

En View kan visa produkter tillsammans med produkttyper, eller sammanfatta lagervärden.

Men den kan inte göra sin information sannare bara genom att presentera den tydligare.

Två Views kan utgå från samma tabeller och ändå ge olika resultat därför att de använder olika urval, grupperingar eller definitioner.

Det betyder inte att en av dem måste vara fel. De kanske beskriver olika perspektiv.

Vi behöver kunna fråga oss **vilka antaganden som ligger bakom varje representation**.

### Det går inte att fråga fram information som saknas

En Query kan vara hur välskriven som helst, men den kan inte återställa ett sakförhållande som aldrig registrerades och inte kan härledas från annan information.

Om vi bara sparar produktens nuvarande pris kan vi inte i efterhand säkert avgöra vad det kostade förra året.

Om vi bara sparar ett kundnamn utan en tillförlitlig identifierare kan vi inte alltid avgöra om två poster beskriver samma person.

Och om vi bara sparar försäljning per månad kan vi inte återskapa varje enskild orderrad.

Det är därför datamodellering påverkar **vilka frågor som över huvud taget går att besvara senare**.

### Lagring är inte förståelse

En dataplattform kan samla information från bokhandelns webbplats, kassasystem, lager och leverantörer.

Men när data förs samman behöver vi fortfarande förstå vad de olika systemen menar.

Två system kan använda samma ord för olika saker. Eller olika ord för samma företeelse.

Det är möjligt att skriva SQL som tekniskt förenar deras uppgifter, utan att de därför har blivit **begreppsligt jämförbara**.

En större mängd data ger inte automatiskt bättre förståelse.

Vi behöver gemensamma definitioner, kända källor och en medvetenhet om vilka skillnader vi förenklar när information sammanställs.

### Är en databas en källa till kunskap?

Vi kan använda databasen för att ta reda på vilka produkter som har sålts, vilka kunder som finns registrerade och hur lagersaldot förändrats.

Sådana svar kan vara viktiga underlag för kunskap.

Men skillnaden mellan **data**, **information** och **kunskap** är inte bara en fråga om tekniska nivåer.

För att förstå ett resultat behöver vi ofta veta hur uppgifterna samlades in, vilka antaganden som gjordes och vilket sammanhang vi tolkar dem i.

Bokhandelns databas kan visa att försäljningen av en produkt ökade. Den säger inte automatiskt *varför*.

Vi kanske behöver undersöka en kampanj, en recension, en leveransförsening eller något annat som inte finns i databasen.

**SQL hjälper oss att ställa precisa frågor till lagrad information. Att förstå svarens betydelse är ett större arbete.**

### Vad återstår när vi kan SQL?

Vi har lärt oss att skapa tabeller, formulera Queries, modellera relationer, förändra data, skydda information och analysera den.

Det ger oss många tekniska möjligheter.

Men innan vi börjar skriva SQL behöver vi fortfarande kunna ställa några enklare frågor:

**Vad är det vi vill beskriva?**

**Vad betyder uppgifterna?**

**Vilka samband behöver vi bevara?**

**Vad behöver vara sant för att informationen ska vara användbar?**

**Vilka frågor vill vi kunna besvara – nu och i framtiden?**

Ju bättre vi förstår detta, desto mer meningsfull blir också vår SQL.

Och när ett informationsbehov förändras behöver vi vara beredda att förändra vår modell, våra regler och ibland också vår uppfattning om vad som är viktigt att registrera.

Vi började med att konstatera att människor alltid har behövt hålla reda på saker.

Databaser är ett av våra mest användbara verktyg för det. Men de är fortfarande **verktyg för att beskriva och arbeta med information**.

De ersätter inte verkligheten, våra beslut eller vårt ansvar att förstå den.

## Reflektion

1. Kan en Query ge ett korrekt resultat som ändå leder till ett felaktigt beslut? Vad skulle det bero på?
2. Hur påverkar datamodellen vilka saker vi senare kan förstå – och vilka frågor vi aldrig kommer att kunna besvara?
3. Var går gränsen mellan det ansvar vi kan lägga på databasen och det ansvar människor och verksamheter alltid behöver behålla?

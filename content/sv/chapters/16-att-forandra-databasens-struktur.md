# 16. Att förändra databasens struktur

När vi först skapade bokhandelns databas bestämde vi vilka uppgifter en produkt, kund och författare skulle ha.

Men verksamheten står inte stilla. Vi kanske upptäcker att vi behöver spara ISBN för böcker, skilja mellan produkter som är aktiva och inaktiva eller registrera fler leveransuppgifter.

Då räcker det inte att lägga till eller ändra rader med `INSERT` och `UPDATE`. Vi behöver förändra **själva strukturen** för den information vi kan lagra.

En datamodell är alltså inte något vi konstruerar en gång för alla. Den behöver kunna utvecklas utan att vi förlorar information eller gör befintliga system obrukbara.

## Grund

### Att förändra data eller att förändra strukturen

I förra kapitlet ändrade vi uppgifter med exempelvis:

```sql
UPDATE products
SET price = 225.00
WHERE id = 1;
```

Det förändrar värdet i en befintlig kolumn.

Men om vi vill börja lagra ISBN för våra böcker behöver vi en **ny kolumn**. Då använder vi `ALTER TABLE`.

### Att lägga till en kolumn

Anta att vår tabell `products` innehåller:

| id | title | price | stock |
|---|---|---:|---:|
| 1 | Vägen hem | 200.00 | 12 |
| 2 | Den blå staden | 150.00 | 0 |
| 3 | Vinterljus | 249.00 | 4 |

Vi vill börja registrera ISBN:

```sql
ALTER TABLE products
ADD COLUMN isbn VARCHAR(20);
```

Kolumnen finns nu i tabellen, även för produkter vi redan registrerat.

| id | title | isbn |
|---|---|---|
| 1 | Vägen hem | NULL |
| 2 | Den blå staden | NULL |
| 3 | Vinterljus | NULL |

Vi har inte förlorat de gamla raderna. Men databasen känner ännu inte till deras ISBN.

Det illustrerar skillnaden mellan att **göra plats för en uppgift** och att **faktiskt känna till dess värde**.

### Att fylla i informationen

När vi har kontrollerat vilka ISBN som hör till vilka produkter kan vi lägga till dem med `UPDATE`:

```sql
UPDATE products
SET isbn = '9781234567897'
WHERE id = 1;
```

ISBN är här ett illustrativt värde. Vi använder text eftersom ett ISBN är en identifierare, inte en kvantitet som vi ska räkna med.

När en ny kolumn införs kan vi alltså behöva kombinera två olika slags förändringar:

1. Ändra **strukturen** med `ALTER TABLE`.
2. Ändra **innehållet** med `UPDATE`.

### Att lägga till ett standardvärde

Anta att vi vill markera om produkter ingår i det aktiva sortimentet.

Vi kan lägga till en kolumn med ett förvalt värde:

```sql
ALTER TABLE products
ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;
```

Tanken är att våra befintliga produkter ska betraktas som aktiva tills vi bestämmer något annat.

Vi behöver då fundera över om det är en rimlig regel för **alla redan registrerade produkter**, inte bara för nya produkter.

Olika databassystem kan hantera tillägg av kolumner, standardvärden och befintliga rader på olika sätt, särskilt när tabellerna är stora.[^add-column]

[^add-column]: Syntaxen `ADD COLUMN` stöds brett, men detaljer och möjligheterna att lägga till `NOT NULL`, standardvärden eller vissa begränsningar skiljer sig mellan MySQL, PostgreSQL, SQLite och SQL Server.

### Att ändra en kolumns definition

Ibland behöver vi ändra en datatyp eller tillåta längre värden.

Om `title` från början definierats som `VARCHAR(100)` kanske det inte räcker för alla boktitlar.

I MySQL kan vi exempelvis skriva:

```sql
ALTER TABLE products
MODIFY COLUMN title VARCHAR(200) NOT NULL;
```

Detta förändrar kolumnens definition, inte dess namn eller vilket slags uppgift den beskriver.

Syntaxen varierar mellan olika SQL-dialekter.[^alter-type]

[^alter-type]: PostgreSQL använder exempelvis `ALTER COLUMN ... TYPE`. SQL Server använder `ALTER COLUMN` med en datatypsdefinition, medan SQLite har mer begränsade möjligheter att ändra befintliga kolumner direkt. MySQL-exemplet ovan använder `MODIFY COLUMN`.

### Att ta bort en kolumn

Om vi inte längre behöver ett attribut kan vi ta bort dess kolumn:

```sql
ALTER TABLE products
DROP COLUMN isbn;
```

Men då försvinner också de lagrade ISBN-värdena ur tabellen.

Det är därför en strukturell förändring kan vara mer omfattande än den ser ut. Vi förändrar inte bara vilka frågor vi kan ställa i framtiden; vi kan också ta bort information som redan finns.

Detta är ett **alternativt exempel**, inte något vi bör göra direkt efter att ha infört ISBN.

### Att byta namn på en kolumn

Vi kan också vilja byta namn på en kolumn, exempelvis från `title` till `product_title`:

```sql
ALTER TABLE products
RENAME COLUMN title TO product_title;
```

Många moderna databassystem stöder denna syntax, men äldre versioner och vissa dialekter använder andra konstruktioner.[^rename]

[^rename]: Bland annat PostgreSQL, moderna MySQL-versioner och SQLite stöder `RENAME COLUMN`. SQL Server använder i regel `sp_rename` för att byta namn på en kolumn.

En namnändring kan påverka alla SQL-frågor och program som använder det gamla namnet.

## Avancerat

### Vad är en databasmigration?

En **migration** är en kontrollerad förändring av databasens struktur och ibland även dess data.

Vi kan beskriva förändringen i en SQL-fil:

```sql
-- 001_add_isbn.sql
ALTER TABLE products
ADD COLUMN isbn VARCHAR(20);
```

Nästa ändring kan finnas i en annan fil:

```sql
-- 002_add_is_active.sql
ALTER TABLE products
ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;
```

Filerna dokumenterar hur databasen har utvecklats. Ett migrationsverktyg kan hålla reda på vilka ändringar som redan genomförts.

Migrationsskript bör normalt versionshanteras tillsammans med den kod och dokumentation som är beroende av databasens struktur.

### Utöka, överför, begränsa

Att göra en stor förändring direkt kan vara riskabelt om flera applikationer använder databasen.

En vanlig strategi är att ändra modellen i flera mindre steg:

**1. Utöka.** Lägg till en ny kolumn utan att omedelbart ta bort den gamla.

**2. Överför.** Fyll den nya kolumnen med kontrollerad information och uppdatera programmen så att de använder den.

**3. Begränsa.** När vi vet att den nya strukturen fungerar kan vi införa striktare regler och så småningom ta bort det gamla.

Detta brukar kallas *expand and contract*.

Strategin gör det möjligt att låta äldre och nyare programversioner fungera under en övergångsperiod, om förändringen planeras för det.

### Att lägga till en regel på befintliga data

Anta att vi vill kräva att varje bok har ett ISBN.

Det är inte tillräckligt att direkt lägga till `NOT NULL` om tabellen redan innehåller produkter där ISBN saknas.

Vi kan behöva:

- Först lägga till kolumnen utan kravet.
- Ta reda på vilka värden som saknas och fylla i dem.
- Kontrollera att informationen är tillräckligt korrekt.
- Först därefter göra kolumnen obligatorisk, om den verkligen ska gälla för alla produkter.

Och innan vi gör detta behöver vi kanske fråga oss om **alla produkter är böcker**. Om vår bokhandel senare säljer vykort eller presentartiklar kan ett obligatoriskt ISBN på tabellen `products` vara fel modellering.

En strukturell förändring kan alltså avslöja att vi behöver tänka om kring datamodellen.

### Att ändra en relation

Anta att vi från början bestämt att varje produkt bara kan ha en författare, genom en kolumn `author_id` i `products`.

När vi senare behöver stöd för flera författare blir lösningen inte bara att öka utrymmet i en kolumn.

Vi behöver förändra **relationen** i modellen, exempelvis med kopplingstabellen `product_authors` som vi redan introducerat.

En sådan migration kan innebära att vi först skapar den nya tabellen, för över befintliga relationer, ändrar applikationens frågor och först därefter tar bort den gamla kolumnen.

Här ser vi skillnaden mellan att förändra en kolumns tekniska form och att förändra **hur vi förstår informationens samband**.

### Går det att ångra en migration?

Vissa databasändringar kan ångras med en omvänd SQL-instruktion. Men det betyder inte att förlorad information automatiskt kommer tillbaka.

Om vi tar bort en kolumn som innehåller data kan det krävas en säkerhetskopia eller en separat överföring för att återställa värdena.

Det finns dessutom dialektskillnader i hur schemaändringar fungerar tillsammans med transaktioner. Exempelvis innebär många DDL-operationer i MySQL implicita commits, medan PostgreSQL ofta kan hantera sådana ändringar transaktionellt.[^ddl]

[^ddl]: Exakt stöd för transaktionell DDL varierar mellan databassystem och mellan olika operationer. En rollback-strategi för en migration bör därför testas i den faktiska databasmiljön.

En genomtänkt migrationsplan omfattar därför både hur förändringen ska utföras och hur vi hanterar ett misslyckande.

### Schemaförändringar och verksamhetens tillgänglighet

På en liten övningsdatabas kan vi oftast ändra en tabell direkt.

I ett system med många användare och stora tabeller kan vissa schemaändringar ta tid, kräva låsning eller påverka pågående frågor och uppdateringar.

Därför behöver vi ibland planera förändringar för att undvika driftstopp, eller använda databasens särskilda möjligheter till mindre störande schemaändringar.

Det är ytterligare ett skäl att inte se `ALTER TABLE` som enbart ett sätt att redigera en tabellbeskrivning.

### En View kan skydda ett gränssnitt

Föreställ dig att vi har en applikation som förväntar sig kolumnen `title`, men att vi vill byta namn på den i vår lagringsmodell.

En möjlig strategi är att erbjuda ett fortsatt stabilt gränssnitt med en **View**:

```sql
CREATE VIEW product_overview AS
SELECT
    id,
    product_title AS title,
    price
FROM products;
```

Här antar vi att den underliggande kolumnen redan heter `product_title`.

Program som frågar vyn `product_overview` kan då fortfarande få en kolumn med namnet `title`.

Detta är bara ett exempel på hur en View kan användas för att skilja den **interna lagringsmodellen** från det **gränssnitt andra system använder**. Det kan fortfarande krävas planering av beroenden och rättigheter.

Vi fördjupar oss i Views i nästa kapitel.

### Att förändra en modell är också att förändra ett avtal

När vi lägger till ett attribut utökar vi vad databasen kan säga om verkligheten.

När vi tar bort en kolumn upphör databasen kanske att kunna beskriva ett tidigare sakförhållande.

Och när vi förändrar relationerna mellan tabellerna kan vi förändra vilka kombinationer av information systemet betraktar som giltiga.

En databasstruktur är därför inte bara en teknisk ritning. Den fungerar också som ett **avtal om informationens betydelse**, mellan verksamheten, databasen och de program som använder den.

## Reflektion

1. Vad är skillnaden mellan att lägga till en ny kolumn och att faktiskt känna till värdena som ska stå i den?
2. Varför kan det vara säkrare att först utöka en databasmodell och senare ta bort äldre delar, i stället för att ändra allt på en gång?
3. När vi ändrar en tabell, förändrar vi då bara dess tekniska struktur – eller ibland också vårt sätt att förstå verksamheten?

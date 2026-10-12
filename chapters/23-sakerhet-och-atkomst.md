# 23. Säkerhet och åtkomst

Bokhandelns databas innehåller information som många kan behöva använda, men inte alla behöver kunna göra samma saker med den.

Kunder ska kunna se vilka böcker som finns. Personal kan behöva ändra lagersaldon. En administratör kan behöva hantera användarkonton och databasens struktur. Men det betyder inte att alla dessa roller ska få läsa och förändra all information.

En viktig del av databassäkerhet är därför att bestämma **vem som får göra vad, med vilken information och under vilka förutsättningar**.

## Grund

### Att identifiera och tillåta

Vi behöver skilja mellan två frågor:

- **Autentisering:** Vem är det som försöker ansluta?
- **Auktorisation:** Vad får den identifierade aktören göra?

Autentisering kan exempelvis ske med användarnamn och lösenord, certifikat eller en identitetstjänst. Auktorisation handlar om vilka rättigheter den identiteten har.

Vi kan också skilja mellan **databasanvändaren** som en applikation ansluter med och **slutanvändaren** som är inloggad i applikationen.

Om hundra kunder använder bokhandelns webbplats behöver det inte innebära hundra olika databaskonton. Webbapplikationen kan använda en särskild databasidentitet och själv kontrollera vilka kunduppgifter den enskilde kunden får se.

### Användare och rättigheter

I MySQL kan vi skapa ett konto för bokhandelns applikation:

```sql
CREATE USER 'bookstore_app'@'localhost'
IDENTIFIED BY 'ett-starkt-unikt-losenord';
```

Det här är ett syntaxexempel. Ett riktigt lösenord ska hanteras säkert och inte sparas i versionshanterade skript.

I MySQL ingår även anslutningsvärden som `localhost` i hur ett konto identifieras. Andra databassystem organiserar användare och anslutningsbehörigheter annorlunda.[^users]

[^users]: `CREATE USER` och hantering av identiteter varierar mellan databassystem. Exemplet använder MySQL:s kontomodell. I andra miljöer kan roller, externa identitetsleverantörer eller serverövergripande inloggningar användas.

Att ett konto finns betyder inte att det automatiskt har rätt att läsa och förändra bokhandelns tabeller.

### GRANT – att tilldela rättigheter

Vi kan ge kontot rätt att läsa information om produkterna:

```sql
GRANT SELECT
ON bookstore.products
TO 'bookstore_app'@'localhost';
```

`GRANT` tilldelar en viss rättighet till en identitet.

Nu kan kontot läsa `products`, men den här instruktionen ger inte rätt att ändra pris, ta bort produkter eller skapa nya tabeller.

Om ett administrativt system också behöver ändra lagersaldon kan vi ge en annan identitet en mer avgränsad rättighet:

```sql
GRANT SELECT, UPDATE
ON bookstore.products
TO 'bookstore_staff'@'localhost';
```

Det förutsätter att kontot `bookstore_staff` redan finns. Även detta exempel är förenklat: `UPDATE` på hela tabellen ger möjlighet att ändra *alla* kolumner, inte bara lagersaldot.

### Minsta privilegium

Principen om **minsta privilegium** (*least privilege*) innebär att en identitet bara får de rättigheter den faktiskt behöver.

Det är ofta ett bättre utgångsläge att börja med få rättigheter och lägga till dem efter behov än att ge alla full åtkomst.

Om webbapplikationen bara behöver läsa produktkatalogen bör den till exempel inte kunna:

```sql
DROP TABLE products;
```

Även om applikationen aldrig avser att utföra en sådan operation är det värdefullt att databasen kan neka den.

Vi skyddar alltså inte bara mot avsiktliga angrepp, utan också mot programmeringsfel och oavsiktliga handlingar.

### REVOKE – att ta tillbaka rättigheter

Vi kan återkalla en tidigare tilldelad rättighet:

```sql
REVOKE UPDATE
ON bookstore.products
FROM 'bookstore_staff'@'localhost';
```

Efter detta har identiteten inte längre denna direkta `UPDATE`-rättighet på tabellen.

Men det är viktigt att komma ihåg att rättigheter också kan komma från andra tilldelningar, exempelvis roller eller rättigheter på en överordnad nivå. `REVOKE` av en enda tilldelning betyder därför inte alltid att alla möjligheter till samma operation försvinner.

### Roller

I stället för att hantera varje kontos rättigheter separat kan vi i många databassystem använda **roller**.

I MySQL 8 kan vi exempelvis skapa en roll för dem som behöver läsa bokhandelns produkter:

```sql
CREATE ROLE 'catalog_reader';

GRANT SELECT
ON bookstore.products
TO 'catalog_reader';

GRANT 'catalog_reader'
TO 'bookstore_app'@'localhost';
```

Detta förutsätter att applikationskontot redan finns. För att rollens rättigheter ska vara aktiva måste även rollaktiveringen hanteras enligt databasens regler, till exempel genom en standardroll eller genom att aktivera rollen i sessionen.[^roles]

[^roles]: MySQL 8 stöder roller, men tilldelade roller är inte alltid automatiskt aktiva. PostgreSQL och SQL Server har andra rollmodeller och syntaxer för tilldelning och aktivering. Kontrollera alltid de faktiska effektiva rättigheterna.

En roll är alltså ett sätt att samla **vilka handlingar en viss funktion behöver kunna utföra**.

## Avancerat

### Behörighet på flera nivåer

Vi kan tänka oss flera nivåer av åtkomst:

| Nivå | Exempel |
|---|---|
| Databasserver | Får identiteten ansluta till databashanteraren? |
| Databas eller schema | Får identiteten använda en viss del av databasen? |
| Tabell eller View | Får identiteten läsa eller ändra ett visst databasobjekt? |
| Kolumn | Får identiteten läsa eller ändra vissa attribut? |
| Rad eller informationspost | Vilka enskilda poster får en användare se? |

Alla SQL-system hanterar inte dessa nivåer på samma sätt. Särskilt **radbaserad åtkomstkontroll** varierar mellan databassystem.

I en webbapplikation måste vi dessutom avgöra vilka rättigheter den inloggade kunden har, även om många kunder delar samma databasanslutning.

### En View som begränsat informationsgränssnitt

I kapitel 17 såg vi hur en View kan visa en del av informationen från en tabell.

Anta att kundtabellen innehåller både namn, e-postadress och födelsedatum, men att en intern namnlista bara behöver identifierare och namn:

```sql
CREATE VIEW customer_names AS
SELECT id, name
FROM customers;
```

Vi kan ge en särskild roll rätt att läsa just denna View:

```sql
GRANT SELECT
ON bookstore.customer_names
TO 'name_reader';
```

Det förutsätter att rollen redan är skapad.

Om rollen inte också har åtkomst till den underliggande tabellen kan vyn utgöra ett avgränsat gränssnitt. Men säkerheten beror på **hur databassystemet kontrollerar behörigheter när vyn körs** och vilka andra rättigheter som finns.[^views]

[^views]: I MySQL kan vyer exempelvis använda `SQL SECURITY DEFINER` eller `INVOKER`. Det påverkar vilken identitets behörigheter som används för åtkomst till underliggande objekt. Vyer är inte automatiskt en fullständig säkerhetsgräns och kan behöva kompletteras med andra mekanismer.

Vi ska alltså inte anta att en View skyddar information bara för att den visar färre kolumner.

### Radbaserad åtkomst

Anta att varje kund ska få se sina egna beställningar, men inte andras.

En applikation kan formulera:

```sql
SELECT id, ordered_at
FROM orders
WHERE customer_id = @customerId;
```

Parametern `@customerId` är här ett exempel på en parametriserad Query från applikationskod, inte en fristående SQL-variabel som fungerar likadant i alla databassystem.

Det avgörande är **varifrån kund-id kommer**.

Om applikationen låter användaren ange vilket kund-id som helst utan kontroll kan kunden kanske läsa någon annans beställningar.

Applikationen behöver därför härleda identiteten från en betrodd inloggningsprocess och kontrollera rätten till den efterfrågade informationen.

Vissa databassystem har dessutom mekanismer för radbaserade säkerhetsregler, exempelvis PostgreSQL:s *Row-Level Security* och SQL Servers *Row-Level Security*. MySQL saknar en direkt motsvarande generell inbyggd funktion, vilket gör applikationskontroller och väl utformade databasgränssnitt särskilt viktiga i sådana miljöer.[^rls]

[^rls]: Funktioner, begränsningar och säkerhetsmodell för radbaserade behörigheter är databasspecifika. Rätt utformning kräver bland annat förståelse för hur identitet och sessionskontext förs vidare från applikationen.

### SQL-injektion är inte bara en fråga om indata

Vi mötte SQL-injektion i kapitel 22.

Parametriserade Queries gör att en användares text inte kan tolkas som SQL-instruktioner där en parameter används som värde.

Men även en applikation med parametriserade Queries behöver begränsa **vad databasidentiteten har rätt att göra**.

Om ett angrepp ändå ger tillgång till en applikations databasanslutning bör kontot inte ha fler privilegier än nödvändigt.

Det är ett exempel på **försvar på flera nivåer** (*defence in depth*): flera oberoende skydd som minskar konsekvenserna om ett av dem misslyckas.

### Säker information är mer än rättigheter

Även om åtkomstkontrollen fungerar behöver vi tänka på hur informationen hanteras.

Exempelvis:

- **Överföring:** Är anslutningen till databasen krypterad, och kontrollerar klienten serverns identitet?
- **Lagring:** Skyddas databaser, säkerhetskopior och lagringsmedier på ett lämpligt sätt?
- **Hemligheter:** Hur förvaras lösenord, anslutningssträngar och andra åtkomstuppgifter?
- **Loggning:** Vilka händelser behöver kunna spåras, och hur undviker vi att loggarna avslöjar känslig information?
- **Säkerhetskopiering:** Går informationen att återställa efter fel, angrepp eller oavsiktlig radering?

Kryptering, åtkomstkontroll och säkerhetskopiering löser olika problem. Ingen enskild mekanism ersätter de andra.

### Kryptering och hashning – två olika syften

När vi lagrar känslig information behöver vi först avgöra **om originalvärdet någonsin ska kunna läsas igen**.

**Kryptering** omvandlar ett värde till en form som kan återställas med rätt nyckel. Det kan behövas för uppgifter som en behörig verksamhetsprocess senare måste kunna läsa.

**Hashning** beräknar däremot ett värde som inte är avsett att kunna omvandlas tillbaka till originalet. För lösenord använder vi särskilda, avsiktligt resurskrävande **lösenordshashningsalgoritmer** – inte en vanlig snabb hashfunktion.

I MySQL finns exempelvis funktionen `SHA2()`:

~~~sql
SELECT SHA2('ett exempelvärde', 256);
~~~

Det är ett exempel på **vanlig hashning**, bland annat användbar i sammanhang där vi behöver ett kontrollvärde. **Det är inte ett lämpligt sätt att lagra lösenord.** En snabb hashfunktion som SHA-256 gör det möjligt att pröva stora mängder lösenordsgissningar på kort tid.

För lösenord använder vi hellre etablerade bibliotek med exempelvis **Argon2id** eller andra moderna, anpassade lösenordshashningsalgoritmer.[^password-storage]

[^password-storage]: Se [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html). Där beskrivs rekommenderade algoritmer, salt, parametrar och migrering av äldre lösenordshashar. Vanlig SHA-256, även med ett enkelt salt, är inte en ersättning för lösenordshashning.

### Att skapa och verifiera ett lösenordshashvärde

Anta att bokhandelns applikation har konton för personalen.

När en användare skapar ett lösenord behöver programmet:

1. Ta emot lösenordet via en skyddad anslutning.
2. Låta ett lösenordshashningsbibliotek skapa ett hashvärde med ett **unikt salt** och lämpliga kostnadsparametrar.
3. Lagra den resulterande lösenordsrepresentationen i databasen – **inte lösenordet i klartext**.

Vi kan illustrera skillnaden med pseudokod; funktionsnamnen nedan är **inte inbyggda SQL-funktioner**:

~~~text
stored_hash = PasswordHasher.Hash(password)
is_valid = PasswordHasher.Verify(password_attempt, stored_hash)
~~~

Vid inloggning verifierar programmet det angivna lösenordet mot det lagrade värdet. Det behöver inte, och ska inte försöka, dekryptera lösenordet.

Salt är inte detsamma som en hemlig krypteringsnyckel. Ett slumpmässigt, unikt salt hjälper oss bland annat att undvika identiska hashvärden för identiska lösenord och försvårar förberäknade attacker. Etablerade bibliotek brukar själva generera och lagra salt tillsammans med algoritm och kostnadsparametrar i en strukturerad hashrepresentation.

Det är också en skillnad mellan **lösenordshashning** och att använda en hash för exempelvis filintegritet eller jämförelse av innehåll. Vi ska välja metod efter vilket problem vi vill lösa.

### Att kryptera lagrad information

MySQL har också funktioner för symmetrisk kryptering, exempelvis `AES_ENCRYPT()` och `AES_DECRYPT()`. Det visar att kryptering i vissa miljöer kan utföras av databashanteraren.

Men valet av funktion räcker inte för att skapa ett säkert system. Vi behöver bland annat hantera **nycklar, krypteringsläge, initialiseringsvärden, integritetsskydd och åtkomst** på ett genomtänkt sätt. Vi bör inte bygga en egen kryptografisk lösning kring enstaka SQL-funktioner.

I många applikationer är det lämpligt att utföra krypteringen med ett välunderhållet bibliotek **innan värdet skickas till databasen**. Då kan databasen lagra exempelvis krypterad binärdata tillsammans med den metadata som behövs för att senare kunna dekryptera den:

| customer_id | encrypted_note | key_version |
|---|---|---|
| 1 | *(krypterad binärdata)* | 2 |

Exemplet beskriver principen, inte en fullständig säker datamodell. Beroende på algoritm behöver vi också hantera exempelvis *nonce/IV* och autentiseringstagg. Nyckeln ska i möjligaste mån förvaras **separat från den krypterade informationen**, exempelvis i en avsedd nyckelhanteringstjänst.[^crypto-storage]

[^crypto-storage]: Se [OWASP Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html) för vägledning om kryptering i applikations-, databas- och lagringslager samt säker hantering av nycklar och krypteringslägen.

Kryptering av enskilda fält är inte heller samma sak som kryptering av hela databasens lagringsfiler eller säkerhetskopior. De skyddar mot delvis olika hot.

### När algoritmen eller nyckeln behöver bytas

Kryptografiska skydd behöver kunna förändras. En algoritm kan få kända svagheter, en nyckel kan misstänkas vara röjd eller säkerhetskraven kan förändras.

För **reversibelt krypterade data** kan vi, om vi fortfarande har tillgång till nyckeln och originalinformationen behöver bevaras:

1. Identifiera vilken algoritm och nyckelversion som användes.
2. Dekryptera uppgiften med den gamla nyckeln i en kontrollerad miljö.
3. Kryptera om den med den nya algoritmen eller nyckeln.
4. Kontrollera resultatet och avveckla det gamla skyddet när det är säkert att göra det.

Under en övergång kan systemet behöva kunna läsa både gamla och nya format. Därför är **versionsinformation** en viktig del av datamodellen.

I vissa system används *envelope encryption*: själva data krypteras med en datanyckel, som i sin tur skyddas med en separat nyckel. Då kan man ibland **kryptera om datanyckeln** med en ny överordnad nyckel utan att kryptera om alla datavärden. Om själva datanyckeln eller krypteringsalgoritmen måste bytas kan även innehållet behöva krypteras om.[^key-management]

[^key-management]: Se [OWASP Key Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Key_Management_Cheat_Sheet.html). Att byta nyckel kräver även hänsyn till äldre säkerhetskopior, återställningsförmåga och hur gamla nycklar slutligen ska avvecklas.

### När lösenordens skydd behöver ersättas

För lösenordshashar fungerar inte metoden ovan: vi kan inte dekryptera en hash och sedan skapa ett nytt hashvärde av det ursprungliga lösenordet.

En vanlig migreringsmetod är därför att **uppgradera hashvärdet vid en lyckad inloggning**:

1. Läs den lagrade lösenordsrepresentationen och identifiera dess algoritm och parametrar.
2. Verifiera användarens inmatade lösenord enligt den gamla metoden.
3. Skapa en ny lösenordshash med den moderna metoden.
4. Ersätt den gamla representationen.

Men vad gör vi med användare som inte loggar in?

Om det gamla skyddet är för svagt, eller misstänks ha komprometterats, kan vi behöva **ogiltigförklara de gamla autentiseringsuppgifterna** och kräva att berörda användare skapar nya lösenord genom en säker återställningsprocess.

Vi ska också skilja mellan att skapa **en ny hash av samma lösenord** och att faktiskt **byta lösenord**. Om äldre hashvärden redan har stulits kan ett algoritmbyte inte göra de stulna värdena ogjorda; angriparen kan fortfarande försöka knäcka dem. Vid kompromettering kan nya lösenord, återkallade sessioner och andra incidentåtgärder behövas.

Den här typen av förändringar bör planeras redan när autentiseringslösningen byggs. Systemet behöver exempelvis kunna hantera mer än ett lösenordsformat under en övergång utan att behålla osäkra format längre än nödvändigt.

### Informationsvärdet och skyddets livslängd

Det finns en viktig skillnad mellan **informationen vi behöver bevara** och **metoden vi använder för att skydda den**.

En krypterad kunduppgift kan fortfarande ha ett giltigt användningsområde även om krypteringsalgoritmen blivit föråldrad. Då vill vi kanske bevara informationen men byta skydd.

För ett lösenord är syftet inte att bevara den ursprungliga texten. Vi behöver i stället bevara eller återupprätta användarens **möjlighet att legitimera sig på ett säkert sätt**.

Det innebär att ett väl utformat system ibland måste kunna **migrera information**, och ibland måste kunna **kassera gamla autentiseringsuppgifter**.

Båda är exempel på att säkerhet också handlar om hur informationssystem kan förändras över tid.

### Personuppgifter och dataminimering

I bokhandelns kundregister finns namn, e-postadress och kanske födelsedatum.

Men behöver vi verkligen kundens födelsedatum för att sälja en bok?

Frågan handlar inte enbart om vilka data vi *kan* lagra, utan också om **varför vi lagrar dem och hur länge de behövs**.

Dataminimering innebär att vi inte samlar in mer personuppgifter än vad som är nödvändigt för ett berättigat ändamål.

Den principen påverkar datamodelleringen redan innan vi börjar diskutera `GRANT` och `REVOKE`.

Den kan också skapa en viktig spänning: vissa uppgifter behöver bevaras för exempelvis bokföring och historik, medan andra bör kunna rättas eller raderas enligt tillämpliga regler. Sådana beslut kräver både verksamhetskunskap och juridisk bedömning.

### Loggning och spårbarhet

Det kan vara viktigt att i efterhand förstå vem som ändrade ett pris eller tog bort en post.

Men en vanlig `UPDATE` säger inte automatiskt *vem* som begärde ändringen eller *varför*.

För spårbarhet kan vi behöva logga administrativa handlingar, använda särskilda historiktabeller eller stöd för databasgranskning (*auditing*).

Även här behöver vi skilja mellan databasens tekniska identitet och applikationens slutanvändare. Om alla ändringar kommer från `bookstore_app` räcker det inte att bara logga databasens kontonamn för att veta vilken anställd som gjorde ändringen.

En logg ska dessutom skyddas från obehörig ändring och inte innehålla fler personuppgifter än nödvändigt.

### Tillgänglighet är också säkerhet

Informationssäkerhet brukar ofta beskrivas genom tre grundläggande mål:

| Mål | Vad det betyder |
|---|---|
| **Konfidentialitet** | Information ska inte avslöjas för obehöriga. |
| **Integritet** | Information ska vara korrekt och skyddad mot otillåten eller oavsiktlig förändring. |
| **Tillgänglighet** | Behöriga användare ska kunna komma åt information när de behöver den. |

En databas som är perfekt skyddad mot läsning men inte kan användas av verksamheten är inte en fungerande lösning.

Säkerhetsarbetet innebär därför avvägningar mellan skydd, funktion, administration och återställningsförmåga.

### Säkerhetsregler som en del av datamodellen

Vi har tidigare diskuterat datamodellen som ett avtal om vad informationen betyder.

Nu kan vi lägga till en dimension: modellen och dess omgivande behörighetsregler uttrycker också **vem som får veta något och vem som får förändra det**.

En tabell kan innehålla korrekt information och en Query kan vara tekniskt giltig, men det betyder inte att alla ska kunna köra den.

Därför behöver vi skilja mellan tre frågor:

**Är informationen korrekt representerad?**

**Kan databasen besvara vår Query?**

**Har den som frågar rätt att få svaret?**

Alla tre kan vara nödvändiga för att ett informationssystem ska fungera ansvarsfullt.

## Reflektion

1. Varför räcker det inte att kontrollera användarens behörighet i webbgränssnittet om databaskontot samtidigt har full åtkomst?
2. Vad är skillnaden mellan att begränsa information med en View och att faktiskt kontrollera vem som får läsa den?
3. Hur påverkas vår datamodell av frågan om vilka uppgifter vi bör lagra – inte bara vilka uppgifter vi tekniskt kan lagra?

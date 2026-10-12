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

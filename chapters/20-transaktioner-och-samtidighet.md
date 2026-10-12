# 20. Transaktioner och samtidighet

När en kund köper en bok händer flera saker. Vi behöver registrera beställningen, komma ihåg vad kunden köpte och minska lagersaldot.

Men vad händer om vi lyckas registrera beställningen och sedan misslyckas med att minska lagret? Eller om två kunder samtidigt försöker köpa det sista exemplaret?

Var och en av våra SQL-satser kan vara korrekt, men **helheten kan ändå bli fel**.

En **transaktion** hjälper oss att hantera flera förändringar som en sammanhängande händelse. Samtidigt behöver databasen kunna hantera att många användare arbetar med informationen parallellt.

## Grund

### En beställning är mer än en rad

Vi har sedan tidigare tabellen `products`:

| id | title | price | stock |
|---|---|---:|---:|
| 1 | Vägen hem | 200.00 | 12 |
| 2 | Den blå staden | 150.00 | 0 |

Vi utökar nu bokhandelns modell med beställningar:

**orders**

| id | customer_id | ordered_at |
|---|---|---|
| 101 | 2 | 2026-10-12 10:30:00 |

**order_items**

| id | order_id | product_id | quantity | unit_price |
|---|---|---|---:|---:|
| 1001 | 101 | 1 | 2 | 200.00 |

En rad i `orders` beskriver beställningen. En rad i `order_items` beskriver en produkt i den beställningen. Värdet `unit_price` bevarar priset vid köptillfället, även om produktens aktuella pris förändras.

Tabellerna är ett förenklat exempel. Vi förutsätter här att de har skapats med lämpliga nycklar och främmande nycklar.

### Flera SQL-satser, en händelse

Anta att Olof beställer två exemplar av `Vägen hem`.

Det innebär åtminstone tre förändringar:

1. En ny beställning registreras.
2. Två exemplar registreras på beställningen.
3. Produktens lagersaldo minskas med två.

Om vi utför SQL-satserna var för sig kan några av förändringarna lyckas även om en senare förändring misslyckas.

Med en transaktion kan vi i stället bestämma att de ska **antingen genomföras tillsammans eller inte alls**.

### START TRANSACTION och COMMIT

I MySQL kan vi påbörja en transaktion med `START TRANSACTION`:

```sql
START TRANSACTION;

INSERT INTO orders (id, customer_id, ordered_at)
VALUES (102, 2, '2026-10-12 11:00:00');

INSERT INTO order_items (
    id, order_id, product_id, quantity, unit_price
)
VALUES (1002, 102, 1, 2, 200.00);

UPDATE products
SET stock = stock - 2
WHERE id = 1 AND stock >= 2;

COMMIT;
```

`COMMIT` avslutar transaktionen och gör dess förändringar bestående.

Det här exemplet visar syntaxen och tanken, men är **inte ett färdigt säkert orderflöde**. Innan vi gör `COMMIT` måste vi bland annat kontrollera att lageruppdateringen verkligen påverkade exakt en rad. Om den inte gjorde det ska vi avbryta transaktionen, inte spara en order som inte kan levereras.

Vi förutsätter också att identifierarna är lediga och att beställningens data har kontrollerats.

### ROLLBACK – att ångra en transaktion

Anta att vi upptäcker ett fel innan transaktionen har avslutats.

Då kan vi skriva:

```sql
START TRANSACTION;

UPDATE products
SET stock = stock - 2
WHERE id = 1 AND stock >= 2;

-- Vi upptäcker att beställningen inte ska genomföras.

ROLLBACK;
```

`ROLLBACK` återställer de förändringar som utförts i den pågående transaktionen, under förutsättning att operationerna omfattas av transaktionsstödet.

Den tar inte automatiskt tillbaka en redan committad transaktion. Efter `COMMIT` behöver vi i regel en **ny förändring** för att korrigera det som hänt.

Det är därför viktigt att skilja mellan att *ångra en ännu inte avslutad händelse* och att *rätta en redan registrerad händelse*.

### Vad är ACID?

Fyra vanliga egenskaper hos databastransaktioner sammanfattas med **ACID**:

| Egenskap | Betydelse |
|---|---|
| **Atomicity – atomäritet** | En transaktion behandlas som en helhet: alla dess förändringar genomförs eller ingen av dem. |
| **Consistency – konsistens** | En transaktion ska föra databasen från ett giltigt tillstånd till ett annat, enligt de regler som faktiskt finns definierade och upprätthålls. |
| **Isolation – isolering** | Samtidiga transaktioner ska inte kunna störa varandra på sätt som den valda isoleringsnivån förbjuder. |
| **Durability – beständighet** | När en transaktion har bekräftats ska dess ändringar överleva ett systemfel, inom de garantier systemets konfiguration erbjuder. |

Vi har redan mött integritetsregler som `PRIMARY KEY`, `FOREIGN KEY` och `CHECK`. De är exempel på regler som hjälper oss att upprätthålla **konsistens**.

Men ACID garanterar inte automatiskt att alla verksamhetsregler är rätt modellerade. Om vi tillåter en affärsmässigt orimlig förändring genom en tekniskt giltig SQL-sats kan databasen ändå genomföra den.

### När flera arbetar samtidigt

Anta att det bara finns **ett exemplar** kvar av en bok och att två kunder försöker köpa det samtidigt.

Om båda applikationerna först läser `stock = 1` och sedan var för sig beslutar att ett köp är möjligt, finns risk att båda registrerar en beställning.

Ett bättre sätt att reservera ett exemplar kan vara att göra kontrollen och förändringen i samma `UPDATE`:

```sql
UPDATE products
SET stock = stock - 1
WHERE id = 1
  AND stock >= 1;
```

Efteråt måste vi kontrollera att **exakt en rad** uppdaterades. Om ingen rad uppdaterades fanns inte tillräckligt lager vid tillfället för uppdateringen.

En villkorlig `UPDATE` är användbar därför att kontrollen och ändringen av raden sker tillsammans i databasen. Men orderflödet behöver fortfarande en transaktion som kopplar lagerändringen till beställningen.

## Avancerat

### Isolering är inte bara av eller på

En databas kan ha flera pågående transaktioner samtidigt. **Isolering** beskriver vilka effekter en transaktion får observera från andra transaktioner.

SQL beskriver flera isoleringsnivåer:

| Isoleringsnivå | Grundidé |
|---|---|
| **READ UNCOMMITTED** | Tillåter mycket svag isolering, där smutsiga läsningar kan förekomma. |
| **READ COMMITTED** | En läsning ska inte se förändringar från andra transaktioner som ännu inte committats. |
| **REPEATABLE READ** | Ger starkare skydd för upprepade läsningar inom en transaktion. |
| **SERIALIZABLE** | Ska ge ett resultat som motsvarar någon seriell ordning av transaktionerna. |

Det här är en orientering, inte en fullständig specifikation. Samma benämning kan innebära något olika praktiskt beteende i olika SQL-system.[^isolation]

[^isolation]: MySQL med InnoDB använder normalt `REPEATABLE READ` som standard. PostgreSQL använder normalt `READ COMMITTED`. SQL Server har vanligtvis `READ COMMITTED`, men hur läsningar hanteras påverkas bland annat av inställningar för radversionering. SQLite har en annan samtidighetsmodell. Kontrollera alltid den faktiska miljön.

### Tre typer av samtidighetsproblem

**Smutsig läsning (*dirty read*).** En transaktion läser en förändring som en annan transaktion ännu inte har committat. Om den senare gör `ROLLBACK` läste vi information som aldrig blev bestående.

**Icke-upprepbar läsning (*non-repeatable read*).** Vi läser en rad två gånger i samma transaktion, men får olika värden därför att en annan transaktion har ändrat och committat raden mellan läsningarna.

**Fantomläsning (*phantom read*).** Vi upprepar en Query som söker efter rader med ett visst villkor och får en förändrad mängd matchande rader, exempelvis därför att andra transaktioner har lagt till matchande poster.

Det finns dessutom problem som **förlorade uppdateringar (*lost updates*)** och **skrivskew (*write skew*)**. Dessa fångas inte fullständigt av den enkla uppräkningen av de tre klassiska läsanomalierna.

### Förlorade uppdateringar

Anta att två administrativa program samtidigt läser samma lagersaldo: `12`.

Det ena programmet vill lägga till fem exemplar och det andra vill minska lagret med två.

Om programmen räknar var för sig och sedan skriver tillbaka `17` respektive `10` kan den ena förändringen skriva över den andra.

Vi förväntade oss `15` men kan få `17` eller `10`.

Att utföra förändringen i SQL med:

```sql
UPDATE products
SET stock = stock + 5
WHERE id = 1;
```

är därför ofta säkrare än att läsa ett tal, räkna ut ett nytt värde i applikationen och sedan skriva tillbaka det. Databasen kan hantera låsning av uppdateringen.

Men detta löser inte automatiskt alla samtidighetsproblem i ett flerstegsflöde.

### Låsning och radversionering

För att hantera samtidighet kan databashanterare använda bland annat **låsning** och **radversionering**, ofta kallad *MVCC* (*Multi-Version Concurrency Control*).

Med låsning kan en transaktion tillfälligt hindra andra från att göra förändringar som skulle skapa konflikt.

Med radversionering kan läsare i många situationer få en konsekvent bild av tidigare committade versioner, i stället för att vänta på en pågående skrivning.

Det betyder inte att MVCC gör låsning eller konflikter obehövliga. En databas kan kombinera flera tekniker.

### SELECT ... FOR UPDATE

I MySQL och PostgreSQL kan vi låsa utvalda rader för en kommande förändring:

```sql
START TRANSACTION;

SELECT stock
FROM products
WHERE id = 1
FOR UPDATE;

-- Kontrollera saldot och genomför de ändringar som hör ihop.

COMMIT;
```

`FOR UPDATE` används när vi behöver läsa något och sedan fatta beslut om en förändring inom samma transaktion.

Vilka lås som tas och vad andra transaktioner får göra under tiden varierar med databassystem, lagringsmotor, index och isoleringsnivå.[^locking]

[^locking]: `SELECT ... FOR UPDATE` stöds bland annat av MySQL/InnoDB och PostgreSQL. SQL Server har andra låsningsmekanismer och syntax, och SQLite har inte samma `FOR UPDATE`-syntax. Exemplet ska köras mot en databas som faktiskt stöder denna låsning.

För ett enkelt lageravdrag kan vår tidigare **villkorliga `UPDATE`** ofta vara ett bättre och enklare val, eftersom vi då inte behöver separera kontrollen från ändringen.

### Ett säkrare köp – transaktionens logik

Vi kan nu formulera ett mer genomtänkt orderflöde:

1. Starta en transaktion.
2. Försök att minska lagersaldot med `UPDATE ... WHERE stock >= quantity`.
3. Kontrollera att **exakt en rad påverkades**; annars gör `ROLLBACK` och meddela att lagret inte räcker.
4. Registrera orderhuvud och orderrader med rätt pris vid köptillfället.
5. Gör `COMMIT` endast om **alla** nödvändiga operationer lyckades.

Själva kontrollen av antalet påverkade rader och felhanteringen utförs ofta av applikationen eller genom databasspecifika funktioner och lagrade procedurer.

Om flera olika produkter köps samtidigt behöver vi tänka igenom i vilken ordning lagerposter uppdateras och hur vi hanterar konflikter.

### Deadlocks och återförsök

Anta att två transaktioner försöker uppdatera två produkter i motsatt ordning.

Den första låser produkt A och väntar på B. Den andra låser B och väntar på A.

Ingen kan fortsätta. Detta kallas en **deadlock**.

Databashanteraren kan då upptäcka situationen och avbryta en av transaktionerna så att den andra kan fortsätta.

Applikationen behöver kunna hantera felet och ibland **försöka om hela transaktionen**.

Det är viktigt att skilja på att försöka om en enskild SQL-sats och att försöka om hela verksamhetshändelsen. Vid återförsök behöver vi också tänka på om en operation kan ha utförts tidigare, exempelvis om nätverksanslutningen försvann innan applikationen fick svar.

### Transaktioner, DDL och systemgränser

Vi har sett att `COMMIT` och `ROLLBACK` hjälper oss att styra ändringar av data.

Men inte alla operationer omfattas av exakt samma transaktionsgarantier. Vissa schemaändringar, exempelvis `ALTER TABLE`, kan orsaka implicita commits i MySQL. I andra databassystem finns ofta ett bredare stöd för transaktionell DDL.[^ddl]

[^ddl]: I MySQL med InnoDB stöds transaktioner för vanliga DML-operationer, men många DDL-satser gör implicita commits. PostgreSQL stöder transaktionell DDL för många schemaoperationer. Garantier kan också påverkas av motorkonfiguration och operationstyp.

Och en databastransaktion styr normalt inte automatiskt vad som händer **utanför databasen**.

Om ett köp också ska skicka ett mejl, debitera ett betalsystem eller beställa leverans är det inte säkert att dessa externa handlingar kan ångras bara för att databasen gör `ROLLBACK`.

Det leder till nya arkitektoniska frågor om hur vi samordnar händelser mellan olika system.

### Vad betyder det att en händelse är klar?

En SQL-sats kan ha körts utan syntaxfel och ändå ingå i en felaktig verksamhetshändelse.

På samma sätt kan flera korrekta SQL-satser tillsammans skapa inkonsekvent information om vi inte bestämmer **vilka förändringar som måste höra ihop**.

Transaktionen är därför inte bara en teknisk funktion för att undvika fel. Den är också ett sätt att uttrycka **var gränsen går för en sammanhängande handling i verksamheten**.

Vi måste förstå vad som räknas som en färdig beställning innan vi kan bestämma när den ska committas.

## Reflektion

1. Vilka förändringar i bokhandelns orderflöde måste genomföras tillsammans, och vilka kan ske senare?
2. Varför räcker det inte att varje enskild SQL-sats är korrekt för att helheten ska bli tillförlitlig?
3. Hur förändras våra krav på databasmodellen när flera användare kan läsa och förändra samma information samtidigt?

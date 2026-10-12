# 22. SQL i applikationer

Hittills har vi skrivit SQL direkt mot bokhandelns databas. Vi har formulerat Queries, förändrat data och undersökt hur databashanteraren arbetar.

Men kunderna kommer inte att skriva SQL när de handlar i vår bokhandel. De använder kanske en webbplats eller en app. Personalen använder ett administrativt system.

Hur kommer då deras handlingar fram till databasen?

Mellan användaren och databasen finns ett program som behöver **översätta verksamhetens handlingar till SQL**, tolka svaren och hantera de fel som kan uppstå.

## Grund

### Från användarhandling till Query

Anta att en kund söker efter en bok med ordet *vägen* i titeln.

Vi kan beskriva händelsen så här:

1. Kunden anger en söktext.
2. Applikationen tar emot söktexten.
3. Applikationen skickar en parametriserad Query till databasen.
4. Databasen returnerar de matchande raderna.
5. Applikationen presenterar böckerna för kunden.

Det är viktigt att skilja på **användarens avsikt**, **applikationens logik** och **databasens ansvar**.

### En SQL-anslutning

För att använda SQL från ett program behöver vi normalt en **databasdrivrutin**: programkod som förstår hur vårt programs miljö och databashanteraren kommunicerar.

I C# används ofta ADO.NET tillsammans med en drivrutin för den aktuella databasen.

I våra exempel använder vi MySQL och NuGet-paketet `MySqlConnector`.[^driver]

En möjlig anslutning ser ut så här:

```csharp
using MySqlConnector;

var connectionString =
    "Server=localhost;Database=bookstore;User ID=bookstore_app;Password=...;";

await using var connection = new MySqlConnection(connectionString);
await connection.OpenAsync();
```

Nu kan applikationen kommunicera med databasen.

Exemplet visar grundprincipen. I en verklig applikation ska lösenord och andra hemligheter **inte skrivas direkt i källkoden**, utan hämtas från exempelvis säker konfiguration eller miljövariabler.

[^driver]: `MySqlConnector` är en fristående ADO.NET-drivrutin för MySQL, tillgänglig via NuGet. Andra databassystem har andra drivrutiner, exempelvis `Npgsql` för PostgreSQL och `Microsoft.Data.SqlClient` för SQL Server. Metodnamn och beteende kan skilja sig något mellan drivrutiner.

### Att köra en Query

Vi vill hämta bokhandelns tillgängliga produkter:

```sql
SELECT id, title, price
FROM products
WHERE stock > 0
ORDER BY title;
```

Från C# kan vi skicka samma Query till databasen:

```csharp
await using var command = new MySqlCommand("""
    SELECT id, title, price
    FROM products
    WHERE stock > 0
    ORDER BY title;
    """, connection);

await using var reader = await command.ExecuteReaderAsync();

while (await reader.ReadAsync())
{
    int id = reader.GetInt32("id");
    string title = reader.GetString("title");
    decimal price = reader.GetDecimal("price");

    Console.WriteLine($"{id}: {title} – {price} kr");
}
```

En Query som returnerar rader kan behandlas med en **data reader**, som låter applikationen läsa resultatet rad för rad.

Vi har inte behövt förändra SQL-syntaxen för att anropa databasen från ett annat programmeringsspråk. Däremot behöver programmet hantera anslutningen och tolka resultatet.

### Parametrar – värden är inte SQL-kod

Nu vill vi söka efter en produkt med ett bestämt id.

Det kan vara frestande att bygga en Query genom att sätta ihop text:

```csharp
// Osäkert mönster – bygg inte SQL från användarinmatning så här.
string sql = $"SELECT title FROM products WHERE id = {userInput}";
```

Problemet är att ett värde från användaren då riskerar att bli en del av **själva SQL-instruktionen**.

Vi ska i stället använda **parametriserade Queries**:

```csharp
await using var command = new MySqlCommand("""
    SELECT title, price
    FROM products
    WHERE id = @productId;
    """, connection);

command.Parameters.AddWithValue("@productId", productId);

await using var reader = await command.ExecuteReaderAsync();

if (await reader.ReadAsync())
{
    Console.WriteLine(reader.GetString("title"));
}
```

Här antar vi att `productId` redan är ett heltal som applikationen har tagit emot och validerat.

Parametern `@productId` är en **plats för ett värde**. Värdet skickas separat från Queryns struktur, så att användarinmatning inte ska kunna omtolkas som SQL-syntax.

Detta är ett grundläggande skydd mot **SQL-injektion**.

### SQL-injektion

SQL-injektion uppstår när ett program låter opålitlig text påverka konstruktionen av en SQL-sats.

Problemet är inte att databasen missförstår SQL. Problemet är att applikationen har byggt en annan instruktion än den avsåg.

Parametrar hjälper oss att skilja **data från instruktioner**.

Men parametrar kan normalt användas för *värden*, inte för godtyckliga tabellnamn, kolumnnamn eller SQL-nyckelord. Om användaren ska kunna välja sorteringskolumn behöver applikationen till exempel välja mellan en **fördefinierad lista av tillåtna alternativ**, inte lägga in användarens text direkt i `ORDER BY`.

### Att förändra data från ett program

När bokhandeln ändrar ett lagersaldo använder applikationen en annan typ av kommando:

```csharp
await using var command = new MySqlCommand("""
    UPDATE products
    SET stock = stock + @quantity
    WHERE id = @productId;
    """, connection);

command.Parameters.AddWithValue("@quantity", 5);
command.Parameters.AddWithValue("@productId", 1);

int changedRows = await command.ExecuteNonQueryAsync();
```

`ExecuteNonQueryAsync()` används för satser som inte förväntas ge ett vanligt radresultat, exempelvis `UPDATE` och `DELETE`.

Returvärdet ger oss information om påverkade rader, men **vad som räknas som en påverkad rad kan bero på drivrutinens och databasens inställningar**. Vid ett kritiskt lageravdrag behöver vi därför förstå exakt vad returvärdet betyder.

## Avancerat

### Vem ansvarar för vad?

Applikationen och databasen samarbetar, men deras ansvar är inte identiska.

| Del | Exempel på ansvar |
|---|---|
| **Användargränssnitt** | Samla in söktext, visa produkter och felmeddelanden |
| **Applikationslogik** | Tolka önskemål, genomföra arbetsflöden och kontrollera behörighet |
| **Databas** | Lagra information, upprätthålla definierade integritetsregler, besvara Queries och hantera transaktioner |

Gränserna är inte absoluta. En verksamhetsregel kan behöva kontrolleras på flera nivåer: i gränssnittet för tydlig återkoppling, i applikationen för att styra processen och i databasen för att skydda informationens integritet.

En databaskoppling får däremot inte ersätta en genomtänkt behörighetsmodell.

### Transaktioner från applikationen

I kapitel 20 såg vi varför beställning och lageravdrag behöver höra ihop.

Ett program kan starta en transaktion och koppla flera SQL-satser till den.

Följande förenklade exempel visar bara ett lageravdrag med kontroll av resultatet:

```csharp
await using var transaction =
    await connection.BeginTransactionAsync();

try
{
    await using var command = new MySqlCommand("""
        UPDATE products
        SET stock = stock - @quantity
        WHERE id = @productId AND stock >= @quantity;
        """, connection, transaction);

    command.Parameters.AddWithValue("@quantity", 2);
    command.Parameters.AddWithValue("@productId", 1);

    int changedRows = await command.ExecuteNonQueryAsync();

    if (changedRows != 1)
    {
        throw new InvalidOperationException("Otillräckligt lagersaldo.");
    }

    // Här skulle fler förändringar som hör till köpet utföras
    // inom samma transaktion.

    await transaction.CommitAsync();
}
catch
{
    await transaction.RollbackAsync();
    throw;
}
```

Detta är fortfarande **inte en komplett beställningsprocess**. I ett verkligt köp behöver vi dessutom registrera beställningen, säkerställa rätt priser och hantera fel som uppstår under eller efter commit.

Det avgörande är att varje kommando som hör till transaktionen använder **samma anslutning och samma transaktion**.

Vid allvarliga anslutningsfel kan en rollback i sig misslyckas. Applikationen behöver också kunna hantera osäkerhet om huruvida en commit hann genomföras.

### Att översätta rader till objekt

I ett objektorienterat program vill vi kanske inte arbeta direkt med kolumnnamn överallt.

Vi kan ha en klass:

```csharp
public sealed class Product
{
    public int Id { get; init; }
    public string Title { get; init; } = "";
    public decimal Price { get; init; }
}
```

Och skapa objekt utifrån databasens resultat:

```csharp
var product = new Product
{
    Id = reader.GetInt32("id"),
    Title = reader.GetString("title"),
    Price = reader.GetDecimal("price")
};
```

Det här brukar kallas **mappning** mellan relationsdata och applikationens objekt.

Men det betyder inte att en tabell alltid motsvarar exakt en klass, eller att varje JOIN ska skapa ett nytt objekt av samma typ.

Tabeller är modeller för lagring och relationer. Objekt är modeller för hur ett program organiserar sin logik. De kan likna varandra, men behöver inte ha identisk struktur.

### ORM – ett annat sätt att arbeta

Ett **Object-Relational Mapper (ORM)** kan hjälpa programmet att läsa och förändra databasens information via objekt och uttryck i programmeringsspråket.

I .NET-världen är **Entity Framework Core** ett vanligt exempel.

Med ett ORM kan applikationen i många fall formulera frågor med exempelvis LINQ, och verktyget översätter dem till SQL.

Men SQL har inte försvunnit. Databasen behöver fortfarande exekvera en Query, och vi behöver fortfarande förstå relationer, index, transaktioner och vilka SQL-satser som faktiskt genereras.

För vissa situationer är direkt SQL tydligare. För andra kan ett ORM minska mängden upprepande kod.

### Att undvika för många databasfrågor

Anta att applikationen först hämtar hundra produkter och sedan gör en separat Query för att hämta produkttypen för **varje produkt**.

Då kan vi få hundra extra Queries för information som kanske hade kunnat hämtas med en JOIN.

Det kallas ofta **N+1-problemet**: en Query för listan och ytterligare en per rad.

Problemet kan uppstå både med handskriven SQL och med ORM-verktyg, exempelvis genom hur relaterade objekt laddas.

Vi behöver därför tänka på **hur många gånger programmet kommunicerar med databasen**, inte bara hur en enskild Query ser ut.

### Anslutningar och connection pooling

Att öppna en fysisk databasanslutning kan innebära nätverksarbete och autentisering.

Därför använder många drivrutiner **connection pooling**: färdiga anslutningar kan återanvändas när ett program behöver dem.

I C# kan vi ändå skriva `await using` och avsluta vår användning av anslutningsobjektet. Med pooling innebär det normalt att anslutningen återlämnas till poolen i stället för att varje gång behöva etableras från början.

Men en anslutningspool är en begränsad resurs. Vi ska inte låta läsare, transaktioner eller anslutningar vara öppna längre än nödvändigt.

### Felhantering och tillförlitlighet

Applikationen behöver skilja mellan olika slags fel:

- **Ogiltiga värden:** exempelvis en prisuppgift som inte får vara negativ.
- **Integritetsfel:** exempelvis en främmande nyckel som hänvisar till en post som saknas.
- **Samtidighetskonflikter:** exempelvis en deadlock eller ett lager som hann ta slut.
- **Anslutningsproblem:** exempelvis tidsgränser eller avbruten nätverkskontakt.

En viktig skillnad är om ett fel ska leda till att vi **rättar indata**, **avbryter arbetet** eller **försöker om en hel transaktion**.

Vi ska också vara försiktiga med vad vi loggar. Databasfel kan innehålla information om tabeller, parametrar eller andra detaljer som inte bör visas för slutanvändaren eller sparas okontrollerat.

### Säkerheten börjar före SQL-satsen

Parametriserade Queries skyddar mot en viktig klass av angrepp, men de ersätter inte andra kontroller.

Applikationen behöver verifiera att den som begär en åtgärd faktiskt har rätt att göra den.

Och databasanslutningen bör använda ett konto som bara har de rättigheter applikationen behöver. Ett vanligt användarflöde ska exempelvis inte ansluta till produktionsdatabasen som administratör.

Vi utvecklar detta i nästa kapitel om säkerhet och åtkomst.

### Vad tillhör databasen – och vad tillhör programmet?

Vi kan lägga mycket logik i applikationen, i databasen eller i en kombination av båda.

Men valet bör bygga på **vilket ansvar logiken har**.

Databasen lämpar sig väl för att skydda sådant som alltid måste vara sant om informationen: nycklar, relationer och viktiga begränsningar.

Applikationen behöver förstå arbetsflödet: vad en kund försöker göra, vilka steg som ska utföras och vilken återkoppling kunden behöver.

Det kan finnas verksamhetsregler som behöver kontrolleras i båda miljöerna av olika skäl.

**Vi ska inte låta databasen bli hela applikationen. Men vi ska heller inte göra databasen till en passiv förvaringsplats utan ansvar för sina data.**

## Reflektion

1. Varför är en parametriserad Query något annat än en SQL-sträng som satts ihop av programmet?
2. Vilka kontroller hör bäst hemma i databasen, och vilka behöver utföras i applikationen?
3. Vad kan gå fel om ett program behandlar varje databasoperation för sig, trots att användaren uppfattar dem som en enda handling?

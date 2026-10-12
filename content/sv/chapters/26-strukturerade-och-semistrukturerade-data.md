# 26. Strukturerade och semistrukturerade data

I bokhandelns databas har vi hittills lagt information i tabeller med bestämda kolumner. En produkt har ett namn, ett pris och ett lagersaldo. En författare har sin egen rad, och relationen mellan produkter och författare representeras i en särskild kopplingstabell.

Men tänk att böckerna också har olika slags beskrivande egenskaper. En roman kanske har ett originalspråk och en serie den tillhör. En fackbok kan ha ett ämnesområde och en upplagebeteckning.

Ska vi lägga till en ny kolumn för varje tänkbar egenskap? Eller finns det information som passar bättre i en mer flexibel struktur?

Det leder oss till skillnaden mellan **strukturerade** och **semistrukturerade data** – och till hur SQL-system kan arbeta med båda.

## Grund

### När strukturen är given

Tabellen `products` kan beskrivas med en tydlig struktur:

| id | title | price | stock | product_type_id |
|---|---|---:|---:|---:|
| 1 | Vägen hem | 200.00 | 12 | 1 |
| 2 | Den blå staden | 150.00 | 0 | 1 |
| 3 | Vinterljus | 249.00 | 4 | 1 |

Varje rad använder samma kolumner. Databasen känner till deras datatyper och kan upprätthålla regler för vilka värden som tillåts.

Det är **strukturerade data**: informationen följer en uttrycklig modell.

Strukturerade data behöver inte vara enkla. Vi kan representera ganska komplicerade företeelser med flera relaterade tabeller.

### När olika poster har olika egenskaper

Anta att vi vill beskriva mer om varje bok:

```json
{
  "language": "sv",
  "pages": 284,
  "series": "Vägarna"
}
```

En annan bok kan ha andra uppgifter:

```json
{
  "language": "en",
  "edition": 3,
  "subjects": ["databaser", "programmering"]
}
```

Detta är **JSON** (*JavaScript Object Notation*), ett vanligt format för att representera information med namngivna egenskaper och samlingar.

Båda objekten är giltiga JSON, trots att de inte innehåller samma egenskaper.

Det är en del av vad vi menar med **semistrukturerade data**: informationen har en intern struktur, men behöver inte följa ett och samma fasta schema för varje post.

### Vad innehåller ett JSON-värde?

JSON använder några grundläggande typer:

| Form | Exempel |
|---|---|
| Objekt | `{"language": "sv"}` |
| Array | `["databaser", "SQL"]` |
| Text | `"Vägen hem"` |
| Tal | `249.50` |
| Boolean | `true` eller `false` |
| Null | `null` |

Objekt innehåller egenskaper med namn. Arrayer innehåller värden i en bestämd ordning och kan i sin tur innehålla objekt eller andra arrayer.

Det betyder att ett JSON-värde kan beskriva **en sammansatt struktur inuti ett enda värde**.

### Att lagra JSON i en SQL-tabell

Vi kan tänka oss att bokhandeln kompletterar produkterna med en kolumn för ytterligare metadata.

I MySQL kan vi skriva:

```sql
ALTER TABLE products
ADD COLUMN metadata JSON;
```

Och fylla i uppgifter för en produkt:

```sql
UPDATE products
SET metadata = '{
    "language": "sv",
    "pages": 284,
    "series": "Vägarna"
}'
WHERE id = 1;
```

Produkten har fortfarande sitt `id`, `title`, `price` och `stock` som vanliga kolumner.

Men den kan också innehålla ett JSON-värde med fler egenskaper.

MySQL har en särskild JSON-datatyp. Andra databassystem erbjuder andra varianter av stöd för JSON.[^json-types]

[^json-types]: PostgreSQL har bland annat `json` och `jsonb`. SQLite har JSON-funktioner och stöd för JSON-representationer men inte samma särskilda JSON-kolumntyp som MySQL. SQL Server har länge haft JSON-funktioner över textvärden och stöd för en särskild `json`-typ varierar med version och produktvariant.

### Att läsa en egenskap från JSON

I MySQL kan vi använda `JSON_EXTRACT()`:

```sql
SELECT
    title,
    JSON_EXTRACT(metadata, '$.language') AS language
FROM products;
```

Uttrycket `'$.language'` är en **JSON-sökväg** (*JSON path*).

Tecknet `$` representerar hela JSON-värdet och `.language` anger egenskapen vi vill läsa.

Vi kan också använda `JSON_UNQUOTE()` för att få ut textvärdet utan JSON-strängens citattecken:

```sql
SELECT
    title,
    JSON_UNQUOTE(
        JSON_EXTRACT(metadata, '$.language')
    ) AS language
FROM products;
```

På så sätt kan vi använda en del av den semistrukturerade informationen i en vanlig SQL-Query.

### Att filtrera på en JSON-egenskap

Vi kan också välja de produkter vars metadata anger svenska som språk:

```sql
SELECT id, title
FROM products
WHERE JSON_UNQUOTE(
    JSON_EXTRACT(metadata, '$.language')
) = 'sv';
```

Vi har alltså fortfarande en relationell tabell och en vanlig `SELECT`-sats. Det nya är att ett av värdena i raden i sin tur innehåller en struktur som vi kan söka i.

## Avancerat

### JSON är inte en ersättning för alla relationer

Det vore möjligt att lagra en produkts författare så här:

```json
{
  "authors": [
    {"id": 1, "name": "Anna Svensson"},
    {"id": 2, "name": "Erik Lund"}
  ]
}
```

Men vi har redan tabellerna `authors` och `product_authors`.

Varför valde vi dem?

Därför att en författare är en egen företeelse, som kan förekomma i relation till flera produkter. Vi vill kunna identifiera författaren, kontrollera relationerna och ändra information på ett ställe.

Om vi kopierar författarens namn in i varje produkts JSON-värde riskerar vi samma problem med redundans och inkonsekvens som vi diskuterade i normaliseringskapitlet.

**JSON är ett alternativt sätt att representera en struktur, inte en anledning att överge datamodellering.**

### När JSON kan vara lämpligt

JSON kan vara användbart när:

- En uppgift har en tydlig intern struktur, men olika poster kan ha olika egenskaper.
- Informationen kommer från ett externt system och vi behöver bevara dess ursprungliga representation.
- Vi behöver lagra kompletterande metadata som inte används som centrala relationer i vår datamodell.
- En viss sammansatt uppgift naturligt hör ihop och vanligtvis läses som en helhet.

Samtidigt bör vi vara försiktiga om egenskaperna behöver starka databasbegränsningar, frekvent filtrering, uppdatering var för sig eller relationer till andra tabeller.

Ett bra beslut bygger på **hur informationen används och vilka regler den måste följa**.

### Schema finns även när det inte står i tabellens kolumner

Ett JSON-fält kan se flexibelt ut, men applikationen förväntar sig ofta ändå vissa egenskaper och datatyper.

Kanske förutsätter vi att:

```json
{
  "language": "sv",
  "pages": 284
}
```

alltid har en `language` som text och en `pages` som ett positivt heltal.

Då har vi fortfarande ett **schema** – men reglerna kanske finns i applikationskod, i en JSON Schema-definition eller i databasens särskilda funktioner för validering.

Frågan blir därför inte om data har struktur eller saknar struktur, utan **var strukturen beskrivs och kontrolleras**.

MySQL erbjuder exempelvis `JSON_SCHEMA_VALID()` för att pröva JSON mot ett schema, men motsvarande funktioner och möjligheter varierar mellan databassystem och versioner.[^schema-validation]

[^schema-validation]: Funktioner för JSON-validering är databasspecifika. Även om ett JSON-värde är syntaktiskt giltigt säger det inte automatiskt att egenskaperna följer verksamhetens regler.

### Saknade egenskaper, JSON null och SQL NULL

Här behöver vi vara särskilt noggranna.

Det finns en skillnad mellan:

1. Att hela SQL-kolumnen `metadata` innehåller `NULL`.
2. Att JSON-objektet saknar egenskapen `language`.
3. Att JSON-objektet uttryckligen innehåller `"language": null`.

Dessa situationer kan ha olika betydelse för verksamheten.

Databassystemens JSON-funktioner kan dessutom representera och jämföra dem på olika sätt.

Vi bör därför inte automatiskt behandla **saknad egenskap**, **JSON null** och **SQL NULL** som samma sak. Om skillnaden spelar roll måste vi välja rätt funktion och kontrollera resultatet i den databas vi använder.

### Arrayer och upprepade värden

JSON-arrayer är användbara för värden som hör ihop i en samling:

```json
{
  "subjects": ["databaser", "programmering", "SQL"]
}
```

Men vi behöver fundera över vad arrayen representerar.

Om `subjects` bara är beskrivande metadata kanske det fungerar bra.

Om ämnen däremot är ett kontrollerat register med egna identifierare, regler och relationer till många produkter kan en separat tabell för ämnen och en kopplingstabell vara en bättre modell.

Det anknyter till vår diskussion om första normalformen: frågan om **vad som räknas som ett enskilt värde** är beroende av hur informationen ska representeras och användas.

JSON i en kolumn är inte automatiskt ett brott mot normalisering. Men JSON gör det möjligt att gömma sådana problem om vi slutar undersöka vad de inre värdena betyder.

### När JSON ska bli relationella rader

Anta att vi tar emot en produktkatalog från ett externt API.

Varje produkt beskrivs med JSON, men vår operativa bokhandel behöver fortfarande kunna söka, prissätta och sälja produkter enligt sin datamodell.

Då kan vi behöva:

1. Läsa in och bevara inkommande JSON.
2. Kontrollera att värden och egenskaper är giltiga.
3. Identifiera produkter och relationer.
4. Transformera relevanta uppgifter till våra relationella tabeller.
5. Dokumentera vilken källa uppgifterna kom från.

Det är en form av **ETL eller ELT**, som vi mötte i föregående kapitel.

Vi behöver inte välja mellan att *endast* lagra rå JSON och att *endast* lagra normaliserade data. I en dataplattform kan olika representationer fylla olika syften.

### Att uppdatera delar av ett JSON-värde

I MySQL kan vi använda `JSON_SET()` för att ändra en egenskap:

```sql
UPDATE products
SET metadata = JSON_SET(
    metadata,
    '$.pages',
    286
)
WHERE id = 1;
```

Denna Query förutsätter att `metadata` innehåller ett JSON-värde, exempelvis det objekt vi lade in tidigare.

Det kan vara praktiskt när en enskild egenskap behöver ändras.

Men det betyder inte att ändringen nödvändigtvis är billig eller sker utan att större delar av värdet bearbetas. Databassystemet avgör hur JSON lagras och uppdateras internt.

### Index och prestanda för JSON

Om vi ofta filtrerar på `language` kanske vi vill kunna indexera den egenskapen.

Ett vanligt index på en JSON-kolumn fungerar inte alltid som ett index på ett vanligt textattribut.

Beroende på databassystem kan vi exempelvis använda **genererade kolumner**, uttrycksindex eller särskilda index för JSON-data.

I MySQL kan vi illustrera principen med en genererad kolumn:

```sql
ALTER TABLE products
ADD COLUMN language_code VARCHAR(10)
GENERATED ALWAYS AS (
    JSON_UNQUOTE(
        JSON_EXTRACT(metadata, '$.language')
    )
) STORED;
```

Därefter kan vi indexera den genererade kolumnen:

```sql
CREATE INDEX idx_products_language
ON products (language_code);
```

Exemplet är inte en generell rekommendation att kopiera varje JSON-egenskap till en egen kolumn. Tvärtom visar det att **vilka egenskaper vi ofta söker på kan påverka hur vi väljer att modellera och indexera informationen**.

### JSON, XML och andra representationer

JSON är bara ett exempel på semistrukturerade data.

**XML** använder element och attribut och har möjligheter att beskriva strukturer med exempelvis XML Schema.

Andra system använder exempelvis dokumentformat, hierarkiska representationer eller binära format för utbyte och lagring.

Vi behöver därför skilja mellan:

- **Hur informationen representeras**, till exempel som tabellrader eller JSON.
- **Vilka regler informationen följer**, till exempel relationer eller schemaspecifikationer.
- **Hur informationen lagras och görs sökbar**, vilket beror på databassystemets funktioner.

Det är möjligt för en relationsdatabas att lagra dokumentliknande information. Och det är möjligt för en dokumentdatabas att ställa höga krav på struktur.

Gränsen handlar inte bara om en filändelse eller vilken produkt vi valt.

### Flexibilitet kräver fortfarande beslut

En fast tabellstruktur tvingar oss ofta att tidigt bestämma vad en uppgift betyder.

JSON kan låta oss skjuta upp vissa beslut. Det kan vara en styrka när informationen varierar eller förändras snabbt.

Men beslutet försvinner inte.

Förr eller senare behöver vi veta vilka uppgifter som är obligatoriska, vilka värden vi kan lita på, hur vi identifierar samma företeelse över tid och hur olika delar av informationen hänger ihop.

**Semistrukturerade data är inte data utan betydelse. De är data där en del av strukturen uttrycks på ett annat sätt.**

## Reflektion

1. När är det lämpligt att lagra en egenskap i ett JSON-fält, och när bör den få en egen kolumn eller relationell tabell?
2. Vad är skillnaden mellan att ett JSON-värde är syntaktiskt giltigt och att informationen är korrekt för bokhandelns behov?
3. Hur påverkar valet mellan relationella tabeller och semistrukturerade värden möjligheten att kontrollera, söka och förändra informationen?

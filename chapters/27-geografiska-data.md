# 27. Geografiska data

Bokhandeln vet vilka kunder den har och vilka adresser de har registrerat. Men ibland behöver vi kunna besvara frågor som handlar om **var** något finns.

Vilken butik ligger närmast en kund? Hur långt är det mellan två leveransadresser? Vilka kunder bor inom ett visst område?

Hittills har vi främst arbetat med text, tal och datum. Nu ska vi se hur en SQL-databas också kan representera **platser, avstånd och geografiska samband**.

## Grund

### En adress är inte en koordinat

I vår tabell `addresses` har vi exempelvis uppgifter som:

| id | customer_id | street | postal_code | city |
|---|---|---|---|---|
| 1 | 1 | Hemmagatan 1 | 124 56 | Hemmavan |
| 2 | 1 | Storgatan 4 | 154 32 | Storfors |
| 3 | 2 | Parkvägen 2 | 154 32 | Storfors |
| 4 | 3 | NULL | NULL | Malmö |

En adress är i första hand en **beskrivning som kan hjälpa oss att hitta en plats**.

Men stadens namn talar inte om exakt var något ligger. Och samma adress kan ibland avse flera byggnader, entréer eller leveranspunkter.

För att kunna beräkna geografiska avstånd behöver vi ofta en mer uttrycklig representation av platsens position.

### Latitud och longitud

En geografisk position kan anges med två koordinater:

- **Latitud** – läget norr eller söder om ekvatorn.
- **Longitud** – läget öster eller väster om en referensmeridian.

Malmö ligger ungefär vid latitud `55.605` och longitud `13.003`.

Vi skulle kunna lägga till två numeriska kolumner:

```sql
ALTER TABLE addresses
ADD COLUMN latitude DECIMAL(9, 6),
ADD COLUMN longitude DECIMAL(9, 6);
```

Det fungerar för att **lagra koordinatvärden**, men det innebär inte att databasen automatiskt förstår deras geografiska betydelse.

För geografiska beräkningar erbjuder många databassystem särskilda **spatiala datatyper och funktioner**.

### Punkter som en geografisk datatyp

En **punkt** (*Point*) representerar en position i ett koordinatsystem.

I MySQL 8 kan vi exempelvis konstruera en geografisk punkt med `ST_GeomFromText()`:

```sql
SELECT ST_GeomFromText(
    'POINT(13.003 55.605)',
    4326,
    'axis-order=long-lat'
);
```

Här anger vi longituden först och latituden därefter.

Talet `4326` är en **SRID** (*Spatial Reference System Identifier*) som identifierar koordinatreferenssystemet WGS 84, ett vanligt system för geografiska positioner.

Vi anger uttryckligen `axis-order=long-lat` för att undvika en vanlig förväxling kring koordinaternas ordning i MySQL.[^mysql-point]

[^mysql-point]: MySQL 8 använder spatiala referenssystem och har särskilda regler för axelordningen när geometrier skapas från WKT. Alternativet `axis-order=long-lat` gäller bland annat `ST_GeomFromText()`. Syntax och axelhantering skiljer sig mellan databassystem. I PostGIS används ofta `ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)`.

### Geografisk information i en tabell

Anta att bokhandeln får flera fysiska butiker.

Vi kan skapa en enkel tabell:

```sql
CREATE TABLE stores (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location POINT NOT NULL SRID 4326
);
```

Och lägga till en butik i Malmö:

```sql
INSERT INTO stores (id, name, location)
VALUES (
    1,
    'Bokhandeln Malmö',
    ST_GeomFromText(
        'POINT(13.003 55.605)',
        4326,
        'axis-order=long-lat'
    )
);
```

Koordinaterna är ungefärliga och illustrativa. De anger ingen verklig butikslokal.

`POINT` och `SRID` gör platsens representation tydligare än två fristående tal. Samtidigt behöver vi fortfarande veta **vad punkten representerar**: byggnadens mittpunkt, entrén eller exempelvis platsen där varor lämnas av.

### Att beräkna avstånd

MySQL erbjuder `ST_Distance_Sphere()` för att beräkna ett ungefärligt avstånd längs jordytan mellan två geografiska punkter.

Vi kan exempelvis jämföra två illustrativa positioner:

```sql
SELECT ST_Distance_Sphere(
    ST_GeomFromText(
        'POINT(13.003 55.605)',
        4326,
        'axis-order=long-lat'
    ),
    ST_GeomFromText(
        'POINT(12.694 55.571)',
        4326,
        'axis-order=long-lat'
    )
) AS distance_meters;
```

Resultatet anges i meter.

Det är viktigt att förstå att detta är ett **geografiskt avstånd**, inte avståndet längs vägar eller den tid det tar att resa mellan platserna.

Beräkningen utgår från en sfärisk approximation av jorden. För vissa användningsområden behöver vi andra avståndsmodeller eller mer detaljerade kartdata.[^distance]

[^distance]: `ST_Distance_Sphere()` är en MySQL-funktion för sfäriskt avstånd. PostgreSQL med PostGIS har exempelvis `ST_Distance` för olika geometri- och geografityper samt `ST_DistanceSphere`. Funktionernas måttenheter och beräkningsmodeller kan skilja sig åt.

### Att söka efter närliggande platser

Vi vill kanske hitta butiker inom tio kilometer från en viss position.

I MySQL kan vi skriva:

```sql
SELECT
    name,
    ST_Distance_Sphere(
        location,
        ST_GeomFromText(
            'POINT(13.003 55.605)',
            4326,
            'axis-order=long-lat'
        )
    ) AS distance_meters
FROM stores
WHERE ST_Distance_Sphere(
    location,
    ST_GeomFromText(
        'POINT(13.003 55.605)',
        4326,
        'axis-order=long-lat'
    )
) <= 10000
ORDER BY distance_meters;
```

Nu kombinerar vi sådant vi redan kan: `SELECT`, `WHERE` och `ORDER BY` – men med en funktion som förstår något om **platser på jordytan**.

Queryn är pedagogiskt enkel. För en stor datamängd kan vi behöva utforma sökningen så att den också kan använda ett spatialt index.

## Avancerat

### Punkter, linjer och områden

Spatiala data är inte begränsade till punkter.

| Geometrityp | Beskriver exempelvis |
|---|---|
| **POINT** | Butikens position |
| **LINESTRING** | En väg eller rutt |
| **POLYGON** | Ett leveransområde |
| **MULTIPOINT** | En samling positioner |
| **MULTIPOLYGON** | Flera geografiskt åtskilda områden |

Vi kan representera en zon som en polygon i stället för att bara lagra namnet på ett område.

Men då behöver vi också välja hur gränsen ska definieras: administrativt område, postnummerområde eller den yta bokhandeln faktiskt levererar till.

Det är återigen ett **modelleringsbeslut**, inte bara ett val av datatyp.

### Ligger punkten inom området?

Anta att vi har tabellen `delivery_areas` med polygoner som beskriver våra leveransområden.

Vi kan undersöka om en butik ligger inom ett område:

```sql
SELECT s.name, d.name AS delivery_area
FROM stores AS s
INNER JOIN delivery_areas AS d
    ON ST_Contains(d.boundary, s.location);
```

Här förutsätter vi att `delivery_areas.boundary` har en kompatibel spatial datatyp och ett kompatibelt koordinatreferenssystem.

`ST_Contains()` undersöker ett **geometriskt förhållande** snarare än att jämföra text eller identifierare.

En viktig detalj är hur gränser behandlas: `ST_Contains()` räknar normalt inte en punkt som ligger exakt på polygonens gräns som en punkt inuti polygonen. Vid andra verksamhetsregler kan exempelvis `ST_Covers()` vara lämplig där den stöds.[^spatial-relations]

[^spatial-relations]: Spatiala predikat och detaljerna i deras topologiska betydelse följer särskilda geometriska regler. `ST_Covers()` finns exempelvis i PostGIS, men inte som en allmänt portabel ersättning i alla SQL-system. Kontrollera också koordinatreferenssystem och geometriernas giltighet.

### Koordinatreferenssystem och projektioner

Vi har använt WGS 84 med SRID 4326.

Men det finns många koordinatreferenssystem. Vissa beskriver lägen på en ellipsoid med latitud och longitud. Andra använder en **kartprojektion** med plana koordinater, ofta uttryckta i meter.

För geografiska analyser i Sverige används bland annat SWEREF 99-varianter.

Valet av koordinatreferenssystem påverkar vad koordinatvärdena betyder och hur vi kan räkna på dem.

Det går därför inte att anta att två punkter med samma koordinatsiffror representerar samma plats om de använder olika referenssystem.

När vi kombinerar geografiska datamängder behöver vi ofta **transformera koordinaterna** till ett gemensamt system.

Och vi bör skilja på att *ange ett SRID* och att faktiskt *transformera koordinaterna*.

### Spatiala index

När vi i kapitel 21 arbetade med vanliga index såg vi hur databashanteraren kan hitta rader utan att läsa hela tabellen.

Geografiska data har ett liknande behov.

Anta att vi har hundratusentals butiker, utlämningsställen eller leveransadresser.

Om vi beräknar avståndet från en punkt till varje rad kan det bli dyrt.

Ett **spatialt index** hjälper databasen att hitta geografiskt relevanta kandidater.

I MySQL kan vi exempelvis skriva:

```sql
CREATE SPATIAL INDEX idx_stores_location
ON stores (location);
```

Det här förutsätter att kolumnens definition och lagringsmotor uppfyller kraven för spatial indexering. Vår tidigare definition med `NOT NULL SRID 4326` är avsedd för en sådan användning i MySQL 8.

Spatiala index använder andra principer än ett enkelt B-trädsindex på exempelvis `price`. Ofta arbetar de med geometriernas begränsande rektanglar (*bounding boxes*) för att hitta möjliga träffar.

En avståndsberäkning med `ST_Distance_Sphere()` blir dock **inte automatiskt indexerad** för att ett spatialt index finns. Ofta behöver vi först avgränsa ett sökområde med en indexvänlig spatial relation och sedan beräkna det exakta eller approximativa avståndet för kandidaterna.

Precis som tidigare behöver vi använda `EXPLAIN` och undersöka hur databashanteraren faktiskt kör vår Query.

### När en adress blir en punkt

Det är möjligt att omvandla en textadress till geografiska koordinater genom en process som brukar kallas **geokodning** (*geocoding*).

Men geokodning innebär ett tolkningssteg.

En adress kan saknas, vara felstavad, hänvisa till en hel gata eller bara kunna matchas ungefärligt.

Därför bör vi inte utan vidare ersätta den ursprungliga adressinformationen med en punkt.

I vissa system kan vi behöva spara både adress, koordinater och metadata om hur positionen fastställdes.

Det anknyter till vårt kapitel om datakvalitet: **ett tekniskt giltigt koordinatvärde är inte nödvändigtvis en korrekt eller tillräckligt noggrann position**.

### Plats och tid

Geografisk information förändras också över tid.

En butik kan flytta. En leveransadress kan ändras. Ett distributionsområde kan få en ny gräns.

Om vi vill analysera tidigare beställningar behöver vi fundera över om vi ska använda **den plats som gällde när beställningen gjordes** eller **den plats som gäller idag**.

Det påminner om vår tidigare diskussion om priser och historiska dimensioner.

En plats är alltså inte alltid en statisk egenskap. I vissa sammanhang behöver vi modellera ett geografiskt sakförhållande **tillsammans med dess giltighetstid**.

### Integritet och platsinformation

Detaljerad platsinformation kan vara känslig.

En kundadress kan vara nödvändig för att leverera en bok, men det betyder inte att alla som kan läsa produktinformationen också ska kunna läsa kundernas adresser.

Och om ett system lagrar återkommande positioner kan det ibland avslöja mer om en persons vanor än vad en enskild adress gör.

Därför behöver vi tillämpa de principer vi mötte i säkerhetskapitlet: behörighet, dataminimering, lämpligt skydd och tydliga användningsändamål.

### Vad betyder geografisk närhet?

Två positioner kan ligga nära varandra fågelvägen men vara långt ifrån varandra om vi måste följa vägnätet.

Ett område kan innehålla en adress geometriskt, men ändå inte omfattas av bokhandelns leveransvillkor.

Och två adresser i samma stad behöver inte vara mer lika ur leveranssynpunkt än adresser på var sin sida av en kommungräns.

Vi behöver därför skilja mellan **geometriska förhållanden** och **verksamhetens betydelse av dem**.

SQL kan hjälpa oss att beräkna avstånd och avgöra om en punkt ligger inom en polygon. Men den kan inte på egen hand bestämma vad som är ett rimligt leveransavstånd eller vilken plats som faktiskt är enklast att nå.

## Reflektion

1. Vad är skillnaden mellan en textadress, ett koordinatpar och en spatial punkt med ett angivet referenssystem?
2. Varför räcker det inte att skapa ett spatialt index för att garantera att alla geografiska Queries blir snabba?
3. Hur kan två geografiskt korrekta avstånd ge olika svar på frågan om vilken butik som ligger närmast en kund?

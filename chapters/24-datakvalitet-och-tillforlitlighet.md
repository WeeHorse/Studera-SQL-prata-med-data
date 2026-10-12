# 24. Datakvalitet och tillförlitlighet

Bokhandelns databas kan innehålla värden som är tekniskt tillåtna men ändå felaktiga.

En kund kan ha ett giltigt formaterat postnummer som tillhör en annan ort. En produkt kan ha ett pris som råkat bli tio gånger för högt. En beställning kan sakna information vi behöver för att hantera en reklamation, trots att alla tabellernas nycklar och relationer är korrekta.

Vi har tidigare arbetat med datatyper, begränsningar och normalisering. De hjälper oss att skydda informationen. Men **att databasen accepterar ett värde betyder inte att värdet beskriver verkligheten korrekt**.

Därför behöver vi också förstå och undersöka **datakvalitet**.

## Grund

### Vad menar vi med datakvalitet?

Datakvalitet handlar om i vilken utsträckning informationen fungerar för sitt avsedda användningsområde.

Det betyder att kvalitet inte bara kan bedömas utifrån tabellen. Vi behöver veta **vad uppgifterna ska användas till**.

Anta att en kundadress saknar lägenhetsnummer. För en enkel sammanställning av kunder per stad kanske det inte spelar någon roll. För att leverera ett paket kan det vara avgörande.

Vi kan därför behöva skilja mellan två frågor:

- **Följer informationen våra tekniska regler?**
- **Är informationen tillräckligt tillförlitlig för det vi vill göra?**

Båda är viktiga, men de besvarar inte samma sak.

### Några kvalitetsdimensioner

Ett vanligt sätt att resonera om datakvalitet är att beskriva olika **kvalitetsdimensioner**.

| Dimension | Fråga vi behöver ställa |
|---|---|
| **Fullständighet** (*Completeness*) | Finns de uppgifter som behövs? |
| **Korrekthet** (*Accuracy*) | Stämmer uppgifterna med verkligheten eller en tillförlitlig källa? |
| **Konsekvens** (*Consistency*) | Stämmer uppgifter överens mellan olika poster, tabeller och system? |
| **Aktualitet** (*Timeliness*) | Är informationen tillräckligt ny eller uppdaterad för användningen? |
| **Unikhet** (*Uniqueness*) | Beskriver flera poster av misstag samma företeelse? |
| **Giltighet** (*Validity*) | Följer värdena regler för format, typ eller tillåtna värden? |

Det finns flera ramverk och varianter av dessa dimensioner. I boken använder vi dem som **sätt att ställa bättre frågor om informationen**, inte som en enda universell definition av kvalitet.

### Giltighet är inte korrekthet

I tabellen `products` har vi ett pris:

```sql
price DECIMAL(10, 2) NOT NULL
```

Vi kan också ha en begränsning:

```sql
CHECK (price >= 0)
```

Då kan databasen neka negativa priser.

Men om boken `Vägen hem` egentligen ska kosta 200 kronor och någon registrerar 2 000 kronor kommer båda reglerna ändå att vara uppfyllda.

**Priset är tekniskt giltigt men sakligt felaktigt.**

Databasen kan kontrollera vissa regler själv. För att veta vilket pris som faktiskt gäller kan vi behöva jämföra med en prislista, ett beslut eller ett annat tillförlitligt underlag.

### Fullständighet – vad saknas?

Vi kan undersöka om kunder saknar e-postadress:

```sql
SELECT id, name
FROM customers
WHERE email IS NULL;
```

Men det räcker inte alltid att kontrollera `NULL`.

En tom text kan också sakna användbart innehåll:

```sql
SELECT id, name
FROM customers
WHERE email IS NULL
   OR TRIM(email) = '';
```

Det här är ett exempel på en **kvalitetskontroll**: en Query som försöker identifiera poster som inte uppfyller ett visst behov.

Samtidigt är det inte självklart att varje kund måste ha e-postadress. För en kund som handlar över disk kanske informationen inte behövs.

Fullständighet måste därför alltid bedömas **i relation till ett ändamål**.

### Giltighet – att följa en regel

Anta att vi vill hitta produkter med orimliga lagersaldon:

```sql
SELECT id, title, stock
FROM products
WHERE stock < 0;
```

Om modellen har en fungerande `CHECK (stock >= 0)` bör den här Queryn inte hitta några sådana rader.

Men kontrollen kan ändå vara användbar när vi arbetar med äldre data, importerar data från andra system eller undersöker en miljö där samma begränsning inte har funnits hela tiden.

Att en kontroll ger **noll träffar** visar att just den regeln inte brutits i de undersökta raderna. Det bevisar inte att all data är korrekt.

### Unikhet – när två poster beskriver samma sak

Vi har en primärnyckel `id` som garanterar att två kunder inte får samma identifierare.

Men det garanterar inte att samma person inte registrerats två gånger:

| id | name | email |
|---|---|---|
| 1 | Benjamin | benjamin@example.com |
| 6 | Benjamin | benjamin@example.com |

Vi kan leta efter upprepade e-postadresser:

```sql
SELECT
    email,
    COUNT(*) AS occurrences
FROM customers
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1;
```

Detta kan indikera dubbletter. Men det är inte ett säkert bevis för att två rader beskriver samma person. Flera personer kan i vissa verksamheter dela en e-postadress, och en person kan ha flera adresser.

**Vi måste först bestämma vad det innebär att två poster är samma företeelse.**

### Konsekvens – när uppgifter motsäger varandra

Anta att bokhandelns administrativa system och webbplatsen har var sin prislista.

Om samma produkt anges med två olika priser kanske vi har ett kvalitetsproblem.

Men först behöver vi fråga om priserna verkligen ska vara identiska. Det kan finnas kampanjer, olika valutor eller avtalade kundpriser.

Konsekvens betyder därför inte att samma text eller tal alltid måste förekomma överallt, utan att informationen **följer de samband och regler som faktiskt gäller**.

Normalisering och främmande nycklar kan förebygga vissa problem genom att minska onödig dubbellagring. Men de kan inte ensamma avgöra om två verksamhetssystem ger samma bild av verkligheten.

## Avancerat

### Att mäta datakvalitet med SQL

Det kan vara användbart att uttrycka en kvalitetskontroll som ett mått.

Anta att vi vill mäta hur stor andel av kunderna som har en registrerad, icke-tom e-postadress:

```sql
SELECT
    COUNT(*) AS total_customers,
    SUM(
        CASE
            WHEN email IS NOT NULL
             AND TRIM(email) <> ''
            THEN 1
            ELSE 0
        END
    ) AS customers_with_email
FROM customers;
```

Vi kan också beräkna en andel:

```sql
SELECT
    100.0 * SUM(
        CASE
            WHEN email IS NOT NULL
             AND TRIM(email) <> ''
            THEN 1
            ELSE 0
        END
    ) / NULLIF(COUNT(*), 0) AS email_completeness_percent
FROM customers;
```

`NULLIF(COUNT(*), 0)` undviker division med noll om tabellen är tom.

Vi har nu gjort en kvalitetsdimension **mätbar**, men måttet behöver fortfarande tolkas. Om e-post inte krävs för alla kunder kan 100 procent vara ett olämpligt mål.

### Korrekthet behöver ofta en referens

Vissa fel kan vi inte upptäcka enbart genom att studera samma tabell.

Anta att `products.price` innehåller 200 kronor. Är det rätt pris?

Vi kan inte avgöra det utan att känna till vad vi jämför med.

Vi kanske har en kontrollerad prislista från inköps- eller affärssystemet. Då kan vi jämföra registrerade priser med referensvärden.

Det kan uttryckas med en Query som kombinerar två tabeller:

```sql
SELECT
    p.id,
    p.title,
    p.price AS registered_price,
    r.approved_price
FROM products AS p
INNER JOIN approved_prices AS r
    ON r.product_id = p.id
WHERE p.price <> r.approved_price;
```

Här är `approved_prices` en **tänkt referenstabell**, inte en del av vår befintliga bokhandelsmodell.

Även den tillförlitliga källan kan förstås innehålla fel eller ha en annan uppdateringstidpunkt. Därför behöver vi veta **vilket system eller beslut som är auktoritativt för respektive uppgift**.

### Aktualitet och tidens betydelse

Vi kan ha en korrekt adress som ändå är för gammal för att användas.

Det innebär att **korrekthet vid registreringstillfället** inte alltid är samma sak som **aktualitet vid användningstillfället**.

Vi kan därför komplettera vissa uppgifter med metadata om när de senast kontrollerades eller uppdaterades:

```text
customer_id | address | verified_at
------------+---------+--------------------
          2 | ...     | 2026-09-15 09:30:00
```

Det är ett konceptuellt exempel, inte en ändring vi redan gjort i `addresses`.

En Query kan identifiera uppgifter som behöver kontrolleras på nytt. Men ett sent datum innebär inte att uppgiften är korrekt, och ett gammalt datum innebär inte automatiskt att den är felaktig.

Aktualitet handlar om **hur snabbt verkligheten kan förändras och hur känslig användningen är för förändringen**.

### Flera dimensioner kan stå i konflikt

Vi kanske kan förbättra fullständigheten genom att kräva att alla kunder fyller i fler fält.

Men fler obligatoriska fält kan också leda till att användare fyller i godtyckliga värden för att komma vidare.

Vi kan få **mer data**, utan att få **bättre data**.

På samma sätt kan omfattande validering ge bättre skydd mot vissa fel men också hindra legitima uppgifter som inte passar ett alltför snävt format.

Kvalitetsarbete innebär därför att vi behöver värdera flera dimensioner tillsammans, utifrån verksamhetens behov.

### Förebygga, upptäcka och rätta

Vi kan skilja mellan tre slags kvalitetsarbete:

**Förebygga:** Använd datatyper, nycklar, begränsningar och välformulerade processer för inmatning.

**Upptäcka:** Kör kvalitetskontroller som hittar saknade värden, misstänkta dubbletter, brutna regler och oväntade förändringar.

**Rätta:** Undersök orsakerna och korrigera data utifrån en tillförlitlig källa eller verksamhetsregel.

Det är frestande att automatiskt ändra alla värden som avviker. Men en avvikelse är inte alltid ett fel.

Vi bör därför hålla isär **upptäckt** och **åtgärd**, särskilt när många poster kan påverkas.

### Datakvalitet i hela informationsflödet

Anta att en leverantör skickar en fil med produktuppgifter.

Vi importerar filen, uppdaterar bokhandelns databas och publicerar sedan produkterna på webbplatsen.

Fel kan uppstå i flera led:

- Uppgifterna kan vara fel redan hos leverantören.
- Importen kan tolka ett tal eller datum på fel sätt.
- Två produktidentifierare kan blandas ihop.
- Applikationen kan visa en gammal version av informationen.

Därför räcker det inte alltid att köra en kontroll i den slutliga databastabellen.

Vi behöver förstå **var data kommer ifrån, vilka förändringar de genomgått och vilka system som ansvarar för dem**.

Detta kallas ofta *data lineage* – informationens ursprung och väg genom olika bearbetningar.

### Tillförlitlighet och spårbarhet

När vi hittar en orimlig uppgift behöver vi kunna besvara frågor som:

Vem eller vilket system registrerade den? När ändrades den senast? Vilket underlag användes? Kan vi se det tidigare värdet?

Det kan kräva historik, loggning och metadata, men också rutiner för hur avvikelser rapporteras och beslutas.

I säkerhetskapitlet diskuterade vi loggning som ett sätt att upptäcka obehöriga förändringar. Här får spårbarhet ytterligare en betydelse: **att kunna förstå och förbättra informationens kvalitet**.

### Var hör kvalitetsreglerna hemma?

Vi har flera möjligheter:

| Plats | Exempel |
|---|---|
| **Databasens struktur** | `NOT NULL`, `CHECK`, `UNIQUE` och främmande nycklar |
| **Applikationen** | Hjälp vid inmatning och kontroller av verksamhetens arbetsflöde |
| **Datapipelines och importer** | Kontroller av format, förväntade värden och avvikande mängder |
| **Återkommande analyser** | Queries och rapporter som upptäcker kvalitetsproblem över tid |

En regel som alltid måste gälla bör, när det är möjligt och lämpligt, också skyddas av databasen.

Andra regler behöver mer kontext än vad en enskild tabell känner till. De kan vara beroende av andra system, avtal eller verksamhetsbeslut.

Att samma kvalitetsprincip kontrolleras på flera ställen behöver inte vara onödig dubblering. Kontrollerna kan ha **olika syften**.

### Att ett värde finns är inte samma sak som att vi vet något

Vi kan fylla varje kolumn i bokhandelns databas, sätta primärnycklar på varje tabell och få alla integritetskontroller att passera.

Ändå kan vi sakna tillförlitlig kunskap om kunderna, produkterna och beställningarna.

En databas kan garantera att värden har en viss **struktur**. Den kan också upprätthålla regler för vilka relationer och kombinationer som är tillåtna.

Men den kan inte ensam garantera att våra uppgifter är **sanna, aktuella och relevanta för det vi vill förstå eller göra**.

Det kräver att vi kopplar data till verksamhetens betydelser, källor och ansvar.

## Reflektion

1. Hur kan ett värde vara giltigt enligt databasens regler men ändå ha låg datakvalitet?
2. När är två likadana kundposter en oönskad dubblett, och när kan de beskriva olika saker?
3. Varför behöver vi förstå både informationens ursprung och dess användningsområde för att bedöma hur tillförlitlig den är?

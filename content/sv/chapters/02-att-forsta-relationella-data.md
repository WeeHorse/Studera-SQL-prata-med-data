# 2. Att förstå relationella data

Den relationella modellen formulerades av E. F. Codd 1970. För modellering av entiteter och samband blev Peter Chens ER-modell från 1976 ett betydelsefullt steg (se [Referenser och vidare läsning](/sv/referenser.html)).

En bokhandel behöver veta vilka kunder den har, var de bor och vart deras beställningar ska levereras. Informationen beskriver olika saker, men sakerna hör ihop.

När vi organiserar data behöver vi därför bestämma vad som är en självständig företeelse, vad som är en egenskap och vad som är ett samband. Valen påverkar vilka frågor vi kan besvara och hur lätt informationen går att förändra.

## Grund

### Entiteter och attribut

En **entitet** är något vi vill hålla reda på, exempelvis en kund eller en adress. Ett **attribut** är en egenskap som vi vill registrera om entiteten.

För en kund kanske vi vill spara namn och e-postadress. För en adress behöver vi gata, postnummer och ort.

**customers**

| id | name | email |
|---|---|---|
| 1 | Benjamin | benjamin@example.com |
| 2 | Olof | olof@example.com |
| 3 | Anaïs | anais@example.com |

En **entitet** hör till modellen av verkligheten; en **tabell** är vårt sätt att representera den i databasen.

### Identitet – vilken kund menar vi?

Det kan finnas två kunder med samma namn. Ett namn räcker alltså inte alltid för att identifiera en kund.

Vi kan därför tilldela varje kund ett eget id. Kolumnen `id` kan fungera som tabellens **primärnyckel** (*primary key*). Primärnyckelns värde måste vara unikt för varje rad och får inte vara `NULL`.

När vi vill hitta eller referera till en viss rad använder vi i första hand primärnyckeln. Skriver vi `WHERE id = 2` menar vi just Olofs rad, och därmed den information vi har lagrat om honom.

Primärnyckeln kan även bestå av flera kolumner, men här använder vi ett enda id.

### Var ska adresserna finnas?

Vi skulle kunna lägga adresserna direkt i kundtabellen.

| id | name | street | city |
|---|---|---|---|
| 1 | Benjamin | Hemmagatan 1 | Hemmavan |
| 2 | Olof | Parkvägen 2 | Storfors |

Men om Benjamin vill registrera både en fakturaadress och en leveransadress? Vi skulle kunna lägga till fler kolumner, men vad händer när vi behöver en tredje adress?

Vi kan i stället dela upp informationen i två tabeller.

**customers**

| id | name |
|---|---|
| 1 | Benjamin |
| 2 | Olof |
| 3 | Anaïs |

**addresses**

| id | customer_id | street | postal_code | city |
|---|---|---|---|---|
| 1 | 1 | Hemmagatan 1 | 124 56 | Hemmavan |
| 2 | 1 | Storgatan 4 | 154 32 | Storfors |
| 3 | 2 | Parkvägen 2 | 154 32 | Storfors |

Kolumnen `customer_id` innehåller värdet från `customers.id`. Den kan definieras som en **främmande nyckel** (*foreign key*).

En sådan begränsning hjälper databasen att kontrollera att en adress inte hänvisar till en kund som saknas. Att bara lagra samma id-värde räcker inte för att databasen ska kontrollera sambandet.

### En-till-många (1:N)

I vår modell kan en kund ha flera adresser, men varje adresspost hör till en kund.

Det är en **en-till-många-relation** (1:N).

```text
customers                 addresses
┌────┬──────────┐         ┌────┬─────────────┐
│ id │ name     │         │ id │ customer_id │
├────┼──────────┤         ├────┼─────────────┤
│  1 │ Benjamin │◄────────│  1 │      1      │
│    │          │◄────────│  2 │      1      │
│  2 │ Olof     │◄────────│  3 │      2      │
└────┴──────────┘         └────┴─────────────┘
```

Notera att två adressposter i vårt exempel kan ha samma `customer_id`. Det är just så en kund kan ha flera adresser.

### En-till-en (1:1)

I en **en-till-en-relation** hör varje post ihop med högst en post i den andra tabellen, och tvärtom.

Bokhandeln kanske lagrar särskilda kundinställningar separat, med högst en inställningspost per kund.

Ofta skulle informationen kunna ligga i samma tabell. Uppdelningen kan ändå vara lämplig om uppgifterna har andra åtkomstbehov eller bara finns för vissa kunder.

### Många-till-många (M:N)

Anta att bokhandeln längre fram vill registrera produkter och deras författare.

En bok kan ha flera författare, och en författare kan ha skrivit flera böcker. Det är ett exempel på en **många-till-många-relation**.

Den kan representeras med en **kopplingstabell**, exempelvis `product_authors`, som innehåller `product_id` och `author_id`.

Vi behöver inte skapa dessa tabeller än. Vi återkommer till dem när bokhandelns sortiment växer.

### Att rita en datamodell

Innan vi skapar tabeller kan vi rita upp vilka entiteter vi behöver och hur de hör ihop. Det kallas **ER-modellering** (*Entity–Relationship*).

Vår första modell kan beskrivas så här:

```text
┌───────────────┐    1       N    ┌────────────────┐
│ customers     │─────────────────│ addresses      │
├───────────────┤                 ├────────────────┤
│ id            │                 │ id             │
│ name          │                 │ customer_id    │
│ email         │                 │ street         │
└───────────────┘                 │ postal_code    │
                                  │ city           │
                                  └────────────────┘
```

Papper och penna är ofta fullt tillräckligt. Det viktiga är att förstå modellen, inte att rita ett snyggt diagram.

## Avancerat

### Kardinalitet och valfrihet

När vi beskriver ett samband behöver vi ställa två frågor:

- **Hur många?** Kan en kund ha en eller flera adresser?
- **Är sambandet obligatoriskt?** Måste varje kund ha en registrerad adress?

En kund kan i vår modell ha noll, en eller flera adresser (0..N). Varje adresspost måste däremot höra till exakt en kund (1..1), om vi bestämmer att det är en regel i verksamheten.

Sådana regler är en del av datamodellen. De följer inte automatiskt av vad vi kallar tabellerna.

### När två kunder delar adress

Två kunder kan bo på samma gata och samma nummer. Betyder det att de ska dela *samma adresspost*?

Inte nödvändigtvis.

I vår första modell har varje adresspost en ägare genom `customer_id`. Två kunder på samma fysiska adress kan därför ha varsin adresspost med samma gata och postnummer.

Om vi senare vill hantera en gemensam adresspost som flera kunder refererar till behöver vi förändra modellen. Vi skulle exempelvis kunna införa kopplingstabellen `customer_addresses`.

Det är en bra illustration av varför **verksamhetens behov avgör hur informationen ska organiseras**.

### När ett samband får egna attribut

Anta att vi behöver markera vilken adress som används för leverans och vilken som används för fakturering.

Vi kan lägga till ett `address_type` i vår enkla adressmodell.

Men om flera kunder ska kunna dela samma adresspost blir adressens roll något som hör till *sambandet mellan kund och adress*, inte till själva gatan och postnumret. Då kan uppgiften ligga i kopplingstabellen.

Vi kommer tillbaka till detta när vi arbetar med datamodellering och normalisering.

### Från adressregister till bokhandel

Hittills har vi bara beskrivit kunder och adresser. Senare behöver vi även hålla reda på sortiment, produkter, författare, varukorgar och beställningar.

Det går att grovt skilja mellan:

- **Masterdata:** relativt varaktiga uppgifter om exempelvis kunder och produkter.
- **Referensdata:** kontrollerade värden, exempelvis produkttyper.
- **Transaktionsdata:** uppgifter om verksamhetens händelser, exempelvis ordrar och orderrader.

Det är användbara kategorier, men inte absoluta gränser. Författare är exempelvis oftast masterdata snarare än referensdata, eftersom de är självständiga företeelser med egna egenskaper.

Vi ska fortsätta bygga ut samma bokhandel allt eftersom vi behöver fler delar av SQL.

### Relation i två betydelser

I ett ER-diagram beskriver en *relation* ett **samband mellan entiteter**.

I den matematiska relationsmodellen betyder ordet något annat: en relation är en mängd tupler över definierade attribut. Den kan förenklat liknas vid en tabell, men SQL-tabeller följer inte alltid alla den matematiska modellens egenskaper.

Orden är besläktade, men betydelserna är inte identiska.

### Från modell till implementation

ER-diagrammet hjälper oss att förstå vad vi vill beskriva innan vi börjar skriva SQL.

Så småningom kommer vi att skapa tabeller, ange primärnycklar och främmande nycklar och använda `JOIN` för att hämta information som finns i flera tabeller.

## Reflektion

1. Är en adress en självständig entitet eller en egenskap hos en kund? Vad avgör det?
2. Varför bör vi identifiera en kund med ett id snarare än ett namn?
3. Hur behöver modellen förändras om flera kunder ska kunna använda samma adresspost?

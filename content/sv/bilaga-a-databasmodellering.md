# Bilaga A – Att planera och modellera en databas

*Från verksamhetens frågor till en användbar informationsmodell.*

En databas börjar sällan med tabeller. Den börjar oftare med att någon behöver veta något, komma ihåg något eller kunna utföra något som inte fungerar tillräckligt bra idag.

Bokhandeln i den här boken behöver hålla reda på kunder, produkter och beställningar. Vi har redan mött dess tabeller och använt dem för att lära oss SQL. Men hur skulle vi ha kunnat komma fram till just den strukturen?

Vi börjar med en ofullständig verksamhetsbeskrivning. Vi formulerar frågor, identifierar begrepp och krav, ritar en modell, upptäcker problem och ändrar oss. Målet är inte den enda tänkbara lösningen, utan att förstå varför vår modell ser ut som den gör.

## 1. Ett uppdrag från bokhandeln

> Vi behöver ett system för att hålla reda på vårt sortiment och våra kunder. Kunderna ska kunna köpa böcker och vi behöver kunna se vad de har beställt. Vi vill också veta vilka författare som skrivit böckerna, vad produkterna kostar och hur många exemplar vi har i lager.

Det är ingen databasmodell. Vi vet ännu inte om en beställning får innehålla flera produkter, om en kund kan ha flera adresser eller hur historiska priser ska hanteras. Att omedelbart skriva `CREATE TABLE` riskerar att göra dessa osäkerheter till dolda antaganden.

Vi börjar i stället med frågor som verksamheten vill kunna besvara: Vilka produkter säljs? Vilka författare hör till en produkt? Vilka beställningar har en kund gjort? Vad kostade en produkt när den beställdes?

Den sista frågan skiljer en historisk händelse från ett aktuellt tillstånd. Redan innan vi har ritat ett diagram ser vi att informationens **betydelse och tidpunkt** kan påverka modellen.

### Uppdaterade krav – version 1

**Användningsbehov**
- Som bokhandlare vill jag kunna registrera och hitta kunder.
- Som bokhandlare vill jag kunna registrera produkter med pris och lagersaldo.
- Som bokhandlare vill jag kunna se vilka författare som hör till en produkt.
- Som bokhandlare vill jag kunna registrera och följa kundernas beställningar.

**Öppna frågor**
- Kan en beställning innehålla flera produkter?
- Kan en produkt ha flera författare?
- Kan en kund ha flera adresser?
- Vilken information måste bevaras historiskt?

Vi skiljer alltså på vad vi vet, vad vi antar och vad vi behöver undersöka.

## 2. Från ord till begrepp

I beskrivningen hittar vi tänkbara **entiteter**: kund, produkt, författare och beställning. En entitet är något vi behöver kunna beskriva och identifiera i vår informationsmodell.

Men varje substantiv blir inte automatiskt en tabell. Är *pris* en självständig företeelse eller ett attribut hos produkten? För en bokhandel med bara ett aktuellt försäljningspris kan det vara ett attribut. Med kampanjer och prislistor kan modellen behöva bli mer omfattande.

| Entitet | Tänkbara attribut |
|---|---|
| Kund | Namn, e-postadress |
| Produkt | Titel, pris, lagersaldo |
| Författare | Namn, e-postadress |
| Beställning | Beställningsdatum |

Vi behöver dessutom identiteter som inte är beroende av namn och titlar. Två kunder kan heta samma sak. Ett namn kan ändras. I vår logiska modell använder vi därför särskilda identifierare, exempelvis `id`.

### Vår första ER-modell

![Figur A.1: Första, förenklade ER-modellen med kund, beställning, produkt och författare.](./images/modell-a1.svg)

*Figur A.1 – Vårt första försök. Vi har ännu inte prövat antagandena om antal produkter och författare.*

### Uppdaterade krav – version 2

**Modelleringsbeslut**
- Kunder, produkter, författare och beställningar behandlas tills vidare som självständiga entiteter.
- Varje entitet ska kunna identifieras utan att förlita sig på exempelvis namn eller titel.
- Aktuellt pris och lagersaldo betraktas som attribut hos produkten.

**Antaganden att undersöka**
- En beställning gäller en enda produkt.
- En produkt har en enda författare.

## 3. När den första modellen inte räcker

Bokhandlaren vill kunna registrera två romaner och tre novellsamlingar i samma beställning. Det fungerar illa om beställningen bara avser en produkt. Vi kan förstås lägga produktidentifierare i en lista, men hur anger vi då antal och pris för varje produkt?

Vi har inte missat bara en kolumn utan ett sakförhållande: **beställningsraden**. En beställning innehåller flera rader och varje rad avser en bestämd produkt i ett bestämt antal.

| Beställning | Produkt | Antal |
|---|---|---:|
| 101 | Vägen hem | 2 |
| 101 | Vinterljus | 1 |
| 101 | Små historier | 3 |

En beställningsrad är ingen självständig fysisk sak. Den beskriver ändå något verksamheten måste kunna komma ihåg.

### Priset kan förändras

Om en bok kostar 200 kronor när kunden beställer den och 225 kronor veckan efteråt, ska den gamla beställningen fortfarande visa det avtalade priset. Därför skiljer vi på produktens **aktuella** `products.price` och orderradens **historiska** `order_items.unit_price`.

Det är inte nödvändigtvis onödig dubbellagring: två lika tal kan beskriva olika sakförhållanden.

### Uppdaterade krav – version 3

**Användningsbehov**
- Som kund vill jag kunna beställa flera produkter samtidigt.
- Som bokhandlare vill jag kunna se antal och pris för varje beställd produkt.
- Som bokhandlare vill jag kunna se det registrerade priset även efter en prisändring.

**Verksamhetsregler**
- En orderrad hör till exakt en beställning och avser exakt en produkt.
- En orderrad måste ha ett positivt antal.
- Ordradens pris bevaras som en uppgift om beställningen.

**Modellförändring:** Vi inför `ORDER_ITEM` mellan beställning och produkt.

## 4. När en bok har flera författare

Vi återvänder till antagandet att en produkt har en författare. Bokhandeln säljer antologier och böcker som skrivits av flera personer. Samtidigt kan en författare ha skrivit flera böcker.

Sambandet är alltså **många-till-många (M:N)**. I en konceptuell modell kan vi rita det direkt. I en relationell databas kommer vi senare att representera det med `product_authors`.

Ett samband kan dessutom ha egna attribut. Bokhandeln kanske vill spara i vilken ordning författarna ska visas. Den ordningen beskriver inte författaren ensam eller produkten ensam, utan författarens roll för den produkten.

Vi behöver också kunna klassificera produkter som exempelvis romaner eller novellsamlingar. I grundmodellen får **produkttypen** en egen entitet, `PRODUCT_TYPE`. En produkt kan tills vidare sakna registrerad typ.

### Uppdaterade krav – version 4

**Användningsbehov**
- Som bokhandlare vill jag kunna registrera flera författare för en produkt.
- Som bokhandlare vill jag kunna hitta alla produkter kopplade till en viss författare.
- Som bokhandlare vill jag kunna klassificera produkter efter typ.

**Verksamhetsregler**
- En författare kan vara knuten till flera produkter.
- En produkt kan vara knuten till flera författare.
- En författare kan registreras utan att ännu ha någon produkt.
- En produkt kan sakna registrerad produkttyp.

**Modellförändring:** M:N-samband och ny entitet för produkttyp.

## 5. Kunder och adresser

Bokhandlaren behöver kunna registrera flera adresser för samma kund. Vi skulle kunna skapa fler adresskolumner i kundtabellen, men hur många? Och vad händer när en kund behöver ytterligare en adress?

Vi väljer separata **adressposter**. I vår grundmodell hör varje adresspost till en kund, medan en kund kan ha flera poster.

Två kunder kan bo på samma fysiska adress. Måste de då dela samma adresspost? Inte nödvändigtvis. Vi väljer att adressposten representerar en uppgift registrerad för en viss kund. Om vi senare behöver gemensamma adressobjekt, adresshistorik eller olika adressroller krävs mer analys.

### Uppdaterade krav – version 5

**Användningsbehov**
- Som bokhandlare vill jag kunna registrera flera adresser för samma kund.
- Som bokhandlare vill jag kunna hitta kundens registrerade adresser.

**Verksamhetsregler**
- En kund kan ha noll, en eller flera adressposter.
- Varje adresspost tillhör exakt en kund.
- Två adressposter kan innehålla samma gatunamn och postnummer.

**Avgränsning:** Gemensamma adressobjekt och adresshistorik ingår inte i grundmodellen.

## 6. Den reviderade konceptuella modellen

Nu kan vi rita en modell som faktiskt följer våra beslut.

![Figur A.2: Reviderad konceptuell ER-modell med adress, orderrad, produkttyp och många-till-många-samband till författare.](./images/modell-a2.svg)

*Figur A.2 – Den konceptuella modellen efter våra diskussioner.*

Här använder vi kardinalitet och valfrihet för att uttrycka vad verksamheten menar. En kund kan finnas utan beställningar; en beställning hör till en kund. En produkt kan ha flera författare.

Vi måste dock skilja på **avsedda verksamhetsregler** och vad den slutliga SQL-implementationen kan garantera. Exempelvis kanske vi vill kräva att en färdig beställning har minst en orderrad, men den regeln följer inte enbart av att varje orderrad har en främmande nyckel till en beställning.

Diagrammet är därmed ett underlag för fler frågor, inte ett slutgiltigt facit.

## 7. Från konceptuell till logisk modell

Nu översätter vi begreppen till **relationer, attribut och nycklar**.

Vi väljer `customers.id` som primärnyckel för kunder och låter `orders.customer_id` vara en främmande nyckel som visar vilken kund som gjort beställningen.

När en relation är M:N behöver vi i den relationella modellen en särskild kopplingstabell. `product_authors` får därför en sammansatt primärnyckel av `product_id` och `author_id`.

Den sammanlagda modellen får åtta tabeller, precis som i bokens gemensamma exempeldatabas.

![Figur A.3: Logisk ER-modell med bokhandelns åtta tabeller samt primärnycklar och främmande nycklar.](./images/modell-a3.svg)

*Figur A.3 – Den logiska modellen, med nycklar och referenser.*

Skillnaden mot föregående diagram är viktig. Den konceptuella modellen beskrev företeelser och samband. Den logiska modellen uttrycker hur dessa kan representeras som relationer.

Vi har inte börjat med att bestämma att bokhandeln ska ha åtta tabeller. **Antalet tabeller är följden av våra beslut om identitet, informationens betydelse och relationerna.**

## 8. Normalisering som en del av analysen

Vi har redan gått igenom normalformerna i kapitel 14. Här använder vi dem som stöd för granskning.

Om vi lagrade författarens e-postadress på varje produkt skulle en namn- eller adressändring behöva göras på flera ställen. Därför skiljer vi på `products` och `authors` och låter `product_authors` beskriva kopplingarna.

Om vi lagrade produkttypens namn på varje produktrad skulle kategoriernas benämningar upprepas. Genom `product_types` får klassificeringen en tydligare plats.

Men inte varje lika värde betyder samma sak. Aktuellt produktpris och registrerat orderpris kan vara lika, men beskriva olika tider och olika sakförhållanden.

Vi kan granska modellen med några frågor:

- Beskriver varje relation en sammanhängande företeelse eller ett samband?
- Finns attribut som egentligen beskriver något annat?
- Beror uppgifterna på rätt identifierare?
- Måste ett och samma sakförhållande underhållas på flera ställen?
- Behöver vi bevara historiska värden separat från aktuella?

Det här ersätter inte en formell normaliseringsanalys. Men det visar varför normalisering hör hemma i en större **modelleringsprocess**, inte bara i en lista över tekniska regler.

## 9. Vad har vi ännu inte modellerat?

Vår modell räcker för många av bokens SQL-exempel. Det innebär inte att den beskriver hela bokhandelns verksamhet.

**När kunden flyttar.** Vi lagrar kundens adressposter men knyter ingen historisk leveransadress till beställningen. Det kan göra det svårt att veta vilken adress som gällde för en äldre order.

**När en produkt försvinner ur sortimentet.** Om historiska orderrader hänvisar till produkten behöver bokhandeln kanske behålla produktposten men markera produkten som inaktiv. Grundmodellen har ingen sådan status.

**När samma bok finns i flera format.** En roman kan ges ut som pocket, inbunden bok och e-bok. Är det samma produkt? Om de har olika pris och lager kan de representeras som olika produkter, men vi kan också behöva beskriva ett gemensamt verk och dess utgåvor.

### Uppdaterade krav – version 6

**Möjliga nya användningsbehov**
- Som bokhandlare vill jag kunna se leveransadressen som användes för en äldre beställning.
- Som bokhandlare vill jag kunna bevara beställningshistorik när produkter inte längre säljs.
- Som bokhandlare vill jag kunna hitta olika utgåvor och format av samma verk.

**Öppna modelleringsfrågor**
- Behöver beställningar historiska adressuppgifter?
- Behöver produkter en aktiv/inaktiv-status?
- Behöver vi skilja mellan litterära verk, utgåvor och säljbara produkter?

**Avgränsning:** Vi dokumenterar behoven men förändrar inte undervisningsexemplets åtta tabeller.

Det är fullt möjligt att identifiera ett behov och samtidigt besluta att det ligger utanför den aktuella modellens syfte.

## 10. Dokumentera besluten

En ritning visar hur modellen ser ut. Den visar sällan varför vi valde just den.

| Beslut | Motivering | Konsekvens |
|---|---|---|
| Författare lagras separat | En författare kan ha flera produkter | `authors` och `product_authors` |
| Beställningar har orderrader | Ett köp kan omfatta flera produkter | `order_items` |
| Orderpris sparas historiskt | Produktpriset kan ändras | `unit_price` på orderraden |
| Kundadresser lagras separat | En kund kan ha flera adresser | `addresses` |
| Produkttyper lagras separat | Gemensam klassificering av produkter | `product_types` |

Det räcker ofta med en kort beslutslogg och en lista över kända avgränsningar. Den dokumentationen kan bli minst lika viktig som ER-diagrammet när verksamheten och systemet utvecklas.

## 11. En modell är en representation

Vi började med bokhandelns behov, formulerade frågor, identifierade begrepp och ritade en första modell. När vi upptäckte att den inte räckte till omformulerade vi kraven och ritade om.

Arbetet kan beskrivas som:

**Verksamhetsbeskrivning → frågor → krav → begreppsmodell → ER-modell → logisk modell → granskning och omprövning.**

Men processen är inte linjär. Vi kan behöva gå tillbaka och undersöka ett begrepp när den logiska modellen visar sig svår att formulera. Ett nytt verksamhetsbehov kan förändra tidigare beslut.

Databasen är inte bokhandeln. Den är en medvetet begränsad representation av de sakförhållanden vi valt att beskriva.

**Att planera en databas är därför inte i första hand att bestämma vilka tabeller som ska finnas. Det är att undersöka vilka sakförhållanden vi behöver kunna representera, vilka samband som gäller och vilka frågor informationen ska hjälpa oss att besvara.**

## Reflektion

1. Varför kan det vara problematiskt att skapa tabeller innan vi har undersökt informationsbehoven?
2. Vad skiljer en User Story från en verksamhetsregel?
3. Varför behövdes beställningsrader i den första modellen?
4. Hur förändras modellen när en produkt kan ha flera författare?
5. Varför bör vi dokumentera både våra beslut och de behov som ligger utanför modellen?

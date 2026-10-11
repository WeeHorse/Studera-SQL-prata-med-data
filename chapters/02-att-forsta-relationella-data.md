# 2. Att förstå relationella data

Information handlar sällan om en enda sak. En person har en adress, en kund gör beställningar och en bok kan ha flera författare.

När vi organiserar information behöver vi därför inte bara beskriva saker och deras egenskaper, utan också sambanden mellan dem. Ibland är sambanden enkla. Ibland visar det sig att det vi trodde var en egenskap egentligen är en egen företeelse.

Relationella databaser hjälper oss att beskriva dessa samband utan att behöva samla all information på samma ställe.

## Grund

### Entiteter och attribut

Vi börjar med några personer och deras husdjur.

En **entitet** är något vi vill hålla reda på, exempelvis en person eller ett husdjur. Ett **attribut** är en egenskap som vi vill registrera om entiteten.

En person kan ha attribut som namn och födelsedatum. Ett husdjur kan ha namn och djurart.

| Person | Födelsedatum |
|---|---|
| Anna | 1992-04-12 |
| Olof | 1988-09-03 |

| Husdjur | Djurart |
|---|---|
| Fido | Hund |
| Morris | Katt |

I en databas kan vi representera varje typ av entitet med en tabell, och attributen med kolumner.

En entitet är alltså inte samma sak som en tabell. Entiteten tillhör vår *modell* av verkligheten; tabellen är ett sätt att representera den i databasen.

### Identitet – hur vet vi vilken vi menar?

Anta att två personer heter Anna. Hur skiljer vi dem åt?

Ett namn räcker inte alltid för att identifiera en person. Vi behöver något som entydigt talar om vilken post vi menar.

Därför kan vi ge varje person ett eget **id**.

| id | name | birth_date |
|---|---|---|
| 1 | Anna | 1992-04-12 |
| 2 | Olof | 1988-09-03 |
| 3 | Anna | 2001-11-20 |

Kolumnen `id` kan fungera som tabellens **primärnyckel** (*primary key*). Primärnyckelns värde måste vara unikt för varje rad och får inte vara `NULL`.

Identiteten påverkas då inte av att en person byter namn.

En primärnyckel kan också bestå av flera kolumner, men i våra första exempel använder vi ett enda `id` för att hålla modellen enkel.

### Samband mellan entiteter

Nu vill vi veta vem som äger vilket husdjur.

Vi skulle kunna lägga in ägarens namn i tabellen med husdjur:

| pet | species | owner |
|---|---|---|
| Fido | Hund | Anna |
| Morris | Katt | Anna |
| Bella | Hund | Olof |

Men om vi har två personer som heter Anna blir informationen tvetydig.

Vi kan i stället använda personens id:

**persons**

| id | name |
|---|---|
| 1 | Anna |
| 2 | Olof |
| 3 | Anna |

**pets**

| id | name | species | owner_id |
|---|---|---|---|
| 1 | Fido | Hund | 1 |
| 2 | Morris | Katt | 1 |
| 3 | Bella | Hund | 2 |

Nu visar `owner_id` vilket värde i `persons.id` husdjuret hör ihop med.

Detta kallas en **främmande nyckel** (*foreign key*).

En viktig skillnad: att lagra ett id i en kolumn är inte automatiskt samma sak som att databasen kontrollerar relationen. För det behöver vi också definiera en främmande nyckelbegränsning. Det kommer vi att göra i ett senare kapitel.

### En-till-många (1:N)

I vårt exempel kan en person äga flera husdjur, medan varje husdjur har en ägare.

Det är en **en-till-många-relation**: en person kan höra ihop med många husdjur.

```text
persons                     pets
┌────┬────────┐             ┌────┬────────┬──────────┐
│ id │ name   │             │ id │ name   │ owner_id │
├────┼────────┤             ├────┼────────┼──────────┤
│  1 │ Anna   │◄────────────│  1 │ Fido   │    1     │
│    │        │◄────────────│  2 │ Morris │    1     │
│  2 │ Olof   │◄────────────│  3 │ Bella  │    2     │
└────┴────────┘             └────┴────────┴──────────┘
```

Relationen beskrivs genom att flera rader i `pets` kan referera till samma rad i `persons`.

### En-till-en (1:1)

I en **en-till-en-relation** hör en post ihop med högst en post i den andra tabellen, och tvärtom.

Vi skulle exempelvis kunna lagra personer och en separat uppsättning inställningar, där varje person kan ha högst en inställningspost.

Sådana uppgifter kan ofta ligga i samma tabell, men ibland finns skäl att dela upp dem, exempelvis olika åtkomstbehov eller att inställningarna är frivilliga.

### Många-till-många (M:N)

Men vad händer om två personer samäger ett husdjur?

Då räcker inte längre ett enda `owner_id` i `pets`. Varje person kan äga flera husdjur, och varje husdjur kan ha flera ägare.

Vi kan beskriva sambandet i en tredje tabell:

**persons**

| id | name |
|---|---|
| 1 | Anna |
| 2 | Olof |

**pets**

| id | name |
|---|---|
| 1 | Fido |
| 2 | Morris |

**pet_owners**

| person_id | pet_id |
|---|---|
| 1 | 1 |
| 2 | 1 |
| 1 | 2 |

Fido ägs av både Anna och Olof. Morris ägs av Anna.

Tabellen `pet_owners` kallas ofta en **kopplingstabell**. Den representerar sambandet mellan personer och husdjur.

Så kan en många-till-många-relation representeras med två en-till-många-relationer.

### Att rita en datamodell

Innan vi bygger tabeller kan vi rita upp vilka entiteter vi behöver och hur de hör ihop. En sådan modell kallas ofta ett **ER-diagram** (*Entity–Relationship diagram*).

En förenklad skiss av vårt exempel kan se ut så här:

```text
┌───────────┐       ┌─────────────┐       ┌───────────┐
│  persons  │  1  N │ pet_owners  │ N  1  │   pets    │
├───────────┤───────├─────────────┤───────├───────────┤
│ id        │       │ person_id   │       │ id        │
│ name      │       │ pet_id      │       │ name      │
└───────────┘       └─────────────┘       └───────────┘
```

Vi börjar gärna med papper och penna. Syftet är inte att rita snyggt, utan att upptäcka vilka samband vi faktiskt behöver beskriva.

## Avancerat

### Kardinalitet och valfrihet

När vi beskriver en relation behöver vi ofta besvara två olika frågor:

- **Hur många?** Kan en person äga ett eller flera husdjur? Kan ett husdjur ha flera ägare?
- **Måste det finnas ett samband?** Kan en person sakna husdjur? Kan ett husdjur tillfälligt sakna registrerad ägare?

Detta beskrivs med *kardinalitet* och ibland med *minsta och största deltagande* (till exempel 0..N eller 1..N).

Vår första modell antog att varje husdjur hade exakt en ägare. När vi tillät samägande behövde modellen förändras.

Det visar något viktigt: **En relation bestäms av verksamhetens regler, inte bara av hur tabellerna ser ut.**

### När ett samband får egna attribut

Anta att vi också vill registrera när en person blev ägare till ett husdjur.

Datumet beskriver varken personen i allmänhet eller husdjuret i allmänhet. Det beskriver just *ägandet*.

Då kan kopplingstabellen innehålla fler uppgifter:

| person_id | pet_id | since |
|---|---|---|
| 1 | 1 | 2024-02-01 |
| 2 | 1 | 2025-06-15 |
| 1 | 2 | 2023-09-10 |

En koppling är alltså inte alltid bara två id-värden. Själva sambandet kan ha egenskaper.

### Vad gör en modell korrekt?

Det finns inte alltid ett enda rätt sätt att dela upp information.

Vi valde exempelvis att beskriva `species` som en egenskap hos ett husdjur. Om vi behöver mer information om olika djurarter kan det vara rimligt att skapa en separat tabell för arter.

Vi behöver därför ställa frågor om vad informationen ska användas till, vilka förändringar som är möjliga och vilka regler som gäller.

Modellering är inte bara en teknisk uppgift. Den kräver att vi förstår området som databasen ska beskriva.

### Relation i två betydelser

Ordet *relation* används också i den matematiska relationsmodellen som ligger bakom relationella databaser.

Där är en relation en mängd tupler med definierade attribut. Den kan i förenklad form liknas vid en tabell, men är inte identisk med alla egenskaper hos en SQL-tabell.

I ER-modellering använder vi däremot ordet relation för ett **samband mellan entiteter**.

Det är alltså två närbesläktade, men olika, betydelser av samma ord.

### Från modell till databas

Ett ER-diagram hjälper oss att planera strukturen innan vi skapar den i SQL.

Vi behöver bland annat bestämma vilka tabeller som ska finnas, vilka nycklar de ska ha och vilka regler som ska gälla för sambanden.

Senare kommer vi att använda SQL för att skapa tabellerna och upprätthålla relationerna. Vi ska också se hur vi med `JOIN` kan kombinera information från tabellerna igen, när vi vill besvara en fråga.

## Reflektion

1. Är en adress en egenskap hos en person eller en egen entitet? När kan det ena eller andra vara lämpligt?
2. Varför kan det vara problematiskt att använda ett namn som identifierare?
3. Vad säger det om vår datamodell när verksamhetens regler förändras?

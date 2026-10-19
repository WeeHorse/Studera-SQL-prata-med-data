---
title: Referenser och vidare läsning
sidebar: false
---

# Referenser och vidare läsning

Den här boken är en introduktion till SQL, inte en vetenskaplig översiktsartikel. Referenserna nedan pekar dels till några av idéernas historiska ursprung, dels till standarder och dokumentation som kan användas för fortsatt fördjupning. De ska inte läsas som en fullständig redovisning av vilka källor som har använts vid varje exempel i boken.

## Historiska originalarbeten

**Codd, E. F. (1970).** ”A Relational Model of Data for Large Shared Data Banks.” *Communications of the ACM*, 13(6), 377–387. [Läs artikeln](https://doi.org/10.1145/362384.362685).

En grundläggande beskrivning av den relationella modellen och tanken att den logiska beskrivningen av data ska skiljas från den fysiska lagringen.

**Chamberlin, D. D. & Boyce, R. F. (1974).** ”SEQUEL: A Structured English Query Language.” *Proceedings of the 1974 ACM SIGFIDET Workshop*, 249–264. [Läs originalpubliceringen](https://doi.org/10.1145/800296.811515) · [IBM Research](https://research.ibm.com/publications/sequel-a-struciured-english-query-language).

Ett tidigt arbete bakom det språk som senare blev SQL. Bokens omslag anknyter till denna publikation.

**Chen, P. P.-S. (1976).** ”The Entity-Relationship Model—Toward a Unified View of Data.” *ACM Transactions on Database Systems*, 1(1), 9–36. [Läs artikeln](https://doi.org/10.1145/320434.320440).

En klassisk utgångspunkt för att modellera entiteter, attribut och samband; särskilt relevant för bilaga A.

## Standard och systemdokumentation

**ISO/IEC 9075 – Database languages — SQL.** Den internationella standardfamiljen för SQL. [Sök standardens delar hos ISO](https://www.iso.org/search.html?q=ISO%2FIEC%209075).

**Oracle.** *MySQL 8.4 Reference Manual*. [Officiell dokumentation](https://dev.mysql.com/doc/refman/8.4/en/). Praktisk referens för den SQL-dialekt som används i många av bokens exempel.

**PostgreSQL Global Development Group.** *PostgreSQL Documentation*. [Officiell dokumentation](https://www.postgresql.org/docs/current/). Användbar för att jämföra SQL-dialekter, datatyper och implementationer.

## Fördjupning

**Date, C. J.** *An Introduction to Database Systems*. Addison-Wesley. En mer omfattande behandling av relationsmodellen och databasteori.

För den som vill gå vidare är det värdefullt att läsa både de ursprungliga texterna och dokumentationen för det databassystem man faktiskt arbetar med. De svarar på olika frågor: *varför* relationella databaser ser ut som de gör, och *hur* en viss implementation fungerar.

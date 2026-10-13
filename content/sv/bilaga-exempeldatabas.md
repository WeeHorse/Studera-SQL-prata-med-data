<script setup>
import { withBase } from 'vitepress'
</script>

# Bilaga – exempeldatabasen

Bokens återkommande exempel utgår från en fiktiv bokhandel. Här kan du ladda ner ett SQL-skript som skapar tabellerna och fyller dem med samma grunddata som används i många av kapitlens exempel.

## MySQL

<a :href="withBase('/downloads/studera-sql-mysql.sql')" download>Ladda ner bokhandelns exempeldatabas för MySQL (.sql)</a>

Skriptet är avsett för **MySQL 8.0.16 eller senare**. Det skapar databasen `studera_sql_bokhandel`, åtta tabeller och ett litet antal exempelrader.

Du kan till exempel köra det från terminalen med:

```sh
mysql -u ditt_anvandarnamn -p < studera-sql-mysql.sql
```

Eller öppna filen i en SQL-klient och köra den där. Använd ett konto som har rättigheter att skapa databaser och tabeller.

**Viktigt:** Kör skriptet i en tom databas. Det är inte avsett att återställas eller köras upprepade gånger ovanpå befintliga data. Om du arbetar med övningar som ändrar eller tar bort rader kan du skapa en ny tom databas och läsa in originalfilen igen.

### Vad ingår?

| Tabell | Innehåll |
|---|---|
| `customers` | Bokhandelns kunder |
| `addresses` | Kundernas adresser |
| `product_types` | Produktkategorier |
| `products` | Böcker, priser och lagersaldon |
| `authors` | Författare |
| `product_authors` | Kopplingar mellan böcker och författare |
| `orders` | En exempelbeställning |
| `order_items` | Beställningens produkter och historiska priser |

**Avgränsning:** I några kapitel används även tillfälliga eller tänkta utökningar, till exempel `reservations`, `categories`, `stores`, geografiska datatyper och JSON-kolumner. Dessa ingår inte i grundfilen. Exemplen som förändrar data är illustrationer och ska inte nödvändigtvis köras i följd.

Vi kan senare komplettera bilagan med motsvarande filer för PostgreSQL, SQLite och SQL Server, när dialekterna är granskade.

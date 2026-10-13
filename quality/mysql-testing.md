# Teknisk kontroll av SQL-exemplen

## MySQL – första automatiserade testsviten

`tests/mysql/verify-examples.sh` läser in **samma .sql-fil som kan laddas ned från GitHub Pages** och kontrollerar utvalda frågor mot en riktig MySQL 8.0-server.

Testerna täcker inledningsvis data och resultat från kapitel 5, 8, 9, 10, 14 och 18 samt primärnycklar, främmande nycklar och CHECK-regler. De kontrollerar även att avvisade INSERT-försök inte förändrar antalet produkter.

### GitHub Actions

`.github/workflows/mysql-examples.yml` startar en isolerad MySQL 8.0-service och kör verifieringen vid relevanta PR:er och ändringar på `main`. Den kan även startas manuellt från Actions.

### Lokalt

**Varning:** skriptet kör `DROP DATABASE IF EXISTS studera_sql_bokhandel`. Använd en **separat testserver**, aldrig en server med värdefulla data under det namnet.

```bash
export MYSQL_HOST=127.0.0.1
export MYSQL_PORT=3306
export MYSQL_USER=root
export MYSQL_PASSWORD='testlösenord'
bash tests/mysql/verify-examples.sh
```

### Avgränsning och fortsatt arbete

Detta är ett **första integrationstest**, inte en garanti att alla kodexempel i samtliga 29 kapitel är exekverade. Kapitel med egna tabeller, transaktionsflöden, JSON, spatial SQL och databasadministration kräver separata testfall. Man bör också skilja på SQL som är körbar kod och korta fragment som förklarar en klausul.

När fler tester tillkommer bör de grupperas per kapitel och vid behov använda egna temporära testdata.

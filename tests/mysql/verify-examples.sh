#!/usr/bin/env bash
set -euo pipefail

: "${MYSQL_HOST:=127.0.0.1}"
: "${MYSQL_PORT:=3306}"
: "${MYSQL_USER:=root}"
: "${MYSQL_PASSWORD:?Ange MYSQL_PASSWORD för testdatabasen}"

# Använd endast en separat testserver: databasen raderas vid återställning.
mysql_cmd=(mysql --host="$MYSQL_HOST" --port="$MYSQL_PORT" --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" --batch --raw --skip-column-names --default-character-set=utf8mb4)

echo "Återställer en separat testdatabas ..."
"${mysql_cmd[@]}" -e "DROP DATABASE IF EXISTS studera_sql_bokhandel;"
"${mysql_cmd[@]}" < content/public/downloads/studera-sql-mysql.sql

query() {
  "${mysql_cmd[@]}" studera_sql_bokhandel -e "$1"
}
assert_eq() {
  local label="$1" expected="$2" sql="$3" actual
  actual="$(query "$sql")"
  if [[ "$actual" != "$expected" ]]; then
    printf 'FEL: %s\nFörväntat: %s\nFick: %s\n' "$label" "$expected" "$actual" >&2
    exit 1
  fi
  echo "OK: $label"
}
assert_rejected() {
  local label="$1" sql="$2"
  if query "$sql" >/dev/null 2>&1; then
    echo "FEL: $label – otillåten ändring accepterades" >&2
    exit 1
  fi
  echo "OK: $label"
}

# Samma grunddata som i kapitel 5, 8, 9, 10 och 14.
assert_eq "Kapitel 1: adresser i Hemmavan" 1 "SELECT COUNT(*) FROM addresses WHERE city = 'Hemmavan';"
assert_eq "Fem kunder" 5 "SELECT COUNT(*) FROM customers;"
assert_eq "Fem produkter" 5 "SELECT COUNT(*) FROM products;"
assert_eq "50 exemplar" 50 "SELECT SUM(stock) FROM products;"
assert_eq "Lagervärde 8016" 8016.00 "SELECT SUM(price * stock) FROM products;"
assert_eq "Medelpris 179.80" 179.800000 "SELECT AVG(price) FROM products;"
assert_eq "Kunder födda 1980–1999" $'Anaïs\nOlof' "SELECT name FROM customers WHERE birthday >= '1980-01-01' AND birthday < '2000-01-01' ORDER BY name;"
assert_eq "Adresser i Storfors" 2 "SELECT COUNT(*) FROM addresses WHERE city = 'Storfors';"
assert_eq "Produkter per typ" $'1\t3\n2\t2' "SELECT product_type_id, COUNT(*) FROM products GROUP BY product_type_id ORDER BY product_type_id;"
assert_eq "Lagervärde per typ" $'1\t3396.00\n2\t4620.00' "SELECT product_type_id, SUM(price * stock) FROM products GROUP BY product_type_id ORDER BY product_type_id;"
assert_eq "Författarkopplingar" 4 "SELECT COUNT(*) FROM products p JOIN product_authors pa ON pa.product_id = p.id JOIN authors a ON a.id = pa.author_id;"
assert_eq "Unika städer" 3 "SELECT COUNT(DISTINCT city) FROM addresses;"
assert_eq "CTE: största lagervärdet" 'Små historier' "WITH product_values AS (SELECT title, price*stock AS inventory_value FROM products) SELECT title FROM product_values WHERE inventory_value > 2000 ORDER BY inventory_value DESC LIMIT 1;"
assert_eq "Ordrader och historiskt pris" 249.00 "SELECT SUM(quantity * unit_price) FROM order_items;"

# Fler resultatkontroller, med entydig sortering.
assert_eq "Kapitel 10: böcker över medelpriset" 'Vägen hem,Vinterljus,Mellan raderna' "SELECT GROUP_CONCAT(title ORDER BY id) FROM products WHERE price > (SELECT AVG(price) FROM products);"
assert_eq "Kapitel 19: ROW_NUMBER efter pris" 'Vinterljus,Vägen hem,Mellan raderna,Den blå staden,Små historier' "SELECT GROUP_CONCAT(title ORDER BY price_position) FROM (SELECT title, ROW_NUMBER() OVER (ORDER BY price DESC, id) AS price_position FROM products) AS ranked;"
assert_eq "Kapitel 19: fönsterfunktion med partiell medelprisjämförelse" 3 "SELECT COUNT(*) FROM (SELECT price, AVG(price) OVER (PARTITION BY product_type_id) AS average_price FROM products) AS p WHERE price > average_price;"
query "CREATE VIEW quality_test_product_overview AS SELECT p.id, p.title, t.name AS product_type FROM products AS p JOIN product_types AS t ON t.id = p.product_type_id;"
assert_eq "Kapitel 17: View med relation" '3' "SELECT COUNT(*) FROM quality_test_product_overview WHERE product_type='Roman';"
query "DROP VIEW quality_test_product_overview;"

# Kapitel 11 använder utökade adresser. Skapa testtabell utan att ändra grundfilen.
query "CREATE TABLE quality_test_addresses AS SELECT * FROM addresses;"
query "INSERT INTO quality_test_addresses (id, customer_id, street, postal_code, city) VALUES (5,1,'Strandgatan 7',NULL,'Malmö'), (6,4,'Torget 3',NULL,'Malmö'), (7,5,'Skolgatan 8',NULL,'Storfors');"
assert_eq "Kapitel 11: UNION" '1,2,3,4,5' "SELECT GROUP_CONCAT(customer_id ORDER BY customer_id) FROM (SELECT customer_id FROM quality_test_addresses WHERE city = 'Storfors' UNION SELECT customer_id FROM quality_test_addresses WHERE city = 'Malmö') AS ids;"
assert_eq "Kapitel 11: UNION ALL" 6 "SELECT COUNT(*) FROM (SELECT customer_id FROM quality_test_addresses WHERE city = 'Storfors' UNION ALL SELECT customer_id FROM quality_test_addresses WHERE city = 'Malmö') AS ids;"
assert_eq "Kapitel 11: INTERSECT" 1 "SELECT GROUP_CONCAT(customer_id ORDER BY customer_id) FROM (SELECT customer_id FROM quality_test_addresses WHERE city = 'Storfors' INTERSECT SELECT customer_id FROM quality_test_addresses WHERE city = 'Malmö') AS ids;"
assert_eq "Kapitel 11: EXCEPT" '2,5' "SELECT GROUP_CONCAT(customer_id ORDER BY customer_id) FROM (SELECT customer_id FROM quality_test_addresses WHERE city = 'Storfors' EXCEPT SELECT customer_id FROM quality_test_addresses WHERE city = 'Malmö') AS ids;"
query "DROP TABLE quality_test_addresses;"

# Kapitel 12–16: kopiera schema och data före ändringar. Originaltabellerna påverkas inte.
query "CREATE TABLE quality_test_products LIKE products;"
query "INSERT INTO quality_test_products SELECT * FROM products;"
assert_eq "Kapitel 15: ursprungligt lagersaldo" 12 "SELECT stock FROM quality_test_products WHERE id = 1;"
query "UPDATE quality_test_products SET stock = stock + 5 WHERE id = 1;"
assert_eq "Kapitel 15: UPDATE ökar saldo" 17 "SELECT stock FROM quality_test_products WHERE id = 1;"
query "INSERT INTO quality_test_products (id, title, price, product_type_id) VALUES (7, 'Om databaser', 225.00, 1);"
assert_eq "Kapitel 15: DEFAULT ger noll i lager" 0 "SELECT stock FROM quality_test_products WHERE id = 7;"
query "DELETE FROM quality_test_products WHERE id = 7;"
assert_eq "Kapitel 15: DELETE tar bort raden" 0 "SELECT COUNT(*) FROM quality_test_products WHERE id = 7;"
query "ALTER TABLE quality_test_products ADD COLUMN isbn VARCHAR(20);"
assert_eq "Kapitel 16: ny kolumn ger NULL" 5 "SELECT COUNT(*) FROM quality_test_products WHERE isbn IS NULL;"
query "UPDATE quality_test_products SET isbn = '9781234567897' WHERE id = 1;"
assert_eq "Kapitel 16: UPDATE kompletterar ISBN" 1 "SELECT COUNT(*) FROM quality_test_products WHERE id = 1 AND isbn = '9781234567897';"
query "ALTER TABLE quality_test_products ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;"
assert_eq "Kapitel 16: befintliga rader aktiva" 5 "SELECT COUNT(*) FROM quality_test_products WHERE is_active = TRUE;"
query "ALTER TABLE quality_test_products RENAME COLUMN title TO product_title;"
assert_eq "Kapitel 16: namnändring" 1 "SELECT COUNT(*) FROM quality_test_products WHERE product_title = 'Vägen hem';"
query "CREATE VIEW quality_test_catalog AS SELECT id, product_title AS title, price FROM quality_test_products;"
assert_eq "Kapitel 16: View bevarar gammalt gränssnitt" 'Vägen hem' "SELECT title FROM quality_test_catalog WHERE id = 1;"
query "DROP VIEW quality_test_catalog;"
query "DROP TABLE quality_test_products;"

# Kapitel 20: START TRANSACTION, COMMIT och ROLLBACK körs i varsin MySQL-session.
# Observera att en separat query() öppnar en NY anslutning; håll transaktionsstegen ihop.
assert_eq "Kapitel 20: ROLLBACK återställer lagret" 12 "START TRANSACTION; UPDATE products SET stock = stock - 2 WHERE id = 1 AND stock >= 2; ROLLBACK; SELECT stock FROM products WHERE id = 1;"
assert_eq "Kapitel 20: COMMIT bevarar ändring" 10 "START TRANSACTION; UPDATE products SET stock = stock - 2 WHERE id = 1 AND stock >= 2; COMMIT; SELECT stock FROM products WHERE id = 1;"
query "UPDATE products SET stock = 12 WHERE id = 1;"
assert_eq "Kapitel 20: grundsaldo återställt" 12 "SELECT stock FROM products WHERE id = 1;"

# Kapitel 21: indexets existens testas, INTE optimerarens val av exekveringsplan.
query "CREATE INDEX idx_quality_products_title ON products (title);"
query "CREATE INDEX idx_quality_products_type_price ON products (product_type_id, price);"
assert_eq "Kapitel 21: titelindex finns" 1 "SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'products' AND index_name = 'idx_quality_products_title';"
assert_eq "Kapitel 21: sammansatt index har två kolumner" 2 "SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'products' AND index_name = 'idx_quality_products_type_price';"
query "EXPLAIN SELECT id, title, price FROM products WHERE title = 'Vägen hem';" >/dev/null
query "DROP INDEX idx_quality_products_title ON products;"
# Behåll stödindexet för FOREIGN KEY; hela testdatabasen återställs vid nästa körning.
# InnoDB kan ha valt detta sammansatta index som stöd för products.product_type_id.

# Kapitel 25: originalfilen har en historisk orderrad; visa och testa båda scenarierna.
assert_eq "Kapitel 25: beställt värde ur grunddata" 249.00 "SELECT SUM(quantity * unit_price) FROM order_items;"
assert_eq "Kapitel 25: ordermånad" '2026-10' "SELECT DATE_FORMAT(o.ordered_at, '%Y-%m') FROM orders o JOIN order_items oi ON oi.order_id=o.id GROUP BY DATE_FORMAT(o.ordered_at, '%Y-%m');"
query "CREATE VIEW quality_test_product_sales AS SELECT product_id, SUM(quantity) AS units_ordered, SUM(quantity * unit_price) AS ordered_value FROM order_items GROUP BY product_id;"
assert_eq "Kapitel 25: analys-View och historiskt pris" 'Vinterljus' "SELECT p.title FROM quality_test_product_sales s JOIN products p ON p.id=s.product_id WHERE s.ordered_value=249.00;"
query "DROP VIEW quality_test_product_sales;"
# Kapiteltexten har tre illustrativa orderrader – håll dem åtskilda från grundfilens enda.
query "CREATE TABLE quality_test_order_items AS SELECT * FROM order_items WHERE 1=0;"
query "INSERT INTO quality_test_order_items (id,order_id,product_id,quantity,unit_price) VALUES (1001,101,1,2,200.00),(1002,102,4,1,120.00),(1003,102,5,2,180.00);"
assert_eq "Kapitel 25: illustrativa orderrader" '101,102' "SELECT GROUP_CONCAT(order_id ORDER BY order_id) FROM (SELECT order_id,SUM(quantity*unit_price) AS amount FROM quality_test_order_items GROUP BY order_id) x;"
assert_eq "Kapitel 25: order 102 summa" 480.00 "SELECT SUM(quantity*unit_price) FROM quality_test_order_items WHERE order_id=102;"
query "DROP TABLE quality_test_order_items;"

# Kapitel 26: JSON-kolumn och genererad kolumn på isolerad kopia.
query "CREATE TABLE quality_test_json_products LIKE products;"
query "INSERT INTO quality_test_json_products SELECT * FROM products;"
query "ALTER TABLE quality_test_json_products ADD COLUMN metadata JSON;"
query 'UPDATE quality_test_json_products SET metadata = JSON_OBJECT("language","sv","pages",284,"series","Vägarna") WHERE id = 1;'
assert_eq "Kapitel 26: JSON_EXTRACT och JSON_UNQUOTE" 'sv' "SELECT JSON_UNQUOTE(JSON_EXTRACT(metadata, '$.language')) FROM quality_test_json_products WHERE id=1;"
assert_eq "Kapitel 26: filtrering på JSON" 1 "SELECT COUNT(*) FROM quality_test_json_products WHERE JSON_UNQUOTE(JSON_EXTRACT(metadata, '$.language')) = 'sv';"
query "UPDATE quality_test_json_products SET metadata=JSON_SET(metadata, '$.pages', 286) WHERE id=1;"
assert_eq "Kapitel 26: JSON_SET ändrar sidantal" 286 "SELECT JSON_UNQUOTE(JSON_EXTRACT(metadata, '$.pages')) FROM quality_test_json_products WHERE id=1;"
query "ALTER TABLE quality_test_json_products ADD COLUMN language_code VARCHAR(10) GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(metadata, '$.language'))) STORED;"
query "CREATE INDEX idx_quality_json_language ON quality_test_json_products (language_code);"
assert_eq "Kapitel 26: genererad kolumn och index" 1 "SELECT COUNT(*) FROM quality_test_json_products WHERE language_code='sv';"
query "DROP TABLE quality_test_json_products;"

# Kapitel 27: kontrollera både plana linjer och geografiska punkter (WGS 84).
assert_eq "Kapitel 27: rak linje har längd fyra" 4 "SELECT ST_Length(ST_GeomFromText('LINESTRING(0 0, 4 0)'));"
assert_eq "Kapitel 27: omväg är längre" 1 "SELECT ST_Length(ST_GeomFromText('LINESTRING(0 0, 1 2, 3 2, 4 0)')) > 6;"
query "CREATE TABLE quality_test_stores (id INTEGER PRIMARY KEY, name VARCHAR(100) NOT NULL, location POINT NOT NULL SRID 4326);"
query "INSERT INTO quality_test_stores (id,name,location) VALUES (1,'Bokhandeln Malmö',ST_GeomFromText('POINT(13.003 55.605)',4326,'axis-order=long-lat'));"
assert_eq "Kapitel 27: punktens koordinatsystem" 4326 "SELECT ST_SRID(location) FROM quality_test_stores WHERE id=1;"
assert_eq "Kapitel 27: butik på sökpunkt ger noll meter" 0 "SELECT ST_Distance_Sphere(location,ST_GeomFromText('POINT(13.003 55.605)',4326,'axis-order=long-lat')) FROM quality_test_stores WHERE id=1;"
assert_eq "Kapitel 27: butik inom tio kilometer" 1 "SELECT COUNT(*) FROM quality_test_stores WHERE ST_Distance_Sphere(location,ST_GeomFromText('POINT(13.003 55.605)',4326,'axis-order=long-lat')) <= 10000;"
query "CREATE SPATIAL INDEX idx_quality_stores_location ON quality_test_stores (location);"
assert_eq "Kapitel 27: spatialt index skapas" 1 "SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='quality_test_stores' AND index_name='idx_quality_stores_location';"
query "DROP TABLE quality_test_stores;"
# Blockvis verifiering av tidiga kapitel, med samma SQL-uttryck som i texten.
# Kapitel 3: SQL-introduktion. Syntaxmallen och kommentarexemplet testas inte.
assert_eq "Kapitel 3: namn från customers" 5 "SELECT COUNT(*) FROM (SELECT name FROM customers) AS q;"
assert_eq "Kapitel 3: WHERE id 2" 'Olof' "SELECT name FROM customers WHERE id = 2;"
assert_eq "Kapitel 3: alias" 'Benjamin' "SELECT customer_name FROM (SELECT name AS customer_name FROM customers) q WHERE customer_name='Benjamin';"
assert_eq "Kapitel 3: koppling via WHERE" 4 "SELECT COUNT(*) FROM customers AS c, addresses AS a WHERE a.customer_id = c.id;"

# Kapitel 5: filtrering, kombination av villkor och NULL.
assert_eq "Kapitel 5: födda 1980-1999" 2 "SELECT COUNT(*) FROM customers WHERE birthday >= '1980-01-01' AND birthday < '2000-01-01';"
assert_eq "Kapitel 5: BETWEEN ger samma urval" 2 "SELECT COUNT(*) FROM customers WHERE birthday BETWEEN '1980-01-01' AND '1999-12-31';"
assert_eq "Kapitel 5: IN" 3 "SELECT COUNT(*) FROM customers WHERE id IN (1,3,5);"
assert_eq "Kapitel 5: LIKE B" 2 "SELECT COUNT(*) FROM customers WHERE name LIKE 'B%';"
assert_eq "Kapitel 5: LIMIT tre" '1,2,3' "SELECT GROUP_CONCAT(id ORDER BY id) FROM (SELECT id FROM customers ORDER BY id LIMIT 3) q;"
assert_eq "Kapitel 5: saknad gatuadress" 1 "SELECT COUNT(*) FROM addresses WHERE street IS NULL;"
assert_eq "Kapitel 5: operatorprioritet AND före OR" 1 "SELECT COUNT(*) FROM customers WHERE name = 'Anna' OR name = 'Olof' AND id > 2;"
assert_eq "Kapitel 5: parenteser förändrar urval" 1 "SELECT COUNT(*) FROM customers WHERE (name = 'Anna' OR name = 'Olof') AND id > 2;"

# Kapitel 6: beräkningar, CASE och funktioner.
assert_eq "Kapitel 6: ROUND" 12.35 "SELECT ROUND(12.345,2);"
assert_eq "Kapitel 6: CONCAT" 'Hej Anna' "SELECT CONCAT('Hej',' ','Anna');"
assert_eq "Kapitel 6: UPPER" 'BOKHANDEL' "SELECT UPPER('bokhandel');"
assert_eq "Kapitel 6: REPLACE" 'Din bok' "SELECT REPLACE('Min bok','Min','Din');"
assert_eq "Kapitel 6: CASE slut i lager" 'Den blå staden' "SELECT title FROM products WHERE CASE WHEN stock > 0 THEN 'I lager' ELSE 'Slut i lager' END='Slut i lager';"
assert_eq "Kapitel 6: COALESCE" 100 "SELECT COALESCE(NULL,100);"

# Kapitel 7: statiska datumintervall och skillnader; rörliga datum testas ej mot fast svar.
assert_eq "Kapitel 7: kunder födda efter 1980" 3 "SELECT COUNT(*) FROM customers WHERE birthday > '1980-01-01';"
assert_eq "Kapitel 7: 1990-talet med BETWEEN" 'Anaïs' "SELECT name FROM customers WHERE birthday BETWEEN '1990-01-01' AND '1999-12-31';"
assert_eq "Kapitel 7: 1990-talet halvöppet" 'Anaïs' "SELECT name FROM customers WHERE birthday >= '1990-01-01' AND birthday < '2000-01-01';"
assert_eq "Kapitel 7: halvöppet orderintervall" 1 "SELECT COUNT(*) FROM orders WHERE ordered_at >= '2026-10-01' AND ordered_at < '2026-11-01';"
assert_eq "Kapitel 7: DATEDIFF" 10 "SELECT DATEDIFF('2026-10-11','2026-10-01');"

# Blockvis verifiering kapitel 8–14. Dessa påståenden jämför exakta resultat.
assert_eq "Kapitel 8: antal tillgängliga produkter" 4 "SELECT COUNT(*) FROM products WHERE stock > 0;"
assert_eq "Kapitel 8: min- och maxpris" 
assert_rejected "CHECK stoppar negativa priser" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',-10,1,1);"
assert_rejected "FOREIGN KEY stoppar okända produkttyper" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',10,1,999);"
assert_rejected "Primärnyckel stoppar dubbla id" "INSERT INTO customers(id,name) VALUES (1,'Dublett');"
assert_eq "Grunddata oförändrade" 5 "SELECT COUNT(*) FROM products;"

echo "Alla MySQL-integrationstester godkända."
120.00\t249.00' "SELECT MIN(price), MAX(price) FROM products;"
assert_eq "Kapitel 8: produkter per typ och lagersaldo" 
assert_rejected "CHECK stoppar negativa priser" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',-10,1,1);"
assert_rejected "FOREIGN KEY stoppar okända produkttyper" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',10,1,999);"
assert_rejected "Primärnyckel stoppar dubbla id" "INSERT INTO customers(id,name) VALUES (1,'Dublett');"
assert_eq "Grunddata oförändrade" 5 "SELECT COUNT(*) FROM products;"

echo "Alla MySQL-integrationstester godkända."
1\t3\t16\n2\t2\t34' "SELECT product_type_id, COUNT(*), SUM(stock) FROM products GROUP BY product_type_id ORDER BY product_type_id;"
assert_eq "Kapitel 8: HAVING fler än två" 1 "SELECT product_type_id FROM products GROUP BY product_type_id HAVING COUNT(*) > 2;"
assert_eq "Kapitel 8: WHERE kombinerat med HAVING" 1 "SELECT product_type_id FROM products WHERE price >= 150 GROUP BY product_type_id HAVING COUNT(*) >= 2 ORDER BY product_type_id;"

assert_eq "Kapitel 9: INNER JOIN kunder och adresser" 4 "SELECT COUNT(*) FROM customers c INNER JOIN addresses a ON a.customer_id=c.id;"
assert_eq "Kapitel 9: LEFT JOIN bevarar kunder utan adress" 6 "SELECT COUNT(*) FROM customers c LEFT JOIN addresses a ON a.customer_id=c.id;"
assert_eq "Kapitel 9: CROSS JOIN ger 20 rader" 20 "SELECT COUNT(*) FROM customers c CROSS JOIN addresses a;"
assert_eq "Kapitel 9: WHERE på vänsteransluten tabell" 2 "SELECT COUNT(*) FROM customers c LEFT JOIN addresses a ON a.customer_id=c.id WHERE a.city='Storfors';"
assert_eq "Kapitel 9: filter i ON bevarar kunder" 5 "SELECT COUNT(*) FROM customers c LEFT JOIN addresses a ON a.customer_id=c.id AND a.city='Storfors';"
assert_eq "Kapitel 9: order och orderrad med kund och produkt" 1 "SELECT COUNT(*) FROM orders o JOIN customers c ON c.id=o.customer_id JOIN order_items oi ON oi.order_id=o.id JOIN products p ON p.id=oi.product_id;"

assert_eq "Kapitel 10: EXISTS adresser i Storfors" 'Benjamin,Olof' "SELECT GROUP_CONCAT(c.name ORDER BY c.id) FROM customers c WHERE EXISTS (SELECT 1 FROM addresses a WHERE a.customer_id=c.id AND a.city='Storfors');"
assert_eq "Kapitel 10: NOT EXISTS kunder utan adresser" 'Beatrice,Anna' "SELECT GROUP_CONCAT(c.name ORDER BY c.id) FROM customers c WHERE NOT EXISTS (SELECT 1 FROM addresses a WHERE a.customer_id=c.id);"
assert_eq "Kapitel 10: underfråga per produkttyp" 'Vägen hem,Vinterljus,Mellan raderna' "SELECT GROUP_CONCAT(p.title ORDER BY p.id) FROM products p WHERE p.price > (SELECT AVG(p2.price) FROM products p2 WHERE p2.product_type_id=p.product_type_id);"

# Kapitel 11: separata illustrationsadresser skapas tidigare i detta skript;
# här kontrollerar vi ytterligare en grunddatabasspecifik resultatsammansättning.
assert_eq "Kapitel 11: grunddata UNION Storfors/Malmö" '1,2,3' "SELECT GROUP_CONCAT(customer_id ORDER BY customer_id) FROM (SELECT customer_id FROM addresses WHERE city='Storfors' UNION SELECT customer_id FROM addresses WHERE city='Malmö') s;"

# Kapitel 12–14: struktur- och nyckelregler på kopierat schema.
query "CREATE TABLE quality_test_model_types (id INTEGER PRIMARY KEY, name VARCHAR(100) NOT NULL UNIQUE);"
query "CREATE TABLE quality_test_model_products (id INTEGER PRIMARY KEY, title VARCHAR(200) NOT NULL, price DECIMAL(10,2) NOT NULL, stock INTEGER NOT NULL DEFAULT 0, product_type_id INTEGER, CHECK(price >= 0), CHECK(stock >= 0), FOREIGN KEY(product_type_id) REFERENCES quality_test_model_types(id));"
query "INSERT INTO quality_test_model_types VALUES (1,'Roman');"
query "INSERT INTO quality_test_model_products(id,title,price,product_type_id) VALUES (1,'Exempel',120,1);"
assert_eq "Kapitel 12: DEFAULT på lager" 0 "SELECT stock FROM quality_test_model_products WHERE id=1;"
assert_rejected "Kapitel 12: CHECK förhindrar negativt lager" "INSERT INTO quality_test_model_products(id,title,price,stock,product_type_id) VALUES (2,'Fel',120,-1,1);"
assert_rejected "Kapitel 13: FOREIGN KEY förhindrar okänd typ" "INSERT INTO quality_test_model_products(id,title,price,product_type_id) VALUES (2,'Fel',120,99);"
assert_rejected "Kapitel 13: UNIQUE förhindrar dubbla typnamn" "INSERT INTO quality_test_model_types VALUES (2,'Roman');"
query "DROP TABLE quality_test_model_products;"
query "DROP TABLE quality_test_model_types;"

query "CREATE TABLE quality_test_author_links (product_id INTEGER NOT NULL, author_id INTEGER NOT NULL, author_order INTEGER NOT NULL, PRIMARY KEY(product_id,author_id), UNIQUE(product_id,author_order), CHECK(author_order>0), FOREIGN KEY(product_id) REFERENCES products(id), FOREIGN KEY(author_id) REFERENCES authors(id));"
query "INSERT INTO quality_test_author_links VALUES (1,1,1);"
assert_rejected "Kapitel 14: två författare får ej samma ordning på produkt" "INSERT INTO quality_test_author_links VALUES (1,2,1);"
assert_rejected "Kapitel 14: författarordning måste vara positiv" "INSERT INTO quality_test_author_links VALUES (2,2,0);"
query "DROP TABLE quality_test_author_links;"

# Integritetsregler testas med rader som inte ska kunna läggas in.
assert_rejected "CHECK stoppar negativa priser" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',-10,1,1);"
assert_rejected "FOREIGN KEY stoppar okända produkttyper" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',10,1,999);"
assert_rejected "Primärnyckel stoppar dubbla id" "INSERT INTO customers(id,name) VALUES (1,'Dublett');"
assert_eq "Grunddata oförändrade" 5 "SELECT COUNT(*) FROM products;"

echo "Alla MySQL-integrationstester godkända."

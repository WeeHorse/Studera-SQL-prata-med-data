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

# Fortsatt kapitelkontroll: subqueries, Views och fönsterfunktioner.
assert_eq "Kapitel 10: över genomsnittspris" 
assert_rejected "CHECK stoppar negativa priser" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',-10,1,1);"
assert_rejected "FOREIGN KEY stoppar okända produkttyper" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',10,1,999);"
assert_rejected "Primärnyckel stoppar dubbla id" "INSERT INTO customers(id,name) VALUES (1,'Dublett');"
assert_eq "Grunddata oförändrade" 5 "SELECT COUNT(*) FROM products;"

echo "Alla MySQL-integrationstester godkända."
Vägen hem\\nVinterljus' "SELECT title FROM products WHERE price > (SELECT AVG(price) FROM products) ORDER BY id;"
assert_eq "Kapitel 19: ROW_NUMBER efter pris" 
assert_rejected "CHECK stoppar negativa priser" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',-10,1,1);"
assert_rejected "FOREIGN KEY stoppar okända produkttyper" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',10,1,999);"
assert_rejected "Primärnyckel stoppar dubbla id" "INSERT INTO customers(id,name) VALUES (1,'Dublett');"
assert_eq "Grunddata oförändrade" 5 "SELECT COUNT(*) FROM products;"

echo "Alla MySQL-integrationstester godkända."
Vinterljus\\t1\\nVägen hem\\t2\\nMellan raderna\\t3\\nDen blå staden\\t4\\nSmå historier\\t5' "SELECT title, ROW_NUMBER() OVER (ORDER BY price DESC, id) AS price_position FROM products ORDER BY price_position;"
assert_eq "Kapitel 19: genomsnitt per produkttyp" 
assert_rejected "CHECK stoppar negativa priser" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',-10,1,1);"
assert_rejected "FOREIGN KEY stoppar okända produkttyper" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',10,1,999);"
assert_rejected "Primärnyckel stoppar dubbla id" "INSERT INTO customers(id,name) VALUES (1,'Dublett');"
assert_eq "Grunddata oförändrade" 5 "SELECT COUNT(*) FROM products;"

echo "Alla MySQL-integrationstester godkända."
1\\t199.666667\\n2\\t150.000000' "SELECT product_type_id, AVG(price) FROM products GROUP BY product_type_id ORDER BY product_type_id;"
query "CREATE VIEW quality_test_product_overview AS SELECT p.id, p.title, t.name AS product_type FROM products AS p JOIN product_types AS t ON t.id = p.product_type_id;"
assert_eq "Kapitel 17: View med relation" 
assert_rejected "CHECK stoppar negativa priser" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',-10,1,1);"
assert_rejected "FOREIGN KEY stoppar okända produkttyper" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',10,1,999);"
assert_rejected "Primärnyckel stoppar dubbla id" "INSERT INTO customers(id,name) VALUES (1,'Dublett');"
assert_eq "Grunddata oförändrade" 5 "SELECT COUNT(*) FROM products;"

echo "Alla MySQL-integrationstester godkända."
Roman\\t3\\nNovellsamling\\t2' "SELECT product_type, COUNT(*) FROM quality_test_product_overview GROUP BY product_type ORDER BY COUNT(*) DESC;"
query "DROP VIEW quality_test_product_overview;"

# Kapitel 11 presenterar tre extra adresser som INTE ingår i grundfilen.
# Lägg dem i en separat testtabell, så att bokens nedladdningsbara data lämnas orörda.
query "CREATE TABLE quality_test_addresses AS SELECT * FROM addresses;"
query "INSERT INTO quality_test_addresses (id, customer_id, street, postal_code, city) VALUES (5,1,'Strandgatan 7',NULL,'Malmö'), (6,4,'Torget 3',NULL,'Malmö'), (7,5,'Skolgatan 8',NULL,'Storfors');"
assert_eq "Kapitel 11: UNION" '1,2,3,4,5' "SELECT GROUP_CONCAT(customer_id ORDER BY customer_id) FROM (SELECT customer_id FROM quality_test_addresses WHERE city = 'Storfors' UNION SELECT customer_id FROM quality_test_addresses WHERE city = 'Malmö') AS ids;"
assert_eq "Kapitel 11: UNION ALL behåller sex rader" 6 "SELECT COUNT(*) FROM (SELECT customer_id FROM quality_test_addresses WHERE city = 'Storfors' UNION ALL SELECT customer_id FROM quality_test_addresses WHERE city = 'Malmö') AS ids;"
assert_eq "Kapitel 11: INTERSECT" 1 "SELECT GROUP_CONCAT(customer_id ORDER BY customer_id) FROM (SELECT customer_id FROM quality_test_addresses WHERE city = 'Storfors' INTERSECT SELECT customer_id FROM quality_test_addresses WHERE city = 'Malmö') AS ids;"
assert_eq "Kapitel 11: EXCEPT" '2,5' "SELECT GROUP_CONCAT(customer_id ORDER BY customer_id) FROM (SELECT customer_id FROM quality_test_addresses WHERE city = 'Storfors' EXCEPT SELECT customer_id FROM quality_test_addresses WHERE city = 'Malmö') AS ids;"
query "DROP TABLE quality_test_addresses;"

# Integritetsregler testas med rader som inte ska kunna läggas in.
assert_rejected "CHECK stoppar negativa priser" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',-10,1,1);"
assert_rejected "FOREIGN KEY stoppar okända produkttyper" "INSERT INTO products(id,title,price,stock,product_type_id) VALUES (99,'Otillåten',10,1,999);"
assert_rejected "Primärnyckel stoppar dubbla id" "INSERT INTO customers(id,name) VALUES (1,'Dublett');"
assert_eq "Grunddata oförändrade" 5 "SELECT COUNT(*) FROM products;"

echo "Alla MySQL-integrationstester godkända."

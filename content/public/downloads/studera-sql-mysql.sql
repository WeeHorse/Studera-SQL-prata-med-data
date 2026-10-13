-- Studera SQL – prata med data
-- Bokhandelns gemensamma exempeldatabas (MySQL 8.0.16+)
-- Kör på en MySQL-server med rättigheter att skapa databaser och tabeller.
-- Skriptet är avsett att köras EN GÅNG i en tom bokdatabas.
-- Tabellerna och grundvärdena motsvarar den återkommande modellen i boken.
-- Utvidgade kapitelexempel (t.ex. categories, reservations, stores, JSON)
-- skapas inte här; de presenteras separat i respektive kapitel.
-- Ändringssatser i kapitlen är fristående illustrationer: kör dem inte
-- alla i följd om du vill bevara startvärdena.

CREATE DATABASE IF NOT EXISTS studera_sql_bokhandel
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE studera_sql_bokhandel;

CREATE TABLE customers (
    id INTEGER PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(200),
    birthday DATE
);

CREATE TABLE addresses (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    street VARCHAR(200),
    postal_code VARCHAR(20),
    city VARCHAR(100),
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE product_types (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    product_type_id INTEGER,
    CHECK (price >= 0),
    CHECK (stock >= 0),
    FOREIGN KEY (product_type_id) REFERENCES product_types(id)
);

CREATE TABLE authors (
    id INTEGER PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(200)
);

CREATE TABLE product_authors (
    product_id INTEGER NOT NULL,
    author_id INTEGER NOT NULL,
    PRIMARY KEY (product_id, author_id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (author_id) REFERENCES authors(id)
);

CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    ordered_at DATETIME NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE order_items (
    id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    CHECK (quantity > 0),
    CHECK (unit_price >= 0),
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

INSERT INTO customers (id, name, email, birthday) VALUES
    (1, 'Benjamin', 'benjamin@example.com', '1968-04-12'),
    (2, 'Olof', 'olof@example.com', '1982-09-03'),
    (3, 'Anaïs', 'anais@example.com', '1995-06-21'),
    (4, 'Beatrice', 'beatrice@example.com', '2000-02-15'),
    (5, 'Anna', 'anna@example.com', '1975-11-08');

INSERT INTO addresses (id, customer_id, street, postal_code, city) VALUES
    (1, 1, 'Hemmagatan 1', '124 56', 'Hemmavan'),
    (2, 1, 'Storgatan 4', '154 32', 'Storfors'),
    (3, 2, 'Parkvägen 2', '154 32', 'Storfors'),
    (4, 3, NULL, NULL, 'Malmö');

INSERT INTO product_types (id, name) VALUES
    (1, 'Roman'),
    (2, 'Novellsamling');

INSERT INTO products (id, title, price, stock, product_type_id) VALUES
    (1, 'Vägen hem', 200.00, 12, 1),
    (2, 'Den blå staden', 150.00, 0, 1),
    (3, 'Vinterljus', 249.00, 4, 1),
    (4, 'Små historier', 120.00, 25, 2),
    (5, 'Mellan raderna', 180.00, 9, 2);

INSERT INTO authors (id, name, email) VALUES
    (1, 'Anna Svensson', 'anna@authors.example'),
    (2, 'Erik Lund', 'erik@authors.example');

INSERT INTO product_authors (product_id, author_id) VALUES
    (1, 1),
    (2, 2),
    (3, 1),
    (4, 2);

-- Ett litet kompletterande orderunderlag för kapitel om JOIN,
-- transaktioner och analys. Dessa orderrader är fiktiva.
-- Produkternas stock-värden är bokens ursprungliga startvärden,
-- inte ett lager som räknats ned av nedanstående historiska ordrar.
INSERT INTO orders (id, customer_id, ordered_at) VALUES
    (101, 1, '2026-10-10 10:30:00');

INSERT INTO order_items (id, order_id, product_id, quantity, unit_price) VALUES
    (1001, 101, 3, 1, 249.00);

-- Kontrollera grunddata:
-- SELECT COUNT(*) FROM customers; -- 5
-- SELECT COUNT(*) FROM products;  -- 5
-- SELECT SUM(stock) FROM products; -- 50

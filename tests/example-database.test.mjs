import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const script = readFileSync('content/public/downloads/studera-sql-mysql.sql', 'utf8');
const appendix = readFileSync('content/sv/bilaga-exempeldatabas.md', 'utf8');
const printed = readFileSync('publishing/print/appendix-database.md', 'utf8');
const builder = readFileSync('scripts/book-content.mjs', 'utf8');

test('MySQL-underlaget skapar alla åtta grundtabeller', () => {
  const tables = ['customers', 'addresses', 'product_types', 'products',
    'authors', 'product_authors', 'orders', 'order_items'];
  for (const name of tables) {
    assert.match(script, new RegExp('CREATE TABLE ' + name + '\\s*\\('));
  }
});

test('grunddata har bokens fem kunder och fem produkter', () => {
  assert.match(script, /\(3, 'Anaïs', 'anais@example.com'/);
  assert.match(script, /\(5, 'Mellan raderna', 180\.00, 9, 2\)/);
  assert.match(script, /\(4, 3, NULL, NULL, 'Malmö'\)/);
});

test('exempelbilagan finns på webb och i tryck', () => {
  assert.match(appendix, /studera-sql-mysql\.sql/);
  assert.match(printed, /\/sv\/bilaga-exempeldatabas\.html/);
  assert.match(builder, /appendix-database\.md/);
});

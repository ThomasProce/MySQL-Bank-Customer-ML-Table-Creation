
-- Inspect the database

SELECT * FROM cliente LIMIT 10;
SELECT * FROM conto LIMIT 10;
SELECT * FROM tipo_conto LIMIT 10;
SELECT * FROM tipo_transazione LIMIT 10;
SELECT * FROM transazioni LIMIT 10;

/* 

Checking the min and max values we could see a little discrepancy.
min value from id_cliente from cliente table is 0,
min value from id_cliente from conto table is 1.

POSSIBILITIES:
1) We have a little inconsistency in the database.
2) Giada Romano (id_cliente = 0 in cliente table) didn't have an account

*/

SELECT
    MIN(id_cliente) AS min_id_cliente,
    MAX(id_cliente) AS max_id_cliente
FROM cliente;

SELECT
    MIN(id_cliente) AS min_id_conto,
    MAX(id_cliente) AS max_id_conto
FROM conto;
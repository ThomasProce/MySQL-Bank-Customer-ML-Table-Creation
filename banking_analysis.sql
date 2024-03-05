
-- Inspect the database

SELECT * FROM cliente LIMIT 10;
SELECT * FROM conto LIMIT 10;
SELECT * FROM tipo_conto LIMIT 10;
SELECT * FROM tipo_transazione LIMIT 20;
SELECT * FROM transazioni LIMIT 10;

/* 

Checking the min and max values we could see a little discrepancy.
min value from id_cliente from cliente table is 0,
min value from id_cliente from conto table is 1.

POSSIBILITIES:
1) We have a little inconsistency in the database.
2) Giada Romano (id_cliente = 0 in cliente table) didn't have an account

*/


WITH compare_id AS (
    SELECT
        MIN(id_cliente) AS min_id_cliente,
        MAX(id_cliente) AS max_id_cliente
    FROM cliente
),
conto_id AS (
    SELECT
        MIN(id_cliente) AS min_id_cliente_conto,
        MAX(id_cliente) AS max_id_cliente_conto
    FROM conto
)
SELECT * FROM compare_id, conto_id;

-- check for the client with id = 0

SELECT * FROM cliente WHERE id_cliente = '0';

-- As expected the client with id = 0 doesn't have an account
SELECT id_cliente,id_tipo_conto
FROM conto
WHERE id_cliente = '0';

/*
From the query below we could see that are present several entries
wich seems didn't have an account.
There's no inconsistency in the database.
simply since they do not have an account
and therefore their id does not appear (obviously) in the table for the account
*/

WITH no_accounts AS (
    SELECT cliente.*, 
        CASE WHEN conto.id_conto IS NULL THEN 'No Account' ELSE conto.id_conto END AS Account
    FROM cliente
    LEFT JOIN conto ON cliente.id_cliente = conto.id_cliente
    WHERE conto.id_cliente IS NULL
)
SELECT * FROM no_accounts;

-- No duplicates are present

WITH check_duplicates AS (
    SELECT id_cliente, COUNT(*) AS num_duplicates
    FROM cliente
    GROUP BY id_cliente
    HAVING COUNT(*) > 1
),
check_duplicates_conto AS (
    SELECT id_cliente, COUNT(*) AS num_duplicates
    FROM conto
    GROUP BY id_cliente
    HAVING COUNT(*) > 1
)
SELECT * FROM check_duplicates;

/* 

Create a new table with new values:
- Age
- Number of outgoing transactions on all accounts
- Number of incoming transactions on all accounts
- Amount transacted outgoing on all accounts
- Amount transacted inbound on all accounts
- Total number of accounts held
- Number of accounts held by type (one indicator per type)
- Number of outgoing transactions by type (one indicator per type)
- Number of incoming transactions by type (one indicator per type)
- Amount transacted outbound by account type (one indicator per type)
- Amount transacted inbound by account type (one indicator per type)

*/

CREATE TABLE Customer_Account(
    id_customer INT NOT NULL,
    customer_name CHAR NOT NULL,
    customer_surname CHAR NOT NULL,
    customer_age INT NOT NULL,
    Num_transactions_out INT NOT NULL,
    Num_transactions_in INT NOT NULL,
    Amount_transacted_out FLOAT NOT NULL,
    Amount_transacted_in FLOAT NOT NULL,
    Num_accounts_held INT NOT NULL,
    Num_transactions_out_per_type INT NOT NULL,
    Num_transactions_in_per_type INT NOT NULL,
    Amount_transacted_out_per_type FLOAT NOT NULL,
    Amount_transacted_in_per_type FLOAT NOT NULL,
    Amount_transacted_out_per_account_type FLOAT NOT NULL,
    Amount_transacted_in_per_account_type FLOAT NOT NULL
);
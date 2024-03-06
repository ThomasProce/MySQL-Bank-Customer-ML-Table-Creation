
-- Inspect the database

SELECT * FROM cliente;
SELECT * FROM conto;
SELECT * FROM tipo_conto;
SELECT * FROM tipo_transazione;
SELECT * FROM transazioni;

SELECT 
    'cliente' AS table_name, COUNT(*) AS num_obs 
FROM 
    cliente
UNION ALL
SELECT 
    'conto' AS table_name, COUNT(*) AS num_obs 
FROM 
    conto
UNION ALL
SELECT 
    'tipo_conto' AS table_name, COUNT(*) AS num_obs 
FROM 
    tipo_conto
UNION ALL
SELECT 
    'tipo_transazione' AS table_name, COUNT(*) AS num_obs 
FROM 
    tipo_transazione;

/* 
Checking the min and max values we could see a little discrepancy.
min value from id_cliente from cliente table is 0,
min value from id_cliente from conto table is 1.

POSSIBILITIES:
1) We have a little inconsistency in the database.
2) Giada Romano (id_cliente = 0 in cliente table) didn't have an account
*/

-- find the minimum and maximum values of 'id_cliente' in the 'cliente' table
SELECT
    MIN(id_cliente) AS min_id_cliente,
    MAX(id_cliente) AS max_id_cliente
FROM cliente;

-- find the minimum and maximum values of 'id_cliente' in the 'conto' table
SELECT
    MIN(id_cliente) AS min_id_cliente_conto,
    MAX(id_cliente) AS max_id_cliente_conto
FROM conto;


-- check for the client with id = 0

SELECT * FROM cliente WHERE id_cliente = '0';

-- As expected the client with id = 0 doesn't have an account
SELECT id_cliente,id_tipo_conto
FROM conto
WHERE id_cliente = '0';

/* 
From the query below we could see that there are several entries
which seem to not have an account.
There's no inconsistency in the database.
Simply, since they do not have an account,
their id does not appear (obviously) in the account table.
*/

SELECT cliente.*, 'No Account' AS Account
FROM cliente
WHERE NOT EXISTS (
    SELECT 1
    FROM conto
    WHERE cliente.id_cliente = conto.id_cliente
);


-- No duplicates are present

-- check for duplicates in the 'cliente' table based on 'id_cliente'
WITH check_duplicates AS (
    SELECT id_cliente, COUNT(*) AS num_duplicates
    FROM cliente
    GROUP BY id_cliente
    HAVING COUNT(*) > 1
),

-- check for duplicates in the 'conto' table based on 'id_cliente'
check_duplicates_conto AS (
    SELECT id_cliente, COUNT(*) AS num_duplicates
    FROM conto
    GROUP BY id_cliente
    HAVING COUNT(*) > 1
)
SELECT * FROM check_duplicates;




/* 

CREATE THE CUSTOMERS INFO TABLE WHERE STORE ALL INFORMATIONS ABOUT CUSTOMERS
STARTING FROM:
- ID
- NAME
- SURNAME
- AGE 

*/

CREATE TABLE customer_info AS
SELECT 
    id_cliente AS id_customer,
    nome AS name,
    cognome AS surname,
    EXTRACT(YEAR FROM CURRENT_DATE()) - EXTRACT(YEAR FROM data_nascita) AS age
FROM cliente;

/*

ADD NUMBER OF TOTAL ACCOUNT HELD BY EACH CUSTOMER

*/

ALTER TABLE customer_info
ADD COLUMN num_accounts_held INT;
-- Update the num_accounts_held column with the count of accounts held by each customer using a join
UPDATE customer_info ci
SET num_accounts_held = (
    SELECT COUNT(*)
    FROM conto c
    WHERE c.id_cliente = ci.id_customer
);

/*

ADD THE TOTAL EXPENSES FOR EACH CUSTOMER

*/

-- add the column for the number of transactions outgoing
ALTER TABLE customer_info
ADD COLUMN total_trans_out DECIMAL(10, 2); 

-- update the column with the sum of transactions outgoing
UPDATE customer_info ci
SET total_trans_out = (
    SELECT COALESCE(SUM(t.importo), 0)
    FROM transazioni t
    JOIN conto c ON t.id_conto = c.id_conto
    WHERE c.id_cliente = ci.id_customer
    AND t.id_tipo_trans IN ('3', '4', '5', '6', '7')
);

/*

ADD THE TOTAL INCOME FOR EACH CUSTOMER

*/

-- Add a column for transactions ingoing
ALTER TABLE customer_info
ADD COLUMN total_trans_in DECIMAL(10, 2);

-- Update the column with the sum of transactions ingoing
UPDATE customer_info ci
SET total_trans_in = (
    SELECT COALESCE(SUM(t.importo), 0)
    FROM transazioni t
    JOIN conto c ON t.id_conto = c.id_conto
    WHERE c.id_cliente = ci.id_customer
    AND t.id_tipo_trans IN ('0', '1', '2')
);

/*

ADD THE TOTAL NUMBER FOR INGOING TRANSACTIONS

*/

-- add a column to calculate the number of trans in
ALTER TABLE customer_info
ADD COLUMN num_trans_in INT;

-- update the column with the sum of transactions ingoing
UPDATE customer_info ci
SET num_trans_in = (
    SELECT COUNT(*)
    FROM transazioni t
    JOIN conto c ON t.id_conto = c.id_conto
    WHERE c.id_cliente = ci.id_customer
    AND t.id_tipo_trans IN ('0', '1', '2')
);

/*

ADD THE TOTAL NUMBER FOR OUTGOING TRANSACTIONS

*/


-- add a column to calculate the number of trans out
ALTER TABLE customer_info
ADD COLUMN num_trans_out INT;

-- update the column with the sum of transactions outgoing
UPDATE customer_info ci
SET num_trans_out = (
    SELECT COUNT(*)
    FROM transazioni t
    JOIN conto c ON t.id_conto = c.id_conto
    WHERE c.id_cliente = ci.id_customer
    AND t.id_tipo_trans IN ('3', '4', '5', '6', '7')
);

/*

ADD COLUMNS TO STORE THE TYPES OF ACCOUNT HELD BY EACH CUSTOMER

*/

-- Add columns for "one-hot encoding" representation
ALTER TABLE customer_info
ADD COLUMN account_basis TINYINT(1) DEFAULT 0,
ADD COLUMN business_account TINYINT(1) DEFAULT 0,
ADD COLUMN private_account TINYINT(1) DEFAULT 0,
ADD COLUMN household_account TINYINT(1) DEFAULT 0;

-- Update and denormalize representation for each customer
UPDATE customer_info ci
LEFT JOIN (
    SELECT 
        id_cliente,
        MAX(CASE WHEN id_tipo_conto = 0 THEN 1 ELSE 0 END) AS account_basis,
        MAX(CASE WHEN id_tipo_conto = 1 THEN 1 ELSE 0 END) AS business_account,
        MAX(CASE WHEN id_tipo_conto = 2 THEN 1 ELSE 0 END) AS private_account,
        MAX(CASE WHEN id_tipo_conto = 3 THEN 1 ELSE 0 END) AS household_account
    FROM conto
    GROUP BY id_cliente
) c ON ci.id_customer = c.id_cliente
SET 
    ci.account_basis = COALESCE(c.account_basis, 0),
    ci.business_account = COALESCE(c.business_account, 0),
    ci.private_account = COALESCE(c.private_account, 0),
    ci.household_account = COALESCE(c.household_account, 0);

/*

ADD THE TOTAL NUMBER OF TRANSACTIONS FOR EACH TYPE OF PURCHASE

*/

-- Add new columns to the customer_info table
ALTER TABLE customer_info
ADD COLUMN num_amazon_purchases INT DEFAULT 0,
ADD COLUMN num_mortgage_installment INT DEFAULT 0,
ADD COLUMN num_hotel_purchases INT DEFAULT 0,
ADD COLUMN num_plane_ticket_purchases INT DEFAULT 0,
ADD COLUMN num_supermarket_purchases INT DEFAULT 0;

-- Update the values in the new columns with the counts of transactions for each customer
UPDATE customer_info ci
LEFT JOIN (
    SELECT 
        c.id_cliente,
        SUM(CASE WHEN t.id_tipo_trans = 3 THEN 1 ELSE 0 END) AS amazon_purchases,
        SUM(CASE WHEN t.id_tipo_trans = 4 THEN 1 ELSE 0 END) AS mortgage,
        SUM(CASE WHEN t.id_tipo_trans = 5 THEN 1 ELSE 0 END) AS Hotel,
        SUM(CASE WHEN t.id_tipo_trans = 6 THEN 1 ELSE 0 END) AS plane_ticket,
        SUM(CASE WHEN t.id_tipo_trans = 7 THEN 1 ELSE 0 END) AS supermarket
    FROM conto c
    LEFT JOIN transazioni t ON c.id_conto = t.id_conto AND t.id_tipo_trans IN (3, 4, 5, 6, 7)
    GROUP BY c.id_cliente
) AS totals ON ci.id_customer = totals.id_cliente
SET ci.num_amazon_purchases = IFNULL(totals.amazon_purchases, 0),
    ci.num_mortgage_installment = IFNULL(totals.mortgage, 0),
    ci.num_hotel_purchases = IFNULL(totals.Hotel, 0),
    ci.num_plane_ticket_purchases = IFNULL(totals.plane_ticket, 0),
    ci.num_supermarket_purchases = IFNULL(totals.supermarket, 0);

/*

ADD THE TOTAL NUMBER OF INGOING TRANSACTIONS FOR EACH TYPE OF INCOME

*/

-- Add new columns to the customer_info table
ALTER TABLE customer_info
ADD COLUMN num_salary INT DEFAULT 0,
ADD COLUMN num_pension INT DEFAULT 0,
ADD COLUMN num_dividends INT DEFAULT 0;

-- Update the values in the new columns with the counts of transactions for each customer
UPDATE customer_info ci
LEFT JOIN (
    SELECT 
        c.id_cliente,
        SUM(CASE WHEN t.id_tipo_trans = 0 THEN 1 ELSE 0 END) AS salary,
        SUM(CASE WHEN t.id_tipo_trans = 1 THEN 1 ELSE 0 END) AS pension,
        SUM(CASE WHEN t.id_tipo_trans = 2 THEN 1 ELSE 0 END) AS dividends
    FROM conto c
    LEFT JOIN transazioni t ON c.id_conto = t.id_conto AND t.id_tipo_trans IN (0, 1, 2)
    GROUP BY c.id_cliente
) AS totals ON ci.id_customer = totals.id_cliente
SET ci.num_salary = IFNULL(totals.salary, 0),
    ci.num_pension = IFNULL(totals.pension, 0),
    ci.num_dividends = IFNULL(totals.dividends, 0);

/*

ADD THE TOTAL NUMBER OF OUTBOUND TRANSACTIONS FOR EACH TYPE OF EXPENSE

*/

-- Add new columns to the customer_info table
ALTER TABLE customer_info
ADD COLUMN amazon_outbound INT DEFAULT 0,
ADD COLUMN mortgage_installment_outbound INT DEFAULT 0,
ADD COLUMN Hotel_outbound INT DEFAULT 0,
ADD COLUMN plane_ticket_outbound INT DEFAULT 0,
ADD COLUMN supermarket_outbound INT DEFAULT 0;

-- Update the values in the new columns with the counts of transactions for each customer
-- Update the values in the new columns with the total expenses for each customer
UPDATE customer_info ci
LEFT JOIN (
    SELECT 
        c.id_cliente,
        SUM(CASE WHEN t.id_tipo_trans = 3 THEN t.importo ELSE 0 END) AS amazon_purchases_outbound,
        SUM(CASE WHEN t.id_tipo_trans = 4 THEN t.importo ELSE 0 END) AS mortgage_outbound,
        SUM(CASE WHEN t.id_tipo_trans = 5 THEN t.importo ELSE 0 END) AS Hotel_outbound,
        SUM(CASE WHEN t.id_tipo_trans = 6 THEN t.importo ELSE 0 END) AS plane_ticket_outbound,
        SUM(CASE WHEN t.id_tipo_trans = 7 THEN t.importo ELSE 0 END) AS supermarket_outbound
    FROM conto c
    LEFT JOIN transazioni t ON c.id_conto = t.id_conto
    GROUP BY c.id_cliente
) AS totals ON ci.id_customer = totals.id_cliente
SET ci.amazon_outbound = IFNULL(totals.amazon_purchases_outbound, 0),
    ci.mortgage_installment_outbound = IFNULL(totals.mortgage_outbound, 0),
    ci.Hotel_outbound = IFNULL(totals.Hotel_outbound, 0),
    ci.plane_ticket_outbound = IFNULL(totals.plane_ticket_outbound, 0),
    ci.supermarket_outbound = IFNULL(totals.supermarket_outbound, 0);

/*

ADD THE TOTAL NUMBER OF INBOUND TRANSACTIONS FOR EACH TYPE OF INCOME

*/

-- Add new columns to the customer_info table
ALTER TABLE customer_info
ADD COLUMN salary_inbound INT DEFAULT 0,
ADD COLUMN pension_inbound INT DEFAULT 0,
ADD COLUMN dividends_inbound INT DEFAULT 0;

-- Update the values in the new columns with the total inbound amounts for each customer
UPDATE customer_info ci
LEFT JOIN (
    SELECT 
        c.id_cliente,
        SUM(CASE WHEN t.id_tipo_trans = 0 THEN t.importo ELSE 0 END) AS salary_inbound,
        SUM(CASE WHEN t.id_tipo_trans = 1 THEN t.importo ELSE 0 END) AS pension_inbound,
        SUM(CASE WHEN t.id_tipo_trans = 2 THEN t.importo ELSE 0 END) AS dividends_inbound
    FROM conto c
    LEFT JOIN transazioni t ON c.id_conto = t.id_conto AND t.id_tipo_trans IN (0, 1, 2)
    GROUP BY c.id_cliente
) AS totals ON ci.id_customer = totals.id_cliente
SET ci.salary_inbound = IFNULL(totals.salary_inbound, 0),
    ci.pension_inbound = IFNULL(totals.pension_inbound, 0),
    ci.dividends_inbound = IFNULL(totals.dividends_inbound, 0);


SELECT * from customer_info;
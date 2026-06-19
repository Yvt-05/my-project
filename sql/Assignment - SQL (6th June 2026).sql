
-- Q1: Unique nodes in system

SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;


-- Q2: Number of nodes per region

SELECT
    r.region_name,
    COUNT(DISTINCT cn.node_id) AS node_count
FROM customer_nodes cn
JOIN regions r
    ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;


-- Q3: Customers allocated per region

SELECT
    r.region_name,
    COUNT(DISTINCT cn.customer_id) AS customer_count
FROM customer_nodes cn
JOIN regions r
    ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;


-- Q4: Average node reallocation days

SELECT
    AVG(CAST(DATEDIFF(DAY, start_date, end_date) AS FLOAT))
        AS avg_reallocation_days
FROM customer_nodes
WHERE end_date < '9999-12-31';


-- Q5: Reallocation day percentiles

WITH node_days AS
(
    SELECT
        r.region_name,
        DATEDIFF(DAY, start_date, end_date) AS reallocation_days
    FROM customer_nodes cn
    JOIN regions r
        ON cn.region_id = r.region_id
    WHERE end_date < '9999-12-31'
)

SELECT DISTINCT
    region_name,

    PERCENTILE_CONT(0.5)
    WITHIN GROUP (ORDER BY reallocation_days)
    OVER(PARTITION BY region_name) AS median_days,

    PERCENTILE_CONT(0.8)
    WITHIN GROUP (ORDER BY reallocation_days)
    OVER(PARTITION BY region_name) AS percentile_80,

    PERCENTILE_CONT(0.95)
    WITHIN GROUP (ORDER BY reallocation_days)
    OVER(PARTITION BY region_name) AS percentile_95

FROM node_days
ORDER BY region_name;


-- Q6: Transaction count and amount

SELECT
    txn_type,
    COUNT(*) AS transaction_count,
    SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type
ORDER BY txn_type;


-- Q7: Average historical deposits

WITH customer_deposits AS
(
    SELECT
        customer_id,
        COUNT(*) AS deposit_count,
        SUM(txn_amount) AS deposit_amount
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)

SELECT
    AVG(CAST(deposit_count AS FLOAT)) AS avg_deposit_count,
    AVG(CAST(deposit_amount AS FLOAT)) AS avg_deposit_amount
FROM customer_deposits;


-- Q8: Monthly active customers

WITH monthly_transactions AS
(
    SELECT
        customer_id,
        YEAR(txn_date) AS txn_year,
        MONTH(txn_date) AS txn_month,

        SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
        SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count

    FROM customer_transactions
    GROUP BY
        customer_id,
        YEAR(txn_date),
        MONTH(txn_date)
)

SELECT
    txn_year,
    txn_month,
    COUNT(*) AS customer_count
FROM monthly_transactions
WHERE deposit_count > 1
  AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY
    txn_year,
    txn_month
ORDER BY
    txn_year,
    txn_month;


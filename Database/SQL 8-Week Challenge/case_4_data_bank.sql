SET search_path = data_bank;

-- Query 1 : How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) unique_nodes FROM customer_nodes

-- Query 2 : What is the number of nodes per region?
SELECT region_name, COUNT(DISTINCT node_id) number_of_nodes
FROM regions 
INNER JOIN customer_nodes USING (region_id)
GROUP BY region_name

-- Query 3 : How many customers are allocated to each region?
SELECT region_name, COUNT(DISTINCT customer_id) number_of_customers
FROM regions 
INNER JOIN customer_nodes USING (region_id)
GROUP BY region_name

-- Query 4 : How many days on average are customers reallocated to a different node?
WITH base AS (
	SELECT *, end_date - start_date date_difference
	FROM customer_nodes
	WHERE end_date != '9999-12-31'
)

SELECT ROUND(AVG(date_difference), 2) days_on_average
FROM base

-- Query 5 : What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH base AS (
	SELECT region_name, end_date - start_date date_difference
	FROM customer_nodes
	INNER JOIN regions USING(region_id)
	WHERE end_date != '9999-12-31' OR end_date != NULL
)

SELECT region_name, 
	   PERCENTILE_DISC(0.5) WITHIN GROUP (
	   	ORDER BY date_difference
	   ) median_reallocation_days, 
	   PERCENTILE_DISC(0.8) WITHIN GROUP (
	   	ORDER BY date_difference
	   ) percentile_80_reallocation_days, 
	   PERCENTILE_DISC(0.95) WITHIN GROUP (
	   	ORDER BY date_difference
	   ) percentile_95_reallocation_days
FROM base
GROUP BY region_name

-- B. Customer Transactions
-- Query 1 : What is the unique count and total amount for each transaction type?
SELECT txn_type, COUNT(*) unique_count, SUM(txn_amount) total_amount
FROM customer_transactions
GROUP BY txn_type

--Query 2 : What is the average total historical deposit counts and amounts for all customers?
WITH base AS (
	SELECT customer_id, COUNT(*) counts, SUM(txn_amount) amounts
	FROM customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id
)

SELECT ROUND(AVG(counts), 2)historical_deposit_counts, ROUND(AVG(amounts), 2) historical_deposit_amounts
FROM base

-- Query 3 : For each month - how many Data Bank customers make more than 1 deposit and 
--           either 1 purchase or 1 withdrawal in a single month?
WITH base AS (
	SELECT EXTRACT(MONTH FROM txn_date) AS month_number, customer_id, 
	SUM (
		CASE txn_type
			WHEN 'deposit' THEN 1
			ELSE 0
		END
	) deposit_count,
	SUM (
		CASE txn_type
			WHEN 'withdrawal' THEN 1
			ELSE 0
		END
	) withdrawal_count,
	SUM (
		CASE txn_type
			WHEN 'purchase' THEN 1
			ELSE 0
		END
	) purchase_count
	FROM customer_transactions
	GROUP BY EXTRACT(MONTH FROM txn_date), customer_id
)

SELECT month_number, COUNT(*) Total_Customers
FROM base 
WHERE deposit_count > 1 AND (withdrawal_count > 0 OR purchase_count > 0)
GROUP BY month_number
ORDER BY month_number

-- Query 4 : What is the closing balance for each customer at the end of the month?
WITH txn AS (
    SELECT
        customer_id,
        txn_date,
        EXTRACT(MONTH FROM txn_date) AS month,

        CASE
            WHEN txn_type = 'deposit' THEN txn_amount
            ELSE -txn_amount
        END AS amount_change
    FROM customer_transactions
),

running_balance AS (
    SELECT
        customer_id,
        txn_date,
        month,
        SUM(amount_change) OVER (
            PARTITION BY customer_id
            ORDER BY txn_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS balance
    FROM txn
),

month_end AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, month
            ORDER BY txn_date DESC
        ) AS rn
    FROM running_balance
)

SELECT
    customer_id,
    month,
    balance AS closing_balance
FROM month_end
WHERE rn = 1
ORDER BY customer_id, month;


-- Query 5 : What is the percentage of customers who increase their 
-- 			 closing balance by more than 5%?
WITH txn AS (
    SELECT
        customer_id,
        txn_date,
        DATE_TRUNC('month', txn_date) AS month,

        CASE
            WHEN txn_type = 'deposit' THEN txn_amount
            ELSE -txn_amount
        END AS amount_change
    FROM customer_transactions
),

running_balance AS (
    SELECT
        customer_id,
        txn_date,
        month,
        SUM(amount_change) OVER (
            PARTITION BY customer_id
            ORDER BY txn_date
        ) AS balance
    FROM txn
),

month_end AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, month
            ORDER BY txn_date DESC
        ) AS rn
    FROM running_balance
),

final_table AS (
    SELECT
        customer_id,
        month,
        balance AS closing_balance
    FROM month_end
    WHERE rn = 1
),

balance_growth AS (
    SELECT
        customer_id,
        month,
        closing_balance,
        LAG(closing_balance) OVER (
            PARTITION BY customer_id
            ORDER BY month
        ) AS prev_balance
    FROM final_table
),

qualified_customers AS (
    SELECT DISTINCT customer_id
    FROM balance_growth
    WHERE prev_balance IS NOT NULL
      AND prev_balance <> 0
      AND (closing_balance - prev_balance) / ABS(prev_balance) >= 0.05
),

total_customers AS (
    SELECT COUNT(DISTINCT customer_id) AS total_count
    FROM customer_transactions
)

SELECT
    ROUND(
        (SELECT COUNT(*) FROM qualified_customers) * 100.0
        / (SELECT total_count FROM total_customers),
        2
    ) AS percentage_customer_having_5_percent_increment;
















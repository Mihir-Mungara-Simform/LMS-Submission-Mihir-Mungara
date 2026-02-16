SET search_path = foodie_fi;

-- A. Customer Journey
SELECT customer_id, plan_id, plan_name, start_date FROM subscriptions 
INNER JOIN plans USING(plan_id)
WHERE customer_id IN (1,2,11,13,15,16,18,19);


-- B. Data Analysis Questions

-- Query 1 : How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) total_customers FROM subscriptions;

-- Query 2 : What is the monthly distribution of trial plan start_date 
--           values for our dataset - use the start of the month as the group by value
SELECT to_char(start_date , 'mon yyyy') date, count(*) monthly_distribution
FROM subscriptions 
INNER JOIN plans USING(plan_id)
WHERE plan_name = 'trial'
GROUP BY to_char(start_date , 'mon yyyy')


-- Query 3 : What plan start_date values occur after the year 2020 for our dataset?
--			 Show the breakdown by count of events for each plan_name
SELECT plan_name, COUNT(*) no_of_time_purchased
FROM subscriptions 
INNER JOIN plans USING(plan_id)
WHERE EXTRACT(YEAR FROM start_date) > 2020
GROUP BY plan_name
order by plan_name


-- Query 4 : What is the customer count and percentage of customers
-- 			 who have churned rounded to 1 decimal place?
WITH total_customers AS (
	SELECT COUNT(DISTINCT customer_id) counts_total
	FROM subscriptions
),

churned AS (
	SELECT COUNT(DISTINCT customer_id) counts_churned
	FROM subscriptions
	INNER JOIN plans USING(plan_id)
	WHERE plan_name = 'churn'
)

SELECT counts_churned, ROUND((counts_churned * 100.0) / counts_total , 1) percentage_of_customers
FROM total_customers, churned;


-- Query 5 : How many customers have churned straight after their initial free trial 
-- 			 what percentage is this rounded to the nearest whole number?
WITH base AS (
	SELECT customer_id, start_date, plan_name, 
	LEAD(plan_name) OVER (
		PARTITION BY customer_id
		ORDER BY start_date
	) next_plan
	FROM subscriptions
	INNER JOIN plans USING(plan_id)
),

total_customers AS (
	SELECT COUNT(DISTINCT customer_id) counts_total
	FROM subscriptions
),

churned_after_trial AS (
	SELECT COUNT(*) count_churn_after_trial 
	FROM base
	WHERE plan_name = 'trial'
		  AND next_plan = 'churn' 
)

SELECT count_churn_after_trial, ROUND((count_churn_after_trial * 100.0 )/counts_total) percentage
FROM total_customers, churned_after_trial;

-- Query 6 : What is the number and percentage of customer plans after their initial free trial?
WITH base AS (
	SELECT customer_id, start_date, plan_name, 
	LEAD (plan_name) OVER (
		PARTITION BY customer_id
		ORDER BY start_date
	) next_plan
	FROM subscriptions
	INNER JOIN plans USING(plan_id)
),

next_after_trial AS (
	SELECT customer_id, next_plan 
	FROM base
	WHERE plan_name = 'trial'
),

total_customers AS (
	SELECT COUNT(DISTINCT customer_id) counts_total
	FROM subscriptions
)

SELECT next_plan, COUNT(*) no_of_customers, ROUND((COUNT(*) * 100.0)/ counts_total, 2) percentage
FROM total_customers, next_after_trial
GROUP BY next_plan, counts_total
ORDER BY next_plan


-- Query 7 : What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH customer_specified AS (
	SELECT * FROM subscriptions 
	WHERE start_date <= '2020-12-31'
),

count_total AS (
	SELECT COUNT(DISTINCT customer_id) total FROM customer_specified
),

lag_list AS (
	SELECT customer_id, plan_name, start_date, 
	LAG(plan_name) OVER (
		PARTITION BY customer_id
		ORDER BY start_date DESC 
	) last_plan
	FROM customer_specified 
	INNER JOIN plans USING(plan_id)
),

last_plans AS (
	SELECT plan_name
	FROM lag_list
	WHERE last_plan IS NULL
)

SELECT plan_name, COUNT(*) no_of_customers , ROUND((COUNT(*) * 100.0) / total, 2)percentage
FROM last_plans, count_total
GROUP BY plan_name, total
ORDER BY plan_name


-- Query 8 : How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) customers_upgraded_to_annual_plans
FROM subscriptions
INNER JOIN plans USING(plan_id)
WHERE EXTRACT(YEAR FROM start_date) = 2020
	  AND plan_name LIKE '%annual'


-- Query 9 : How many days on average does it take for a customer to 
--			 an annual plan from the day they join Foodie-Fi?
WITH annual AS (
	SELECT DISTINCT customer_id, start_date
	FROM subscriptions 
	INNER JOIN plans USING(plan_id)
	WHERE plan_name LIKE '%annual'
),

trial AS(
	SELECT DISTINCT customer_id, start_date
	FROM subscriptions 
	INNER JOIN plans USING(plan_id)
	WHERE plan_name = 'trial'
)

SELECT ROUND(AVG(a.start_date - t.start_date), 2) :: int avg_days_from_trial_to_annual
FROM annual a
INNER JOIN trial t USING(customer_id)


-- Query 10 : Can you further breakdown this average value into 
-- 			  30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH annual AS (
	SELECT DISTINCT customer_id, start_date
	FROM subscriptions 
	INNER JOIN plans USING(plan_id)
	WHERE plan_name LIKE '%annual'
),

trial AS(
	SELECT DISTINCT customer_id, start_date
	FROM subscriptions 
	INNER JOIN plans USING(plan_id)
	WHERE plan_name = 'trial'
),

diff AS (
	SELECT customer_id, (a.start_date - t.start_date) date_diff
	FROM annual a
	INNER JOIN trial t USING(customer_id) 
)
-- width_bucket(date_diff, MIN(date_diff), MAX(date_diff), MAX(date_diff)/30)
SELECT (date_diff / 30 + 1) thirty_days_period_number, COUNT(*) no_of_customers
FROM diff
GROUP BY thirty_days_period_number



-- Query 11 : How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH base AS (
	SELECT customer_id, plan_name, start_date,
	LAG(plan_name) OVER (
		PARTITION BY customer_id
		ORDER BY start_date
	) last_plan
	FROM subscriptions 
	INNER JOIN plans USING(plan_id)
)

SELECT COUNT(*) downgrade_pro_to_basic FROM 
base 
WHERE plan_name = 'basic monthly'
	  AND last_plan = 'pro monthly'
	  AND EXTRACT(YEAR FROM start_date) = 2020

-- MOST IMP
-- C. Challenge Payment Question
CREATE TABLE payments (
	customer_id INT,
	plan_id INT,
	plan_name VARCHAR(13),
	payment_date DATE, 
	amount DECIMAL(5,2),
	payment_order INT
)
-----------------------------------
WITH data_of_2020 AS (
	SELECT * FROM subscriptions 
	WHERE EXTRACT(YEAR FROM start_date) = 2020
),

table_with_next_plan AS (
	SELECT customer_id, plan_id, plan_name, start_date, 
	LEAD(plan_name) OVER (
		PARTITION BY customer_id
		ORDER BY start_date
	) next_plan, 
	LEAD(start_date) OVER (
		PARTITION BY customer_id
		ORDER BY start_date
	) next_plan_start_date
	FROM data_of_2020
	INNER JOIN plans USING(plan_id)
),

without_trials AS (
	SELECT *
	FROM table_with_next_plan
	-- WHERE plan_name != 'trial'
),

basic_monthly_null AS (
	SELECT
	wt.customer_id,
	wt.plan_id,
	wt.plan_name,
	-- wt.start_date,
	ARRAY_AGG(gs.payment_date ORDER BY gs.payment_date) AS payment_dates,
	9.9 amount
	FROM without_trials wt
	LEFT JOIN LATERAL (
	    SELECT (wt.start_date + (n || ' month')::interval)::date AS payment_date
	    FROM generate_series(
	            0,
	            EXTRACT(YEAR  FROM AGE('2020-12-31', wt.start_date)) * 12 +
	            EXTRACT(MONTH FROM AGE('2020-12-31', wt.start_date))
	         ) AS g(n)
	) gs ON TRUE
	WHERE wt.plan_name = 'basic monthly'
	      AND wt.next_plan IS NULL
	GROUP BY wt.customer_id, wt.plan_id, wt.plan_name, wt.start_date
	ORDER BY wt.customer_id
),

pro_monthly_null AS (
	SELECT
	wt.customer_id,
	wt.plan_id,
	wt.plan_name,
	-- wt.start_date,
	ARRAY_AGG(gs.payment_date ORDER BY gs.payment_date) AS payment_dates,
	19.9 amount
	FROM without_trials wt
	LEFT JOIN LATERAL (
	    SELECT (wt.start_date + (n || ' month')::interval)::date AS payment_date
	    FROM generate_series(
	            0,
	            EXTRACT(YEAR  FROM AGE('2020-12-31', wt.start_date)) * 12 +
	            EXTRACT(MONTH FROM AGE('2020-12-31', wt.start_date))
	         ) AS g(n)
	) gs ON TRUE
	WHERE wt.plan_name = 'pro monthly'
	      AND wt.next_plan IS NULL
	GROUP BY wt.customer_id, wt.plan_id, wt.plan_name, wt.start_date
	ORDER BY wt.customer_id
),

pro_annual_null AS (
	SELECT
	wt.customer_id,
	wt.plan_id,
	wt.plan_name,
	ARRAY_AGG(gs.payment_date ORDER BY gs.payment_date) AS payment_dates,
	199 amount
	FROM without_trials wt
	LEFT JOIN LATERAL (
	    SELECT (wt.start_date + (n || ' month')::interval)::date AS payment_date
	    FROM generate_series(
	            0, 0
	         ) AS g(n)
	) gs ON TRUE
	WHERE wt.plan_name = 'pro annual'
	      AND wt.next_plan IS NULL
	GROUP BY wt.customer_id, wt.plan_id, wt.plan_name, wt.start_date
	ORDER BY wt.customer_id
),

basic_monthly_pro_monthly AS (
	SELECT
	wt.customer_id,
	wt.plan_id,
	wt.plan_name,
	ARRAY_AGG(gs.payment_date ORDER BY gs.payment_date) AS payment_dates,
	9.9 amount
	FROM without_trials wt
	LEFT JOIN LATERAL (
	    SELECT (wt.start_date + (n || ' month')::interval)::date AS payment_date
	    FROM generate_series(
	            0,
				(
		            EXTRACT(YEAR  FROM AGE(wt.next_plan_start_date, wt.start_date)) * 12 +
		            EXTRACT(MONTH FROM AGE(wt.next_plan_start_date, wt.start_date))
				) - 1
	         ) AS g(n)
	) gs ON TRUE
	WHERE wt.plan_name = 'basic monthly'
	      AND wt.next_plan = 'pro monthly'
	GROUP BY wt.customer_id, wt.plan_id, wt.plan_name, wt.start_date, wt.next_plan_start_date

	UNION ALL 

	SELECT
	wt.customer_id,
	wt.plan_id,
	wt.next_plan,
	ARRAY_AGG(gs.payment_date ORDER BY gs.payment_date) AS payment_dates,
	19.9 - 9.9 amount
	FROM without_trials wt
	LEFT JOIN LATERAL (
	    SELECT (wt.next_plan_start_date + (n || ' month')::interval)::date AS payment_date
	    FROM generate_series(
	            0, 0
	         ) AS g(n)
	) gs ON TRUE
	WHERE wt.plan_name = 'basic monthly'
	      AND wt.next_plan = 'pro monthly'
	GROUP BY wt.customer_id, wt.plan_id, wt.plan_name, wt.next_plan, wt.start_date, wt.next_plan_start_date

	UNION ALL 

	SELECT
	wt.customer_id,
	wt.plan_id,
	wt.next_plan,
	ARRAY_AGG(gs.payment_date ORDER BY gs.payment_date) AS payment_dates,
	19.9 amount
	FROM without_trials wt
	LEFT JOIN LATERAL (
	    SELECT (wt.start_date + (n || ' month')::interval)::date AS payment_date
	    FROM generate_series(
	            0,
				(
		            EXTRACT(YEAR  FROM AGE('2020-12-31', wt.next_plan_start_date)) * 12 +
		            EXTRACT(MONTH FROM AGE('2020-12-31', wt.next_plan_start_date))
				)
	         ) AS g(n)
	) gs ON TRUE
	WHERE wt.plan_name = 'basic monthly'
	      AND wt.next_plan = 'pro monthly'
	GROUP BY wt.customer_id, wt.plan_id, wt.plan_name, wt.next_plan, wt.start_date, wt.next_plan_start_date
),

basic_monthly_pro_annual AS (
	SELECT
	wt.customer_id,
	wt.plan_id,
	wt.plan_name,
	ARRAY_AGG(gs.payment_date ORDER BY gs.payment_date) AS payment_dates,
	9.9 amount
	FROM without_trials wt
	LEFT JOIN LATERAL (
	    SELECT (wt.start_date + (n || ' month')::interval)::date AS payment_date
	    FROM generate_series(
	            0,
				(
		            EXTRACT(YEAR  FROM AGE(wt.next_plan_start_date, wt.start_date)) * 12 +
		            EXTRACT(MONTH FROM AGE(wt.next_plan_start_date, wt.start_date))
				) - 1
	         ) AS g(n)
	) gs ON TRUE
	WHERE wt.plan_name = 'basic monthly'
	      AND wt.next_plan = 'pro annual'
	GROUP BY wt.customer_id, wt.plan_id, wt.plan_name, wt.start_date, wt.next_plan_start_date

	UNION ALL 

	SELECT
	wt.customer_id,
	wt.plan_id,
	wt.next_plan,
	ARRAY_AGG(gs.payment_date ORDER BY gs.payment_date) AS payment_dates,
	199 - 9.9 amount
	FROM without_trials wt
	LEFT JOIN LATERAL (
	    SELECT (wt.next_plan_start_date + (n || ' month')::interval)::date AS payment_date
	    FROM generate_series(
	            0, 0
	         ) AS g(n)
	) gs ON TRUE
	WHERE wt.plan_name = 'basic monthly'
	      AND wt.next_plan = 'pro annual'
	GROUP BY wt.customer_id, wt.plan_id, wt.plan_name, wt.next_plan, wt.start_date, wt.next_plan_start_date
),


pro_monthly_pro_annual AS (

    SELECT
        wt.customer_id,
        wt.plan_id,
        wt.plan_name,
        ARRAY_REMOVE(ARRAY_AGG(gs.payment_date ORDER BY gs.payment_date), NULL) AS payment_dates,
        19.9 AS amount
    FROM without_trials wt
    LEFT JOIN LATERAL (
        SELECT (wt.start_date + (n || ' month')::interval)::date AS payment_date
        FROM generate_series(
            0,
            CEIL(
                (
                    EXTRACT(YEAR  FROM AGE(wt.next_plan_start_date, wt.start_date)) * 12 +
                    EXTRACT(MONTH FROM AGE(wt.next_plan_start_date, wt.start_date)) +
                    EXTRACT(DAY FROM AGE(wt.next_plan_start_date, wt.start_date)) / 31.0
                )
            )::int - 1
        ) AS g(n)
    ) gs ON TRUE
    WHERE wt.plan_name = 'pro monthly'
      AND wt.next_plan = 'pro annual'
    GROUP BY wt.customer_id, wt.plan_id, wt.plan_name, wt.start_date, wt.next_plan_start_date

    UNION ALL

    SELECT
        wt.customer_id,
        wt.plan_id,
        'pro annual' AS plan_name,
        ARRAY_REMOVE(ARRAY_AGG(gs.payment_date ORDER BY gs.payment_date), NULL) AS payment_dates,
        199 AS amount
    FROM without_trials wt
    LEFT JOIN LATERAL (
        SELECT (wt.start_date + (n || ' month')::interval)::date AS payment_date
        FROM generate_series(
            CEIL(
                (
                    EXTRACT(YEAR  FROM AGE(wt.next_plan_start_date, wt.start_date)) * 12 +
                    EXTRACT(MONTH FROM AGE(wt.next_plan_start_date, wt.start_date)) +
                    EXTRACT(DAY FROM AGE(wt.next_plan_start_date, wt.start_date)) / 31.0
                )
            )::int,
            CEIL(
                (
                    EXTRACT(YEAR  FROM AGE(wt.next_plan_start_date, wt.start_date)) * 12 +
                    EXTRACT(MONTH FROM AGE(wt.next_plan_start_date, wt.start_date)) +
                    EXTRACT(DAY FROM AGE(wt.next_plan_start_date, wt.start_date)) / 31.0
                )
            )::int
        ) AS g(n)
    ) gs ON TRUE
    WHERE wt.plan_name = 'pro monthly'
      AND wt.next_plan = 'pro annual'
    GROUP BY wt.customer_id, wt.plan_id, wt.start_date, wt.next_plan_start_date
),


all_arrays AS (

    SELECT * FROM basic_monthly_null
    UNION ALL SELECT * FROM pro_monthly_null
    UNION ALL SELECT * FROM pro_annual_null
    UNION ALL SELECT * FROM basic_monthly_pro_monthly
    UNION ALL SELECT * FROM basic_monthly_pro_annual
    UNION ALL SELECT * FROM pro_monthly_pro_annual

),

expanded AS (
    SELECT
        customer_id,
        plan_id,
        plan_name,
        amount,
        payment_date
    FROM all_arrays
    CROSS JOIN LATERAL UNNEST(payment_dates) AS payment_date
)

INSERT INTO payments (customer_id, plan_id, plan_name, payment_date, amount, payment_order)

SELECT
    customer_id,
    plan_id,
    plan_name,
    payment_date,
    amount,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY payment_date
    ) AS payment_order
FROM expanded
ORDER BY customer_id, payment_date;


SELECT * FROM payments














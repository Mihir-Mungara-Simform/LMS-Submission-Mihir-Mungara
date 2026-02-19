CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');



UPDATE customer_orders
SET exclusions = NULL
WHERE exclusions IN ('null', 'NaN', '');

UPDATE customer_orders
SET extras = NULL
WHERE extras IN ('null', 'NaN', '');
-- select * from customer_orders;

-- drop table order_extras;
CREATE TABLE order_extras AS
SELECT 
	order_id,
	customer_id,
	pizza_id,
	UNNEST(string_to_array(extras, ',')) ::INT as extras,
	order_time
FROM customer_orders
WHERE extras IS NOT NULL;
-- select * from order_extras;


CREATE TABLE order_exclusions AS
SELECT 
	order_id,
	customer_id,
	pizza_id,
	UNNEST(string_to_array(exclusions, ',')) ::INT as exclusions,
	order_time
FROM customer_orders
WHERE exclusions IS NOT NULL;
-- select * from order_exclusions; 
UPDATE runner_orders
SET
  pickup_time = NULLIF(pickup_time, 'null'),
  distance    = NULLIF(distance, 'null'),
  duration    = NULLIF(duration, 'null'),
  cancellation = NULLIF(cancellation, 'null');

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = '';

-- select * from runner_orders;

ALTER TABLE runner_orders
ADD COLUMN pickup_ts TIMESTAMP,
ADD COLUMN distance_km NUMERIC,
ADD COLUMN duration_min NUMERIC;

UPDATE runner_orders
SET pickup_ts = pickup_time::TIMESTAMP
WHERE pickup_time IS NOT NULL;

UPDATE runner_orders
SET distance_km =
  NULLIF(
    regexp_replace(distance, '[^0-9\.]', '', 'g'),
    ''
  )::NUMERIC;

UPDATE runner_orders
SET duration_min =
  NULLIF(
    regexp_replace(duration, '[^0-9]', '', 'g'),
    ''
  )::NUMERIC;


ALTER TABLE runner_orders
DROP COLUMN pickup_time,
DROP COLUMN distance,
DROP COLUMN duration;

CREATE TABLE pizza_recipes_nd (
  pizza_id INT,
  topping_id INT
);

INSERT INTO pizza_recipes_nd (pizza_id, topping_id)
SELECT
  pizza_id,
  UNNEST(string_to_array(toppings, ','))::INT
FROM pizza_recipes;


select * from pizza_toppings;







-- Queries 

-- Query 1 : How many pizzas were ordered?
SELECT COUNT(*) total_pizzas FROM customer_orders;

-- Query 2 : How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) 
unique_customer_orders FROM customer_orders;

-- Query 3 : How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) orders_delivered
FROM runner_orders 
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;

-- Query 4 : How many of each type of pizza was delivered?
-- cancelled order is not taken into consideration
SELECT pizza_id, COUNT(pizza_id) no_of_pizza_delivered
FROM customer_orders
INNER JOIN 
runner_orders USING(order_id)
WHERE cancellation IS NULL
GROUP BY pizza_id
ORDER BY pizza_id;

-- Query 5 : How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, pizza_name, count(*)
FROM customer_orders
INNER JOIN pizza_names USING(pizza_id)
GROUP BY customer_id, pizza_name
ORDER BY customer_id, pizza_name;

-- Query 6 : What was the maximum number of pizzas delivered in a single order?
-- cancelled order is not taken into consideration
SELECT order_id, COUNT(*) max_pizzas
FROM customer_orders
INNER JOIN runner_orders USING(order_id)
WHERE cancellation IS NULL
GROUP BY order_id
ORDER BY COUNT(*) DESC 
FETCH NEXT 1 ROW ONLY;

-- Query 7 : For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- cancelled order is not taken into consideration
SELECT customer_id, 
SUM (
	CASE 
		WHEN extras IS NOT NULL OR exclusions IS NOT NULL THEN 1
		ELSE 0
	END
) atleast_1_change,
SUM (
	CASE 
		WHEN extras IS NOT NULL OR exclusions IS NOT NULL THEN 0
		ELSE 1
	END
) no_changes
FROM customer_orders
INNER JOIN runner_orders USING(order_id)
WHERE cancellation IS NULL
GROUP BY customer_id
ORDER BY customer_id;

-- Query 8 : How many pizzas were delivered that had both exclusions and extras?
-- cancelled order is not taken into consideration
SELECT COUNT(*) pizzas_had_both_exclusiona_and_extras
FROM customer_orders
INNER JOIN runner_orders USING(order_id)
WHERE cancellation IS NULL AND
(extras IS NOT NULL and exclusions IS NOT NULL);

-- Query 9 : What was the total volume of pizzas ordered for each hour of the day?
-- Showing only that hours which had some value 
SELECT EXTRACT(HOUR FROM order_time) AS Hour_of_Day, COUNT(*) Volume_of_pizzas
FROM customer_orders 
GROUP BY Hour_of_Day
HAVING COUNT(*) > 0
ORDER BY hour_of_day;

-- Query 10 : What was the volume of orders for each day of the week?
-- Showing only that days which had some value 
SELECT TO_CHAR(order_time, 'Day') AS day_of_week, COUNT(*) Volume_of_pizzas
FROM customer_orders 
GROUP BY Day_of_Week
HAVING COUNT(*) > 0
ORDER BY Day_of_Week;


-- B. Runner and Customer Experience

-- Query 1 : How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT (registration_date - DATE '2021-01-01') / 7 + 1 AS week_no, count(*) signed_up
FROM runners
GROUP BY week_no
ORDER BY week_no;

-- Query 2 : What was the average time in minutes it took for each runner 
-- 			 to arrive at the Pizza Runner HQ to pickup the order?
WITH cte1 AS(
	SELECT DISTINCT order_id, customer_id, order_time
	FROM customer_orders
)

SELECT runner_id, ROUND(AVG(EXTRACT(EPOCH FROM (pickup_ts - order_time))/60), 2) average_minutes
FROM cte1
INNER JOIN runner_orders USING(order_id)
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;

-- Query 3 : Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- Assuming difference between pickup time and order time as time to prepare an order
-- Assuming cancelled order is not made
WITH cte as (
	SELECT order_id, AVG(EXTRACT(EPOCH FROM (pickup_ts - order_time)) / 60) average_minutes, count(*) no_of_pizzas
	FROM runner_orders 
	INNER JOIN customer_orders USING(order_id)
	WHERE cancellation IS NULL
	GROUP BY order_id
	ORDER BY order_id
)

SELECT no_of_pizzas, ROUND(AVG(average_minutes), 2) avg_min
FROM cte
GROUP BY no_of_pizzas

-- Query 4 : What was the average distance travelled for each customer?
WITH cte1 AS(
	SELECT DISTINCT order_id, customer_id, order_time
	FROM customer_orders
)

SELECT customer_id, ROUND(AVG(distance_km), 2) distance_km
FROM cte1 
INNER JOIN runner_orders USING(order_id)
WHERE cancellation IS NULL
GROUP BY customer_id
ORDER BY customer_id;

-- Query 5 : What was the difference between the longest and shortest delivery times for all orders?
-- Assuming delivery time = duration to reach destination from pick_up point 
SELECT ROUND(MAX(Duration_min), 2) longesr_time, 
	   ROUND(MIN(Duration_min), 2) shortest_time,
	   ROUND(MAX(Duration_min) - MIN(Duration_min)) diff
FROM runner_orders;

-- Query 6 : What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, order_id, ROUND(AVG(distance_km / duration_min) * 60 , 2) avg_speed_km_hr
FROM runner_orders
INNER JOIN runners USING(runner_id)
WHERE cancellation IS NULL
GROUP BY runner_id, order_id
ORDER BY runner_id, order_id;

-- Query 7 : What is the successful delivery percentage for each runner?
SELECT runner_id,
ROUND(SUM (
	CASE 
		WHEN pickup_ts IS NOT NULL THEN 1
		ELSE 0
	END
) :: numeric / count(*), 2) * 100 Successful_Delivery_Percent
FROM runner_orders
GROUP BY runner_id
ORDER BY runner_id;




-- C. Ingredient Optimisation

-- Query 1 : What are the standard ingredients for each pizza?
SELECT pizza_id, ARRAY_AGG(topping_name) standard_ingredients
FROM pizza_recipes_nd
INNER JOIN pizza_toppings USING(topping_id)
GROUP BY pizza_id
ORDER BY pizza_id;

-- Query 2 : What was the most commonly added extra?
SELECT oe.extras extra_id , pt.topping_name toppings, COUNT(*) no_of_times_added
FROM order_extras oe
INNER JOIN pizza_toppings pt
ON oe.extras = pt.topping_id
GROUP BY extra_id, toppings
ORDER BY COUNT(*) DESC
FETCH NEXT 1 ROW ONLY;

-- Query 3 : What was the most common exclusion?
SELECT oe.exclusions exclusion_id , pt.topping_name toppings, COUNT(*) no_of_times_excluded
FROM order_exclusions oe
INNER JOIN pizza_toppings pt
ON oe.exclusions = pt.topping_id
GROUP BY exclusion_id, toppings
ORDER BY COUNT(*) DESC
FETCH NEXT 1 ROW ONLY;

-- Query 4 : Generate an order item for each record in the customers_orders table 
-- 			 in the format of one of the following:
-- 			 	* Meat Lovers
-- 			 	* Meat Lovers - Exclude Beef
-- 			 	* Meat Lovers - Extra Bacon
-- 			 	* Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH base AS (
  SELECT
    co.*,
    pn.pizza_name
  FROM customer_orders co
  JOIN pizza_names pn USING (pizza_id)
),

changes AS (
  SELECT
    b.order_id,

    COALESCE(
      ' - Exclude: ' || STRING_AGG(DISTINCT pt_ex.topping_name, ', '),
      ''
    ) ||

    COALESCE(
      ' - Extra: ' || STRING_AGG(DISTINCT pt_extra.topping_name, ', '),
      ''
    ) AS change_text

  FROM base b
  LEFT JOIN order_exclusions oe
    ON b.order_id = oe.order_id
  LEFT JOIN pizza_toppings pt_ex
    ON pt_ex.topping_id = oe.exclusions
  LEFT JOIN order_extras oex
    ON b.order_id = oex.order_id
  LEFT JOIN pizza_toppings pt_extra
    ON pt_extra.topping_id = oex.extras

  GROUP BY b.order_id
)

SELECT
  b.*,
  b.pizza_name || COALESCE(c.change_text, '') AS order_description
FROM base b
LEFT JOIN changes c USING (order_id)
ORDER BY b.order_id;


-- Query 5 : Generate an alphabetically ordered comma separated ingredient list 
--           for each pizza order from the customer_orders table and 
--           add a 2x in front of any relevant ingredients
--			 For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH base AS (
	SELECT ROW_NUMBER () OVER (
		ORDER BY order_id, pizza_id
	) row_id , *
	FROM customer_orders
),

default_list AS (
	SELECT b.row_id, unnest(string_to_array(r.toppings,', ')) topping_id, 1 cnt
	FROM base b
	JOIN pizza_recipes r USING(pizza_id)
),

extras AS (
	SELECT b.row_id, UNNEST(string_to_array(extras, ','))topping_id, 1 cnt
	FROM base b
),

exclusions AS (
	SELECT b.row_id, UNNEST(string_to_array(exclusions, ','))topping_id, -1 cnt
	FROM base b
),

combined AS (
	SELECT * FROM default_list
	UNION ALL 
	SELECT * FROM extras
	UNION ALL
	SELECT * FROM exclusions
),

grouped AS (
	SELECT row_id, topping_id, sum(cnt) total_cnt
	FROM combined
	GROUP BY row_id, topping_id
	HAVING sum(cnt) > 0
),

naming_ind AS (
	SELECT g.row_id, pt.topping_name, g.total_cnt cnt
	FROM grouped g
	INNER JOIN pizza_toppings pt
	ON g.topping_id :: int = pt.topping_id
),

partial_format AS (
	SELECT row_id, 
	CASE 
		WHEN cnt > 1 
		THEN cnt || 'x' || topping_name
		ELSE topping_name
	END
	individuals
	FROM naming_ind
),

final_string AS (
	SELECT row_id, 
	STRING_AGG(individuals, ',' ORDER BY individuals) ingredients
	FROM partial_format
	GROUP BY row_id
)

SELECT row_id, order_id, customer_id, pizza_id, order_time,
		pizza_name || ': ' || ingredients AS ingredients
FROM base 
INNER JOIN final_string USING(row_id)
INNER JOIN pizza_names USING(pizza_id)
ORDER BY row_id, order_id;



-- Query 6 : What is the total quantity of each ingredient used 
--			 in all delivered pizzas sorted by most frequent first?
-- cancelled orders are not counted
WITH base AS (
	SELECT ROW_NUMBER () OVER (
		ORDER BY order_id, pizza_id
	) row_id , *
	FROM customer_orders
),

default_list AS (
	SELECT b.row_id, unnest(string_to_array(r.toppings,', ')) topping_id, 1 cnt
	FROM base b
	JOIN pizza_recipes r USING(pizza_id)
),

extras AS (
	SELECT b.row_id, UNNEST(string_to_array(extras, ','))topping_id, 1 cnt
	FROM base b
),

exclusions AS (
	SELECT b.row_id, UNNEST(string_to_array(exclusions, ','))topping_id, -1 cnt
	FROM base b
),

combined AS (
	SELECT * FROM default_list
	UNION ALL 
	SELECT * FROM extras
	UNION ALL
	SELECT * FROM exclusions
),

grouped AS (
	SELECT row_id, topping_id, sum(cnt) total_cnt
	FROM combined
	GROUP BY row_id, topping_id
	HAVING sum(cnt) > 0
),

naming_ind AS (
	SELECT g.row_id, pt.topping_name, g.total_cnt cnt
	FROM grouped g
	INNER JOIN pizza_toppings pt
	ON g.topping_id :: int = pt.topping_id
)

SELECT topping_name, SUM(cnt) total_quantity
FROM naming_ind
INNER JOIN base b USING(row_id)
INNER JOIN runner_orders USING(order_id)
WHERE cancellation IS NULL
GROUP BY topping_name
ORDER BY SUM(cnt) DESC;



-- D. Pricing and Ratings

-- Query 1 : If a Meat Lovers pizza costs $12 and Vegetarian costs $10 
--			 and there were no charges for changes - how much money has 
--			 Pizza Runner made so far if there are no delivery fees? 
-- Assuming that money for cancelled pizza is not collected/received
SELECT SUM 
(
	CASE pizza_name
		WHEN 'Vegetarian' THEN 10
		WHEN 'Meatlovers' THEN 12
	END
) total_money_made_$
FROM customer_orders
INNER JOIN pizza_names USING(pizza_id)
INNER JOIN runner_orders USING(order_id)
WHERE cancellation IS NULL;

-- Query 2 : What if there was an additional $1 charge for any pizza extras?
--           ex : Add cheese is $1 extra
-- Assuming that money for cancelled pizza is not collected/received
SELECT SUM 
(
	CASE pizza_name
		WHEN 'Vegetarian' THEN 10
		WHEN 'Meatlovers' THEN 12
	END
	+
	COALESCE(array_length(string_to_array(extras, ','), 1), 0)
) total_money_made_$
FROM customer_orders
INNER JOIN pizza_names USING(pizza_id)
INNER JOIN runner_orders USING(order_id)
WHERE cancellation IS NULL;

-- Query 3 : The Pizza Runner team now wants to add an additional ratings system 
--			 that allows customers to rate their runner, how would you design an 
--           additional table for this new dataset - generate a schema for this new table 
-- 			 and insert your own data for ratings for each successful customer order between 1 to 5.

CREATE TABLE ratings (
	customer_id INT,
	order_id INT,
	runner_id INT,
	rating INT CHECK (Rating BETWEEN 1 AND 5),
	description VARCHAR(1000)
)

INSERT INTO ratings (customer_id, order_id, runner_id, rating, description) VALUES
(101, 1, 1, 5, 'Fast delivery and hot pizza'),
(101, 2, 1, 4, 'Good service, slightly late'),
(102, 3, 1, 5, 'Perfect timing and taste'),
(103, 4, 2, 3, 'Delivery was slow but food ok'),
(104, 5, 3, 4, 'Nice and warm pizza'),
(105, 7, 2, 5, 'Excellent delivery'),
(102, 8, 2, 4, 'Good but packaging could improve'),
(104, 10, 1, 5, 'Very quick delivery');


SELECT * FROM ratings;

-- Query 4 : Using your newly generated table - can you join all of the information together to 
-- 			 form a table which has the following information for successful deliveries?
--           * customer_id
--           * order_id
--           * runner_id
--           * rating
--           * order_time
--           * pickup_time
--           * Time between order and pickup
--           * Delivery duration
--           * Average speed
--           * Total number of pizzas
SELECT r.customer_id, 
	   r.order_id, 
	   r.runner_id, 
	   r.rating, 
	   co.order_time,
	   ro.pickup_ts pickup_time, 
	   ROUND(EXTRACT (EPOCH FROM (ro.pickup_ts - co.order_time)) / 60, 2) time_between_order_pickup_minutes,
	   duration_min delivery_duration, 
	   ROUND((ro.distance_km / ro.duration_min) * 60, 2) avg_speed_km_hr,
	   COUNT(*) total_pizzas
FROM ratings r
INNER JOIN customer_orders co USING(order_id)
INNER JOIN runner_orders ro USING(order_id)
GROUP BY r.customer_id, 
	   r.order_id, 
	   r.runner_id, 
	   r.rating, 
	   co.order_time,
	   ro.pickup_ts, 
	   ROUND(EXTRACT (EPOCH FROM (ro.pickup_ts - co.order_time)) / 60, 2),
	   duration_min, 
	   ROUND((ro.distance_km / ro.duration_min) * 60, 2)
ORDER BY customer_id, order_id, runner_id

-- Query 5 : If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost
--		     for extras and each runner is paid $0.30 per kilometre traveled - 
--			 how much money does Pizza Runner have left over after these deliveries?
WITH total_earning AS (
	SELECT SUM 
	(
		CASE pizza_name
			WHEN 'Vegetarian' THEN 10
			WHEN 'Meatlovers' THEN 12
		END
	) total_money_made , ROUND(AVG(distance_km * 0.30), 2) runner_paid
	FROM customer_orders
	INNER JOIN pizza_names USING(pizza_id)
	INNER JOIN runner_orders USING(order_id)
	WHERE cancellation IS NULL
	GROUP BY order_id
)

SELECT SUM(total_money_made - runner_paid) total_leftovers
FROM total_earning;
	   

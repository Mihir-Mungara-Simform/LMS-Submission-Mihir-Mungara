CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;



-- Question 1 :- What is the total amount each customer spent at the restaurant?
SELECT customer_id Customer, 
SUM(price) Total_Amount
FROM sales s
INNER JOIN
menu m USING(product_id)
GROUP BY customer_id
ORDER BY customer_id;

-- Question 2 :- How many days has each customer visited the restaurant?
SELECT customer_id customer, 
COUNT(DISTINCT order_date) No_of_Days
FROM sales
GROUP BY customer_id;

-- Question 3 :- What was the first item from the menu purchased by each customer?
WITH cte as (
	SELECT customer_id, product_id,
	RANK () over (
		PARTITION BY customer_id
		ORDER BY 
		order_date ASC
	) items_rank
	FROM sales
)

SELECT DISTINCT customer_id AS customer,
ARRAY_AGG(DISTINCT product_name) AS first_items
FROM cte
INNER JOIN
menu USING(product_id)
WHERE items_rank = 1
GROUP BY customer_id;

-- Question 4 :- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT Product_Name Most_Purchased_Item,
COUNT(product_id) No_of_Times_Purchased
FROM sales s
INNER JOIN menu m USING(product_id)
GROUP BY product_name
FETCH NEXT 1 ROW ONLY;

-- Question 5 :- Which item was the most popular for each customer?
WITH item_cnt AS (
SELECT customer_id, product_id, COUNT(*) cnt
FROM sales 
GROUP BY 
customer_id, product_id
),

ranked_items AS (
	SELECT customer_id, product_id,
	RANK () OVER (
		PARTITION BY customer_id
		ORDER BY cnt desc
	) popularity_rank
	FROM item_cnt
)

SELECT customer_id customer, ARRAY_AGG(product_name) AS most_popular_product
FROM ranked_items
INNER JOIN menu m
USING(product_id)
WHERE popularity_rank = 1
GROUP BY customer_id
ORDER BY customer_id;

-- Question 6 :- Which item was purchased first by the customer after they became a member?
-- Assumption :- taking same day in count 
WITH after_membership AS (
	SELECT s.customer_id, s.product_id, s.order_date, m.join_date
	FROM sales s 
	LEFT OUTER JOIN members m
	USING(customer_id)
	WHERE m.join_date <= s.order_date
),

ranked_by_date AS (
	SELECT customer_id, product_id, order_date,
	DENSE_RANK () OVER (
		PARTITION BY customer_id
		ORDER BY order_date
	) date_after_membership
	FROM after_membership
)

SELECT customer_id customer, product_name Purchased_1st_membership
FROM ranked_by_date 
INNER JOIN
menu USING(product_id)
where date_after_membership = 1
ORDER BY customer_id;

-- Question 7 :- Which item was purchased just before the customer became a member?
-- Assumption :- day of joining is not counted
WITH before_membership AS (
	SELECT s.customer_id, s.product_id, s.order_date, m.join_date
	FROM sales s 
	LEFT OUTER JOIN members m
	USING(customer_id)
	WHERE m.join_date > s.order_date
),

ranked_by_date AS (
	SELECT customer_id, product_id, order_date,
	DENSE_RANK () OVER (
		PARTITION BY customer_id
		ORDER BY order_date desc
	) date_before_membership
	FROM before_membership
)

SELECT customer_id customer, ARRAY_AGG(product_name) AS Purchased_before_membership
FROM ranked_by_date 
INNER JOIN
menu USING(product_id)
where date_before_membership = 1
GROUP BY customer_id
ORDER BY customer;

-- Question 8 :- What is the total items and amount spent for each member before they became a member?
WITH before_membership AS (
	SELECT s.customer_id, s.product_id, s.order_date, m.join_date
	FROM sales s 
	LEFT OUTER JOIN members m
	USING(customer_id)
	WHERE m.join_date > s.order_date
)

SELECT customer_id customer,
COUNT(product_id) no_of_items,
SUM (price) Total_Amount
FROM before_membership
INNER JOIN 
menu USING(product_id)
GROUP BY customer_id
ORDER BY customer;

-- Question 9 :- If each $1 spent equates to 10 points and 
-- sushi has a 2x points multiplier - how many points would each customer have?
-- Assumption :- price given is assumed to be in dollars($)
SELECT customer_id customer,
SUM (
	CASE product_name
		WHEN 'sushi' THEN price * 2 * 10
		ELSE price * 10
	END
) total_points
FROM sales
INNER JOIN 
menu USING(product_id)
GROUP BY customer_id
ORDER BY customer_id;

-- Question 10 :- In the first week after a customer joins the program 
-- (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B 
-- have at the end of January?
-- Assumption :- taking 1$ spent to 10 points
WITH selected_dates AS (
	SELECT customer_id, product_id, order_date, join_date
	FROM sales
	INNER JOIN
	members USING(customer_id)
	WHERE order_date <= CAST('2021-01-31' AS DATE)
)

SELECT customer_id customer, 
SUM (
	CASE
		WHEN join_date + INTERVAL '6 days'  >= order_date AND order_date >= join_date THEN price * 2 * 10
		WHEN product_name = 'sushi' THEN price * 2 * 10
		ELSE price * 10
	END
) total_points
FROM selected_dates
INNER JOIN 
menu USING(product_id)
GROUP BY customer_id
ORDER BY customer_id;











CREATE DATABASE femlec_dinner;

USE femlec_dinner;

CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id int
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);


	select *
	from sales;

CREATE TABLE menu(
	product_id int,
	product_name VARCHAR(5),
	price int
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
	(2, 'curry', 15),
	(3, 'ramen', 12);

CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);

--STILL WORKS WITHOUT SPECIFYING THE COLUMN NAMES EXPLICITLY
INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
	('B', '2021-01-09');


--1, what is the total amount each customer spent at the restaurant?
SELECT 
	s.customer_id, SUM(m.price) AS total_Spent
FROM
	sales s
join menu m
ON
	s.product_id=m.product_id
GROUP BY customer_id;




--2, How many days has each customer visited the restaurant?

SELECT
	s.customer_id, COUNT(DISTINCT s.order_date) as days_customer_visited
FROM
	sales s
GROUP BY s.customer_id;


--3, what was the first item from the menu purchased by each customer ?

WITH customer_first_purchase AS (
SELECT 
s.customer_id, MIN(s.order_date) AS first_purchase_date
FROM
	sales s
GROUP BY s.customer_id
)
SELECT
	cfp.customer_id, cfp.first_purchase_date, m.product_name
FROM
customer_first_purchase cfp
join sales s ON s.customer_id = cfp.customer_id
AND cfp.first_purchase_date = s.order_date
join menu m 
ON 
	M.product_id = S.product_id;
	



--4, What is the most purchased item on the menu and how many times was it purchased by all customers
SELECT 
	TOP 3 m.product_name,COUNT(*) AS total_purchased
FROM
sales s
join menu m
ON
	s.product_id = m.product_id
GROUP BY m.product_name
order by total_purchased desc

--5, Which item was the most popular for each customer?

WITH customer_popularity AS (
SELECT
	s.customer_id, m.product_name,COUNT(*) AS purchase_count, 
	DENSE_RANK() OVER (PARTITION BY s.customer_id order by COUNT(*) desc) AS Rank
FROM 
	sales s
join menu m
ON 
	s.product_id=m.product_id
GROUP BY s.customer_id,m.product_name
)
SELECT
	cp.customer_id,cp.product_name, cp.purchase_count
FROM
	customer_popularity cp
WHERE
	Rank = 1;

--6, Which item was purchased first by the customer after they become a member
WITH first_purchase_after_membership AS (
SELECT
	s.customer_id,MIN(s.order_date) AS first_purchase_date
FROM
	sales s
join members mb
ON
	s.customer_id = mb.customer_id
WHERE
	s.order_date>=mb.join_date
GROUP BY s.customer_id
)
SELECT 
	fp.customer_id, m.product_name
FROM
first_purchase_after_membership fp
join sales s
ON 
	s.customer_id= fp.customer_id
AND 
	fp.first_purchase_date = s.order_date
JOIN menu m 
ON
	s.product_id = m.product_id


--7, Which item was purchased just before the customer become a member ?
WITH last_purchase_after_membership AS (
SELECT 
	s.customer_id,MAX(s.order_date) AS last_purchase_date
FROM
sales s
join members mb
ON
	s.customer_id = mb.customer_id
WHERE
	s.order_date < mb.join_date
GROUP BY s.customer_id
)

SELECT
	lpm.customer_id, m.product_name
FROM
last_purchase_after_membership lpm
join sales s
ON
	s.customer_id = lpm.customer_id
AND
	lpm.last_purchase_date = s.order_date
join
	menu m
ON
	s.product_id= m.product_id
	
--what is the total items and amount spent for each member before they became a member
SELECT
	s.customer_id, count(*) as total_items, SUM(m.price) AS total_spent
FROM
sales s
Join menu m
ON
	S.product_id=m.product_id
join members mb
ON
	s.customer_id = mb.customer_id
WHERE
	s.order_date < mb.join_date
GROUP BY s.customer_id;

--9, if each $1 spent equates to 10 points and sushi has a 2x points multiplier , how many points would each customer have
SELECT
	s.customer_id, SUM(
	CASE
		WHEN m.product_name = 'sushi' THEN m.price * 20
		ELSE m.price * 10 END) AS total_points
FROM
sales s
join menu m
ON
	s.product_id = m.product_id
GROUP BY customer_id;

--10, In the first week after a customer join the program (including their join date ) they earn 2x points on all item, not just sushi
--how many points do customer A and B have at the end of january?

SELECT
	s.customer_id, SUM(
CASE
	WHEN
		s.order_date between mb.join_date AND DATEADD(day,7,mb.join_date)
		THEN m.price*20
	WHEN
		m.product_name = 'sushi'
		THEN m.price *20
	ELSE
		m.price * 10 END) AS total_points
FROM
sales s
join menu m
ON
	s.product_id=m.product_id
LEFT join members mb
ON
	s.customer_id=mb.customer_id
WHERE
	S.customer_id IN ('A', 'B') AND s.order_date <= '2021-01-31'
GROUP BY S.customer_id;

--11, Recreate the table output using the available data

SELECT
	s.customer_id, s.order_date,m.price, m.product_name, 
CASE
	WHEN s.order_date >= mb.join_date THEN 'Y'
	ELSE 'N' END AS member
FROM
sales s
join menu m
ON
	s.product_id=m.product_id
LEFT JOIN members mb
ON
	s.customer_id=mb.customer_id
ORDER BY s.customer_id, s.order_date;

--RANK all the things;
WITH Customer_data AS (
SELECT
	s.customer_id, s.order_date,m.product_name,
CASE
	WHEN
S.order_date < MB.join_date THEN 'N'
WHEN S.order_date >= MB.join_date THEN 'Y'
ELSE 'N' END AS member
FROM
sales s
LEFT join members mb 
ON
	s.customer_id=mb.customer_id
JOIN menu m
ON
	s.product_id=m.product_id
)
SELECT 
	*,
CASE
	WHEN
		member = 'N' THEN Null
		ELSE RANK() OVER(PARTITION BY customer_id,member ORDER BY order_date)END AS Rankings
FROM
Customer_data 
ORDER BY customer_id,order_date;

	
USE zomato_analysis;
-- =========================================
-- 1. Revenue Analysis
-- =========================================
-- Q1. What is the total revenue?
SELECT SUM(order_amount) AS total_revenue FROM orders
WHERE order_status = 'Delivered';

-- Q2. What is the Average Order Value (AOV)?
SELECT AVG(order_amount) AS average_order_value
FROM orders
WHERE order_status = 'Delivered';

-- Q3. How has revenue changed month by month?
SELECT
    order_year,
    order_month,
    SUM(order_amount) AS monthly_revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY
    order_year,
    order_month,
    order_month_number
ORDER BY
    order_year,
    Order_month_number;
    
-- Q4. Which city contributes the highest revenue?
SELECT
    customer.city,
    SUM(order_amount) AS total_revenue
FROM customer
INNER JOIN orders
ON customer.customer_id = orders.customer_id
WHERE order_status = 'Delivered'
GROUP BY customer.city
ORDER BY total_revenue DESC;

-- Q5. Which payment mode generates the highest revenue?
SELECT
    payment_mode,
    SUM(order_amount) AS total_revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY payment_mode
ORDER BY total_revenue DESC;

-- =========================================
-- 2. Customer Analysis
-- =========================================
-- Q1. Who are the top 20 customers by revenue?
SELECT
    customer.customer_id,
    customer.customer_name,
    SUM(order_amount) AS total_revenue
FROM customer
INNER JOIN orders
ON customer.customer_id = orders.customer_id
WHERE order_status = "Delivered"
GROUP BY customer.customer_id, customer.customer_name
ORDER BY total_revenue DESC
LIMIT 20;

-- Q2. What percentage of revenue comes from the top customers?
WITH top_customers AS
(
    SELECT
        customer.customer_id,
        customer.customer_name,
        SUM(orders.order_amount) AS total_revenue
    FROM customer
    INNER JOIN orders
        ON customer.customer_id = orders.customer_id
    WHERE orders.order_status = 'Delivered'
    GROUP BY
        customer.customer_id,
        customer.customer_name
    ORDER BY total_revenue DESC
    LIMIT 20
)

SELECT
    ROUND(
        (
            SUM(total_revenue) /
            (
                SELECT SUM(order_amount)
                FROM orders
                WHERE order_status = 'Delivered'
            )
        ) * 100,
        2
    ) AS revenue_percentage
FROM top_customers;

-- Q3. Which acquisition channel brings the most customers?
SELECT
    acquisition_channel,
    COUNT(customer_id) AS total_customers
FROM customer
GROUP BY acquisition_channel
ORDER BY total_customers DESC;

-- Q4.How many repeat customers do we have?
WITH repeat_customers AS
(
    SELECT
        customer_id
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
    HAVING COUNT(order_id) > 1
)
SELECT
    COUNT(customer_id) AS total_repeat_customers
FROM repeat_customers;

-- =========================================
-- 3. Restaurant Analysis
-- =========================================
--  Q1.Which restaurants generate the highest revenue?
SELECT
    restaurant.restaurant_id,
    restaurant.restaurant_name,
    SUM(orders.order_amount) AS total_revenue
FROM restaurant
INNER JOIN orders
    ON restaurant.restaurant_id = orders.restaurant_id
WHERE orders.order_status = 'Delivered'
GROUP BY
    restaurant.restaurant_id,
    restaurant.restaurant_name
ORDER BY total_revenue DESC;

-- Q2.Which restaurants receive the most orders?
SELECT
    restaurant_id,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY restaurant_id
ORDER BY total_orders DESC;

-- Q3.Which cuisines receive the most orders?
SELECT
    restaurant.cuisine,
    COUNT(orders.order_id) AS total_orders
FROM restaurant
INNER JOIN orders
    ON restaurant.restaurant_id = orders.restaurant_id
GROUP BY restaurant.cuisine
ORDER BY total_orders DESC;

-- Q4.Do highly-rated restaurants generate more revenue?
SELECT
    restaurant.avg_rating,
    SUM(orders.order_amount) AS total_revenue
FROM restaurant
INNER JOIN orders
    ON restaurant.restaurant_id = orders.restaurant_id
WHERE orders.order_status = 'Delivered'
GROUP BY restaurant.avg_rating
ORDER BY restaurant.avg_rating DESC;

-- Q5. Which restaurants generate the least revenue?
SELECT
    restaurant.restaurant_name,
    SUM(orders.order_amount) AS total_revenue
FROM restaurant
INNER JOIN orders
    ON restaurant.restaurant_id = orders.restaurant_id
WHERE orders.order_status = 'Delivered'
GROUP BY restaurant.restaurant_id, restaurant.restaurant_name
ORDER BY total_revenue ASC
LIMIT 5;

-- =========================================
-- 4. Coupon Analysis
-- What percentage of orders use coupons?
SELECT
    ROUND(
        SUM(
            CASE
                WHEN discount_amount > 0 THEN 1
                ELSE 0
            END
        ) * 100.0
        / COUNT(order_id),
        2
    ) AS coupon_percentage
FROM orders
WHERE order_status = 'Delivered';

-- =========================================
-- 5.  Cancellation & Refund Analysis
-- Q1. What is the cancellation rate?
SELECT
    ROUND(
        SUM(
            CASE
                WHEN order_status = 'Cancelled' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(order_id),
        2
    ) AS cancellation_rate
FROM orders;

-- Q2. What is the refund rate?
SELECT
    ROUND(
        SUM(
            CASE
                WHEN order_status = 'Refunded' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(order_id),
        2
    ) AS refund_rate
FROM orders;


-- =========================================
-- 6.Customer Churn Analysis
-- =========================================
-- Q1.How many customers have churned?
WITH last_txn AS
(
    SELECT
        MAX(order_timestamp) AS last_txn_date
    FROM orders
),

customer_latest AS
(
    SELECT
        customer_id,
        MAX(order_timestamp) AS last_order
    FROM orders
    GROUP BY customer_id
)

SELECT
    COUNT(last_order) AS churned_customers
FROM customer_latest
CROSS JOIN last_txn
WHERE DATEDIFF(
    last_txn_date, last_order
) > 90;


-- What is the churn rate?
WITH last_txn AS
(
    SELECT
        MAX(order_timestamp) AS last_txn_date
    FROM orders
),

customer_latest AS
(
    SELECT
        customer_id,
        MAX(order_timestamp) AS last_order
    FROM orders
    GROUP BY customer_id
)

SELECT
    ROUND(
        SUM(
            CASE
                WHEN DATEDIFF(last_txn_date, last_order) > 90 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(customer_id),
        2
    ) AS churn_rate
FROM customer_latest
CROSS JOIN last_txn;

-- Q3. Which city has the highest churn?

WITH last_txn AS
(
    SELECT
        MAX(order_timestamp) AS last_txn_date
    FROM orders
),

customer_latest AS
(
    SELECT
        customer_id,
        MAX(order_timestamp) AS last_order
    FROM orders
    GROUP BY customer_id
)

SELECT
    customer.city,
    COUNT(customer.customer_id) AS churned_customers
FROM customer_latest
CROSS JOIN last_txn
INNER JOIN customer
    ON customer_latest.customer_id = customer.customer_id
WHERE DATEDIFF(last_txn_date, last_order) > 90
GROUP BY customer.city
ORDER BY churned_customers DESC
LIMIT 1;



USE Olist

/* ---------- Q11. Repeat purchasers ---------- */
-- Definition: customer_unique_id with MORE THAN ONE qualifying order.
-- Denominator: all customers with at least one qualifying order.
WITH c AS (
    SELECT customer_unique_id,
           COUNT(DISTINCT order_id) AS orders,
           COUNT(DISTINCT CAST(order_purchase_timestamp AS DATE)) AS order_days
    FROM dbo.v_qual_orders
    GROUP BY customer_unique_id
)
SELECT COUNT(*) AS customers,
       SUM(CASE WHEN orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
       CAST(100.0 * SUM(CASE WHEN orders > 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS repeat_pct,
       -- stricter version: orders placed on different days
       SUM(CASE WHEN order_days > 1 THEN 1 ELSE 0 END) AS repeat_on_different_days,
       CAST(100.0 * SUM(CASE WHEN order_days > 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS repeat_pct_different_days
FROM c;
 
-- Distribution of orders per customer
WITH c AS (
    SELECT customer_unique_id, COUNT(DISTINCT order_id) AS orders
    FROM dbo.v_qual_orders
    GROUP BY customer_unique_id
)
SELECT orders AS orders_placed,
       COUNT(*) AS customers,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(6,2)) AS pct_of_customers
FROM c
GROUP BY orders
ORDER BY orders;
 
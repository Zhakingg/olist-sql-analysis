USE Olist

/* ---------- Q14. Delivery performance vs estimated date ---------- */
-- Base: qualifying orders with a valid delivery date.
-- On time = delivered date <= estimated date (date level). Late = delivered date > estimated date.
SELECT COUNT(*) AS delivered_orders,
       SUM(CASE WHEN is_late_day = 0 THEN 1 ELSE 0 END) AS on_time_orders,
       CAST(100.0 * SUM(CASE WHEN is_late_day = 0 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS on_time_pct,
       CAST(100.0 * SUM(CASE WHEN is_late_day = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS late_pct,
       CAST(AVG(CAST(delivery_days AS FLOAT)) AS DECIMAL(6,2)) AS avg_delivery_days,
       CAST(AVG(CAST(DATEDIFF(DAY, order_purchase_timestamp, order_estimated_delivery_date) AS FLOAT)) AS DECIMAL(6,2)) AS avg_promised_days,
       CAST(AVG(CASE WHEN is_late_day = 1
                     THEN CAST(DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) AS FLOAT) END) AS DECIMAL(6,2)) AS avg_days_late_when_late
FROM dbo.v_qual_orders
WHERE is_delivered_valid = 1;
 
-- By state (states with at least 100 delivered orders)
SELECT customer_state,
       COUNT(*) AS delivered_orders,
       CAST(AVG(CAST(delivery_days AS FLOAT)) AS DECIMAL(6,2)) AS avg_delivery_days,
       CAST(100.0 * AVG(CAST(is_late_day AS FLOAT)) AS DECIMAL(5,2)) AS late_pct
FROM dbo.v_qual_orders
WHERE is_delivered_valid = 1
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY late_pct DESC;
 
-- By category (order x category grain, at least 300 orders)
WITH oc AS (SELECT DISTINCT order_id, category FROM dbo.v_qual_items)
SELECT oc.category,
       COUNT(*) AS delivered_orders,
       CAST(AVG(CAST(o.delivery_days AS FLOAT)) AS DECIMAL(6,2)) AS avg_delivery_days,
       CAST(100.0 * AVG(CAST(o.is_late_day AS FLOAT)) AS DECIMAL(5,2)) AS late_pct
FROM oc
JOIN dbo.v_qual_orders o ON o.order_id = oc.order_id
WHERE o.is_delivered_valid = 1
GROUP BY oc.category
HAVING COUNT(*) >= 300
ORDER BY late_pct DESC;
 
-- By month (is late performance getting worse or spiking?)
SELECT order_month,
       COUNT(*) AS delivered_orders,
       CAST(100.0 * AVG(CAST(is_late_day AS FLOAT)) AS DECIMAL(5,2)) AS late_pct
FROM dbo.v_qual_orders
WHERE is_delivered_valid = 1
GROUP BY order_month
ORDER BY order_month;
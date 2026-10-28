USE Olist

/* ---------- Q3. Definition of a completed sale ---------- */
 
-- Funnel from all orders to qualifying orders
SELECT '1. All orders' AS step, COUNT(*) AS orders FROM dbo.orders
UNION ALL SELECT '2. status = delivered', COUNT(*) FROM dbo.orders WHERE order_status = 'delivered'
UNION ALL SELECT '3. ...and has at least one item', COUNT(*) FROM dbo.v_orders_clean
       WHERE order_status = 'delivered' AND is_revenue_order = 1
UNION ALL SELECT '4. ...and purchased Jan 2017 - Aug 2018 (QUALIFYING)', COUNT(*) FROM dbo.v_qual_orders;
 
-- Item revenue sitting in each status (what the definition leaves out)
SELECT o.order_status,
       COUNT(DISTINCT o.order_id) AS orders,
       SUM(i.price) AS item_revenue
FROM dbo.orders o
JOIN dbo.order_items i ON i.order_id = o.order_id
GROUP BY o.order_status
ORDER BY item_revenue DESC;
 
-- Why NULL must not become 0: filling missing delivery dates with 0 drags the average down
SELECT AVG(CAST(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS FLOAT)) AS avg_days_ignoring_nulls,
       AVG(CAST(COALESCE(DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date), 0) AS FLOAT)) AS avg_days_if_nulls_set_to_0
FROM dbo.orders;
Use Olist

/* ---------- Q2. Share of orders by status ---------- */
 
-- Every status present
SELECT order_status,
       COUNT(*) AS orders,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(6,2)) AS pct_of_orders
FROM dbo.orders
GROUP BY order_status
ORDER BY orders DESC;
 
-- Grouped view: delivered / canceled / unavailable / other
SELECT CASE WHEN order_status IN ('delivered','canceled','unavailable') THEN order_status
            ELSE 'other (in progress)' END AS status_group,
       COUNT(*) AS orders,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(6,2)) AS pct_of_orders
FROM dbo.orders
GROUP BY CASE WHEN order_status IN ('delivered','canceled','unavailable') THEN order_status
              ELSE 'other (in progress)' END
ORDER BY orders DESC;
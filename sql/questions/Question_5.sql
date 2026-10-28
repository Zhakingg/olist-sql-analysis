USE Olist

-- Monthly revenue
SELECT order_month,
       COUNT(DISTINCT order_id) AS orders,
       SUM(price) AS item_revenue
FROM dbo.v_qual_items
GROUP BY order_month
ORDER BY order_month;
 
-- Best and weakest month
WITH m AS (
    SELECT order_month, SUM(price) AS revenue FROM dbo.v_qual_items GROUP BY order_month
),
r AS (
    SELECT order_month, revenue,
           RANK() OVER (ORDER BY revenue DESC) AS rk_high,
           RANK() OVER (ORDER BY revenue ASC)  AS rk_low
    FROM m
)
SELECT 'Best month' AS label, order_month, revenue FROM r WHERE rk_high = 1
UNION ALL
SELECT 'Weakest month', order_month, revenue FROM r WHERE rk_low = 1;
 
-- Quarterly revenue (months_in_data < 3 means a partial quarter)
SELECT YEAR(order_month) AS yr,
       DATEPART(QUARTER, order_month) AS qtr,
       COUNT(DISTINCT order_month) AS months_in_data,
       COUNT(DISTINCT order_id) AS orders,
       SUM(price) AS item_revenue
FROM dbo.v_qual_items
GROUP BY YEAR(order_month), DATEPART(QUARTER, order_month)
ORDER BY yr, qtr;
 
-- Best and weakest COMPLETE quarter
WITH q AS (
    SELECT YEAR(order_month) AS yr, DATEPART(QUARTER, order_month) AS qtr, SUM(price) AS revenue
    FROM dbo.v_qual_items
    GROUP BY YEAR(order_month), DATEPART(QUARTER, order_month)
    HAVING COUNT(DISTINCT order_month) = 3
),
r AS (
    SELECT yr, qtr, revenue,
           RANK() OVER (ORDER BY revenue DESC) AS rk_high,
           RANK() OVER (ORDER BY revenue ASC)  AS rk_low
    FROM q
)
SELECT 'Best quarter' AS label, yr, qtr, revenue FROM r WHERE rk_high = 1
UNION ALL
SELECT 'Weakest complete quarter', yr, qtr, revenue FROM r WHERE rk_low = 1;
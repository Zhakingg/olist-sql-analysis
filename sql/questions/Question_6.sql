USE Olist

/* ---------- Q6. Month-over-month revenue growth (CTE + LAG) ---------- */
-- First month has no prior month -> NULL. NULLIF avoids divide-by-zero.
WITH m AS (
    SELECT order_month, SUM(price) AS revenue
    FROM dbo.v_qual_items
    GROUP BY order_month
),
g AS (
    SELECT order_month, revenue,
           LAG(revenue) OVER (ORDER BY order_month) AS prev_revenue
    FROM m
)
SELECT order_month,
       revenue,
       prev_revenue,
       CAST(100.0 * (revenue - prev_revenue) / NULLIF(prev_revenue, 0) AS DECIMAL(10,2)) AS mom_growth_pct
FROM g
ORDER BY order_month;
-- REPORT NOTE: early-2017 growth rates look huge because the base is small.
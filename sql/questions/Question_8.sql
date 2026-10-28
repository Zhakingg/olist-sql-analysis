USE Olist

/* ---------- Q8. Top 10 categories by item revenue ---------- */
WITH c AS (
    SELECT category,
           SUM(price) AS revenue,
           COUNT(DISTINCT order_id) AS orders,
           COUNT(*) AS units
    FROM dbo.v_qual_items
    GROUP BY category
)
SELECT TOP 10
       category, revenue, orders, units,
       CAST(100.0 * revenue / SUM(revenue) OVER () AS DECIMAL(5,2)) AS pct_of_total_revenue,
       CAST(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC ROWS UNBOUNDED PRECEDING)
                  / SUM(revenue) OVER () AS DECIMAL(5,2)) AS cumulative_pct
FROM c
ORDER BY revenue DESC;
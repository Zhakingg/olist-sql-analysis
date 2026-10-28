USE Olist

/* ---------- Q7. Revenue and AOV by state ---------- */
WITH s AS (
    SELECT customer_state,
           COUNT(*) AS orders,
           SUM(revenue) AS revenue,
           SUM(revenue) * 1.0 / COUNT(*) AS aov
    FROM dbo.v_qual_order_rev
    GROUP BY customer_state
)
SELECT customer_state,
       orders,
       revenue,
       CAST(100.0 * revenue / SUM(revenue) OVER () AS DECIMAL(5,2)) AS pct_of_revenue,
       CAST(aov AS DECIMAL(10,2)) AS aov,
       RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
       RANK() OVER (ORDER BY aov DESC)     AS aov_rank
FROM s
ORDER BY revenue DESC;
-- REPORT NOTE: states with few orders have unstable AOV; read aov_rank alongside the orders column.
 
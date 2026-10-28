USE Olist

/* ---------- Q12. Top 20 customers by item spend (anonymised IDs) ---------- */
SELECT TOP 20
       ROW_NUMBER() OVER (ORDER BY SUM(revenue) DESC) AS spend_rank,
       customer_unique_id,
       COUNT(*) AS orders,
       SUM(revenue) AS total_spend,
       CAST(SUM(revenue) * 1.0 / COUNT(*) AS DECIMAL(10,2)) AS aov
FROM dbo.v_qual_order_rev
GROUP BY customer_unique_id
ORDER BY total_spend DESC;
 
-- How much of total revenue do the top 20 represent?
WITH c AS (
    SELECT customer_unique_id, SUM(revenue) AS spend
    FROM dbo.v_qual_order_rev
    GROUP BY customer_unique_id
),
r AS (
    SELECT spend, ROW_NUMBER() OVER (ORDER BY spend DESC, customer_unique_id) AS rn FROM c
)
SELECT CAST(100.0 * SUM(CASE WHEN rn <= 20 THEN spend END) / SUM(spend) AS DECIMAL(6,3)) AS top20_pct_of_revenue
FROM r;
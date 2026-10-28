USE Olist

-- Evidence A: retention. Repeat vs one-time customers.
WITH c AS (
    SELECT customer_unique_id, COUNT(*) AS orders, SUM(revenue) AS spend
    FROM dbo.v_qual_order_rev
    GROUP BY customer_unique_id
)
SELECT CASE WHEN orders > 1 THEN 'Repeat' ELSE 'One-time' END AS customer_type,
       COUNT(*) AS customers,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct_customers,
       SUM(spend) AS revenue,
       CAST(100.0 * SUM(spend) / SUM(SUM(spend)) OVER () AS DECIMAL(5,2)) AS pct_revenue,
       CAST(AVG(spend) AS DECIMAL(10,2)) AS avg_spend_per_customer
FROM c
GROUP BY CASE WHEN orders > 1 THEN 'Repeat' ELSE 'One-time' END;
-- Also use the 'At-Risk High-Value Customers' row from Q13 (customers, revenue, avg_spend).

-- Evidence B: delivery reliability. Review score of late vs on-time orders.
SELECT CASE WHEN o.is_late_day = 1 THEN 'Late' ELSE 'On time' END AS delivery,
       COUNT(*) AS orders,
       CAST(AVG(CAST(r.review_score AS FLOAT)) AS DECIMAL(4,2)) AS avg_review,
       CAST(100.0 * SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END)
                  / NULLIF(COUNT(r.review_score), 0) AS DECIMAL(5,2)) AS pct_1_2_star
FROM dbo.v_qual_orders o
JOIN dbo.v_reviews_dedup r ON r.order_id = o.order_id
WHERE o.is_delivered_valid = 1
GROUP BY CASE WHEN o.is_late_day = 1 THEN 'Late' ELSE 'On time' END;
-- Paired with the worst states from the Q14 state table.

-- Evidence C: revenue concentration (categories and the top state).
WITH c AS (
    SELECT category, SUM(price) AS revenue FROM dbo.v_qual_items GROUP BY category
),
r AS (
    SELECT revenue, ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rn FROM c
)
SELECT CAST(100.0 * SUM(CASE WHEN rn <= 5  THEN revenue END) / SUM(revenue) AS DECIMAL(5,2)) AS top5_categories_pct,
       CAST(100.0 * SUM(CASE WHEN rn <= 10 THEN revenue END) / SUM(revenue) AS DECIMAL(5,2)) AS top10_categories_pct
FROM r;
-- Pair with the Q10 'flag' column (large categories flagged for weak reviews or late deliveries)
-- and the Q7 state table (share of revenue from the top state vs the rest).
USE Olist

/* ---------- Q13. RFM segmentation with NTILE ---------- */
-- Reference date = day after the last qualifying order (NOT today's date),
--   so Recency is measured inside the dataset's own timeline.
-- R score: NTILE(5) on recency, 5 = most recent.
-- M score: NTILE(5) on total spend, 5 = highest.
-- F score: rule based (1 order = 1, 2 orders = 3, 3+ orders = 5), because most
--   customers have exactly one order and NTILE would split identical values arbitrarily.
-- customer_unique_id is the NTILE tie-breaker, so results are reproducible.

CREATE OR ALTER VIEW dbo.v_rfm AS
WITH ref AS (
    SELECT DATEADD(DAY, 1, CAST(MAX(order_purchase_timestamp) AS DATE)) AS ref_date
    FROM dbo.v_qual_orders
),
cust AS (
    SELECT o.customer_unique_id,
           DATEDIFF(DAY, MAX(o.order_purchase_timestamp), MAX(ref.ref_date)) AS recency_days,
           COUNT(DISTINCT o.order_id) AS frequency,
           SUM(r.revenue) AS monetary
    FROM dbo.v_qual_orders o
    JOIN dbo.v_qual_order_rev r ON r.order_id = o.order_id
    CROSS JOIN ref
    GROUP BY o.customer_unique_id
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC, customer_unique_id) AS r_score,
           CASE WHEN frequency >= 3 THEN 5 WHEN frequency = 2 THEN 3 ELSE 1 END AS f_score,
           NTILE(5) OVER (ORDER BY monetary, customer_unique_id) AS m_score
    FROM cust
)
SELECT *,
       CASE WHEN r_score >= 4 AND f_score >= 3 THEN 'Champions'
            WHEN f_score >= 3 AND r_score >= 2 THEN 'Loyal Customers'
            WHEN r_score <= 2 AND m_score >= 4 THEN 'At-Risk High-Value Customers'
            WHEN r_score >= 4                  THEN 'Recent One-time Buyers'
            WHEN r_score = 3                   THEN 'Needs Attention'
            ELSE 'Hibernating / Lost' END AS segment
FROM scored;

 
-- Segment summary
SELECT segment,
       COUNT(*) AS customers,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct_customers,
       SUM(monetary) AS revenue,
       CAST(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER () AS DECIMAL(5,2)) AS pct_revenue,
       CAST(AVG(CAST(recency_days AS FLOAT)) AS DECIMAL(7,1)) AS avg_recency_days,
       CAST(AVG(CAST(frequency AS FLOAT)) AS DECIMAL(5,2))    AS avg_orders,
       CAST(AVG(monetary) AS DECIMAL(10,2))                   AS avg_spend
FROM dbo.v_rfm
GROUP BY segment
ORDER BY revenue DESC;
 
-- Scoring bands (document these in the report)
SELECT 'Recency (days)' AS dimension, r_score AS score,
       MIN(recency_days) AS min_value, MAX(recency_days) AS max_value, COUNT(*) AS customers
FROM dbo.v_rfm GROUP BY r_score
UNION ALL
SELECT 'Monetary (BRL)', m_score, MIN(monetary), MAX(monetary), COUNT(*)
FROM dbo.v_rfm GROUP BY m_score
ORDER BY dimension, score;
-- REPORT NOTE (limitations): historical data ends Aug 2018, so "recency" is relative to that date;
-- ~97% of customers have one order, so frequency separates few customers; there are no customer
-- attributes (age, channel) and IDs are anonymised; the segments are descriptive, not predictive.
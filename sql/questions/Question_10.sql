/* ---------- Q10. High-volume categories with weak reviews or slow delivery ---------- */
 
-- Grain check: joining raw reviews inflates revenue; the deduplicated view does not
SELECT (SELECT SUM(price) FROM dbo.v_qual_items) AS revenue_items_only,
       (SELECT SUM(i.price) FROM dbo.v_qual_items i
          LEFT JOIN dbo.order_reviews r ON r.order_id = i.order_id) AS revenue_after_RAW_review_join,
       (SELECT SUM(i.price) FROM dbo.v_qual_items i
          LEFT JOIN dbo.v_reviews_dedup r ON r.order_id = i.order_id) AS revenue_after_DEDUP_review_join;
 
-- Grain used below: one row per order x category, then 1 review and 1 delivery record per order
WITH oc AS (
    SELECT order_id, category, SUM(price) AS revenue, COUNT(*) AS units
    FROM dbo.v_qual_items
    GROUP BY order_id, category
),
cat AS (
    SELECT oc.category,
           COUNT(*)                                       AS orders,
           SUM(oc.units)                                  AS units,
           SUM(oc.revenue)                                AS revenue,
           AVG(CAST(r.review_score AS FLOAT))             AS avg_review,
           100.0 * SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END)
                 / NULLIF(COUNT(r.review_score), 0)       AS pct_1_2_star,
           AVG(CAST(o.delivery_days AS FLOAT))            AS avg_delivery_days,
           100.0 * AVG(CAST(o.is_late_day AS FLOAT))      AS late_rate_pct
    FROM oc
    JOIN dbo.v_qual_orders o ON o.order_id = oc.order_id
    LEFT JOIN dbo.v_reviews_dedup r ON r.order_id = oc.order_id
    GROUP BY oc.category
),
bench AS (
    SELECT AVG(CAST(r.review_score AS FLOAT))        AS bench_review,
           100.0 * AVG(CAST(o.is_late_day AS FLOAT)) AS bench_late
    FROM dbo.v_qual_orders o
    LEFT JOIN dbo.v_reviews_dedup r ON r.order_id = o.order_id
),
ranked AS (
    SELECT *, RANK() OVER (ORDER BY orders DESC) AS volume_rank
    FROM cat
)
SELECT k.volume_rank, k.category, k.orders, k.revenue,
       CAST(k.avg_review AS DECIMAL(4,2))        AS avg_review,
       CAST(b.bench_review AS DECIMAL(4,2))      AS benchmark_review,
       CAST(k.pct_1_2_star AS DECIMAL(5,2))      AS pct_1_2_star,
       CAST(k.avg_delivery_days AS DECIMAL(5,1)) AS avg_delivery_days,
       CAST(k.late_rate_pct AS DECIMAL(5,2))     AS late_rate_pct,
       CAST(b.bench_late AS DECIMAL(5,2))        AS benchmark_late_pct,
       -- rule: weak = at least 0.10 stars below benchmark; late = at least 1 point above benchmark
       CASE WHEN k.avg_review <= b.bench_review - 0.10 AND k.late_rate_pct >= b.bench_late + 1.0
                 THEN 'Weak reviews + late deliveries'
            WHEN k.avg_review <= b.bench_review - 0.10 THEN 'Weak reviews'
            WHEN k.late_rate_pct >= b.bench_late + 1.0 THEN 'Late deliveries'
            ELSE 'OK' END AS flag
FROM ranked k
CROSS JOIN bench b
WHERE k.volume_rank <= 20
ORDER BY k.volume_rank;
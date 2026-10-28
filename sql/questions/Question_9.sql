Use Olist

/* ---------- Q9. Products: units rank vs revenue rank ---------- */
WITH p AS (
    SELECT product_id,
           MAX(category) AS category,
           COUNT(*) AS units_sold,
           SUM(price) AS revenue,
           CAST(AVG(price) AS DECIMAL(10,2)) AS avg_unit_price
    FROM dbo.v_qual_items
    GROUP BY product_id
),
r AS (
    SELECT *,
           RANK() OVER (ORDER BY units_sold DESC) AS units_rank,
           RANK() OVER (ORDER BY revenue DESC)    AS revenue_rank
    FROM p
)
SELECT product_id, category, units_sold, revenue, avg_unit_price, units_rank, revenue_rank
FROM r
WHERE units_rank <= 10 OR revenue_rank <= 10
ORDER BY units_rank, revenue_rank;
-- REPORT NOTE: rankings differ because of unit price. Cheap items win on units, expensive items win on revenue.
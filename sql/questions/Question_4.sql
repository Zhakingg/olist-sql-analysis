USE Olist

/* ---------- Q4. Overall sales KPIs ---------- */
-- Orders         = distinct order_id (qualifying orders)
-- Customers      = distinct customer_unique_id
-- Item revenue   = SUM(price), freight excluded
-- AOV            = item revenue / distinct orders
-- Units          = count of order_items rows
SELECT COUNT(DISTINCT order_id)            AS orders,
       COUNT(DISTINCT customer_unique_id)  AS customers,
       SUM(price)                          AS item_revenue,
       CAST(SUM(price) * 1.0 / COUNT(DISTINCT order_id) AS DECIMAL(10,2)) AS aov,
       COUNT(*)                            AS units_sold,
       CAST(1.0 * COUNT(*) / COUNT(DISTINCT order_id) AS DECIMAL(6,2)) AS units_per_order,
       CAST(SUM(price) * 1.0 / COUNT(DISTINCT customer_unique_id) AS DECIMAL(10,2)) AS revenue_per_customer,
       SUM(freight_value)                  AS freight_collected
FROM dbo.v_qual_items;
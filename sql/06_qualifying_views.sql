USE Olist;
GO

/* =====================================================================
   06. QUALIFYING-ORDER VIEWS (run AFTER 05_data_cleaning_final_views.sql)
   Q3 to Q15 read from these three views.
   Completed sale = delivered + at least one item + purchased Jan 2017 - Aug 2018
   ===================================================================== */

CREATE OR ALTER VIEW dbo.v_qual_orders AS
SELECT oc.*,
       -- on-time test at DATE level, because the estimate is a date, not a timestamp
       CASE WHEN oc.is_delivered_valid = 1
            THEN CASE WHEN CAST(oc.order_delivered_customer_date AS DATE)
                           > CAST(oc.order_estimated_delivery_date AS DATE)
                      THEN 1 ELSE 0 END
       END AS is_late_day
FROM dbo.v_orders_clean oc
WHERE oc.order_status = 'delivered'
  AND oc.is_revenue_order = 1
  AND oc.in_window = 1;
GO

-- Qualifying items (one row per unit sold)
CREATE OR ALTER VIEW dbo.v_qual_items AS
SELECT q.order_id, q.customer_unique_id, q.customer_state, q.order_month,
       q.order_purchase_timestamp,
       i.order_item_id, i.product_id, i.seller_id, i.price, i.freight_value,
       pc.category
FROM dbo.v_qual_orders q
JOIN dbo.order_items i ON i.order_id = q.order_id
LEFT JOIN dbo.v_products_clean pc ON pc.product_id = i.product_id;
GO

-- Qualifying orders with revenue (one row per order)
CREATE OR ALTER VIEW dbo.v_qual_order_rev AS
SELECT order_id, customer_unique_id, customer_state, order_month,
       order_purchase_timestamp,
       SUM(price) AS revenue,
       COUNT(*)   AS units
FROM dbo.v_qual_items
GROUP BY order_id, customer_unique_id, customer_state, order_month, order_purchase_timestamp;
GO

-- Sanity check (record these numbers in your report)
SELECT COUNT(*) AS qualifying_orders FROM dbo.v_qual_orders;
SELECT COUNT(DISTINCT order_id) AS orders, SUM(price) AS item_revenue FROM dbo.v_qual_items;
SELECT COUNT(*) - COUNT(DISTINCT order_id) AS dup_orders FROM dbo.v_qual_order_rev;   -- must be 0

USE Olist


/* ---------- 1. Fix reference data ---------- */
DELETE FROM dbo.product_category_name_translation
WHERE product_category_name = 'product_category_name';      -- stray header row

IF NOT EXISTS (SELECT 1 FROM dbo.product_category_name_translation WHERE product_category_name = 'pc_gamer')
    INSERT INTO dbo.product_category_name_translation VALUES ('pc_gamer', 'pc_gamer');
IF NOT EXISTS (SELECT 1 FROM dbo.product_category_name_translation WHERE product_category_name = 'portateis_cozinha_e_preparadores_de_alimentos')
    INSERT INTO dbo.product_category_name_translation
    VALUES ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_food_preparers');


/* ---------- 2. Clean views ---------- */
CREATE OR ALTER VIEW dbo.v_products_clean AS
SELECT p.product_id,
       COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       p.product_weight_g, p.product_photos_qty
FROM dbo.products p
LEFT JOIN dbo.product_category_name_translation t
       ON t.product_category_name = p.product_category_name;


-- One review per order (latest wins)
CREATE OR ALTER VIEW dbo.v_reviews_dedup AS
SELECT order_id, review_score, review_creation_date, review_answer_timestamp
FROM (
    SELECT order_id, review_score, review_creation_date, review_answer_timestamp,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_creation_date DESC, review_answer_timestamp DESC) AS rn
    FROM dbo.order_reviews
) x
WHERE rn = 1;


-- One row per order, with validity flags
CREATE OR ALTER VIEW dbo.v_orders_clean AS
SELECT o.order_id, o.customer_id, c.customer_unique_id, c.customer_city, c.customer_state,
       o.order_status, o.order_purchase_timestamp, o.order_approved_at,
       o.order_delivered_carrier_date, o.order_delivered_customer_date, o.order_estimated_delivery_date,
       DATEFROMPARTS(YEAR(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp), 1) AS order_month,

       -- in the agreed analysis window (Jan 2017 - Aug 2018)
       CASE WHEN o.order_purchase_timestamp >= '2017-01-01'
             AND o.order_purchase_timestamp <  '2018-09-01' THEN 1 ELSE 0 END AS in_window,

       -- a real sale: has items and was not canceled/unavailable
       CASE WHEN o.order_status NOT IN ('canceled','unavailable')
             AND EXISTS (SELECT 1 FROM dbo.order_items i WHERE i.order_id = o.order_id)
            THEN 1 ELSE 0 END AS is_revenue_order,

       -- usable for delivery metrics
       CASE WHEN o.order_status = 'delivered'
             AND o.order_delivered_customer_date IS NOT NULL THEN 1 ELSE 0 END AS is_delivered_valid,

       CASE WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
            THEN DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) END AS delivery_days,

       CASE WHEN o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
            THEN CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END
       END AS is_late
FROM dbo.orders o
JOIN dbo.customers c ON c.customer_id = o.customer_id;


-- Item-level revenue base (revenue = item price, freight kept separate)
CREATE OR ALTER VIEW dbo.v_sales_items AS
SELECT oc.order_id, oc.customer_unique_id, oc.customer_state, oc.order_month,
       oc.order_purchase_timestamp, oc.in_window,
       i.order_item_id, i.product_id, i.seller_id,
       i.price, i.freight_value, pc.category
FROM dbo.order_items i
JOIN dbo.v_orders_clean oc ON oc.order_id = i.order_id AND oc.is_revenue_order = 1
LEFT JOIN dbo.v_products_clean pc ON pc.product_id = i.product_id;


-- Order-level totals
CREATE OR ALTER VIEW dbo.v_order_revenue AS
SELECT order_id, customer_unique_id, order_month, in_window,
       SUM(price) AS revenue, SUM(freight_value) AS freight, COUNT(*) AS items
FROM dbo.v_sales_items
GROUP BY order_id, customer_unique_id, order_month, in_window;


/* ---------- 3. Sanity checks ---------- */
SELECT COUNT(*) AS orders_all,
       SUM(is_revenue_order)   AS revenue_orders,
       SUM(is_delivered_valid) AS delivered_valid,
       SUM(in_window)          AS in_window
FROM dbo.v_orders_clean;

SELECT COUNT(*) AS n_orders, SUM(revenue) AS total_revenue
FROM dbo.v_order_revenue WHERE in_window = 1;

-- Must be 1 row per order (both should be 0)
SELECT COUNT(*) - COUNT(DISTINCT order_id) AS dup_orders FROM dbo.v_orders_clean;
SELECT COUNT(*) - COUNT(DISTINCT order_id) AS dup_reviews FROM dbo.v_reviews_dedup;
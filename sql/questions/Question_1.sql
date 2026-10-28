Use Olist

-- 1a. Row counts (use whichever geolocation table holds the full file)
SELECT 'customers' AS tbl, COUNT(*) AS n FROM dbo.customers UNION ALL
SELECT 'geolocation',      COUNT(*) FROM dbo.geolocation_main UNION ALL
SELECT 'orders',           COUNT(*) FROM dbo.orders UNION ALL
SELECT 'order_items',      COUNT(*) FROM dbo.order_items UNION ALL
SELECT 'order_payments',   COUNT(*) FROM dbo.order_payments UNION ALL
SELECT 'order_reviews',    COUNT(*) FROM dbo.order_reviews UNION ALL
SELECT 'products',         COUNT(*) FROM dbo.products UNION ALL
SELECT 'sellers',          COUNT(*) FROM dbo.sellers UNION ALL
SELECT 'category_translation', COUNT(*) FROM dbo.product_category_name_translation;

-- 1b. Missing values in important fields
WITH n AS (
    SELECT 'orders.order_approved_at' AS field, COUNT(*) AS total_rows,
           SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS null_rows FROM dbo.orders
    UNION ALL SELECT 'orders.order_delivered_carrier_date', COUNT(*),
           SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) FROM dbo.orders
    UNION ALL SELECT 'orders.order_delivered_customer_date', COUNT(*),
           SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) FROM dbo.orders
    UNION ALL SELECT 'orders.order_estimated_delivery_date', COUNT(*),
           SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) FROM dbo.orders
    UNION ALL SELECT 'customers.customer_unique_id', COUNT(*),
           SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) FROM dbo.customers
    UNION ALL SELECT 'order_items.price', COUNT(*),
           SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) FROM dbo.order_items
    UNION ALL SELECT 'order_items.freight_value', COUNT(*),
           SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) FROM dbo.order_items
    UNION ALL SELECT 'order_payments.payment_value', COUNT(*),
           SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) FROM dbo.order_payments
    UNION ALL SELECT 'order_reviews.review_score', COUNT(*),
           SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) FROM dbo.order_reviews
    UNION ALL SELECT 'order_reviews.review_comment_message', COUNT(*),
           SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) FROM dbo.order_reviews
    UNION ALL SELECT 'products.product_category_name', COUNT(*),
           SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) FROM dbo.products
    UNION ALL SELECT 'products.product_weight_g', COUNT(*),
           SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) FROM dbo.products
)
SELECT field, total_rows, null_rows,
       CAST(100.0 * null_rows / total_rows AS DECIMAL(6,2)) AS null_pct
FROM n
ORDER BY null_pct DESC;

-- 1c. Key uniqueness and duplicates
SELECT 'orders (order_id)' AS key_checked, COUNT(*) AS total_rows,
       COUNT(DISTINCT order_id) AS distinct_keys,
       COUNT(*) - COUNT(DISTINCT order_id) AS duplicates
FROM dbo.orders
UNION ALL SELECT 'customers (customer_id)', COUNT(*), COUNT(DISTINCT customer_id),
       COUNT(*) - COUNT(DISTINCT customer_id) FROM dbo.customers
UNION ALL SELECT 'products (product_id)', COUNT(*), COUNT(DISTINCT product_id),
       COUNT(*) - COUNT(DISTINCT product_id) FROM dbo.products
UNION ALL SELECT 'sellers (seller_id)', COUNT(*), COUNT(DISTINCT seller_id),
       COUNT(*) - COUNT(DISTINCT seller_id) FROM dbo.sellers
UNION ALL SELECT 'order_items (order_id, order_item_id)', COUNT(*),
       (SELECT COUNT(*) FROM (SELECT DISTINCT order_id, order_item_id FROM dbo.order_items) d),
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT order_id, order_item_id FROM dbo.order_items) d)
FROM dbo.order_items
UNION ALL SELECT 'order_payments (order_id, payment_sequential)', COUNT(*),
       (SELECT COUNT(*) FROM (SELECT DISTINCT order_id, payment_sequential FROM dbo.order_payments) d),
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT order_id, payment_sequential FROM dbo.order_payments) d)
FROM dbo.order_payments
UNION ALL SELECT 'order_reviews (review_id)  - not a clean key', COUNT(*), COUNT(DISTINCT review_id),
       COUNT(*) - COUNT(DISTINCT review_id) FROM dbo.order_reviews
UNION ALL SELECT 'order_reviews (order_id)   - orders with >1 review', COUNT(*), COUNT(DISTINCT order_id),
       COUNT(*) - COUNT(DISTINCT order_id) FROM dbo.order_reviews
UNION ALL SELECT 'translation (category name)', COUNT(*), COUNT(DISTINCT product_category_name),
       COUNT(*) - COUNT(DISTINCT product_category_name) FROM dbo.product_category_name_translation;
 
-- geolocation: many rows per zip prefix by design, plus exact duplicate rows
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT geolocation_zip_code_prefix) AS distinct_zip_prefixes,
       COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM dbo.geolocation_main) d) AS exact_duplicate_rows
FROM dbo.geolocation_main;
 
-- customer_id is per order; customer_unique_id is the real customer
SELECT COUNT(DISTINCT customer_id) AS customer_ids,
       COUNT(DISTINCT customer_unique_id) AS real_customers
FROM dbo.customers;

-- 1d. Invalid or inconsistent values (issue_rows = 0 is good)
SELECT check_name, issue_rows
FROM (
    SELECT 'order_items: price <= 0' AS check_name, COUNT(*) AS issue_rows FROM dbo.order_items WHERE price <= 0
    UNION ALL SELECT 'order_items: freight_value < 0', COUNT(*) FROM dbo.order_items WHERE freight_value < 0
    UNION ALL SELECT 'order_items: order_item_id < 1', COUNT(*) FROM dbo.order_items WHERE order_item_id < 1
    UNION ALL SELECT 'order_payments: payment_value < 0', COUNT(*) FROM dbo.order_payments WHERE payment_value < 0
    UNION ALL SELECT 'order_payments: payment_value = 0', COUNT(*) FROM dbo.order_payments WHERE payment_value = 0
    UNION ALL SELECT 'order_payments: installments < 1', COUNT(*) FROM dbo.order_payments WHERE payment_installments < 1
    UNION ALL SELECT 'order_reviews: score outside 1-5', COUNT(*) FROM dbo.order_reviews WHERE review_score NOT BETWEEN 1 AND 5
    UNION ALL SELECT 'products: weight <= 0', COUNT(*) FROM dbo.products WHERE product_weight_g <= 0
    UNION ALL SELECT 'orders: approved before purchase', COUNT(*) FROM dbo.orders WHERE order_approved_at < order_purchase_timestamp
    UNION ALL SELECT 'orders: carrier pickup before approval', COUNT(*) FROM dbo.orders WHERE order_delivered_carrier_date < order_approved_at
    UNION ALL SELECT 'orders: customer delivery before carrier pickup', COUNT(*) FROM dbo.orders WHERE order_delivered_customer_date < order_delivered_carrier_date
    UNION ALL SELECT 'orders: delivered before purchase', COUNT(*) FROM dbo.orders WHERE order_delivered_customer_date < order_purchase_timestamp
    UNION ALL SELECT 'orders: estimate before purchase', COUNT(*) FROM dbo.orders WHERE order_estimated_delivery_date < order_purchase_timestamp
    UNION ALL SELECT 'orders: status delivered but no delivery date', COUNT(*) FROM dbo.orders
           WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL
    UNION ALL SELECT 'orders: status canceled but has delivery date', COUNT(*) FROM dbo.orders
           WHERE order_status = 'canceled' AND order_delivered_customer_date IS NOT NULL
    UNION ALL SELECT 'orders: in-progress status but has delivery date', COUNT(*) FROM dbo.orders
           WHERE order_status NOT IN ('delivered','canceled') AND order_delivered_customer_date IS NOT NULL
    UNION ALL SELECT 'orders: no items at all', COUNT(*) FROM dbo.orders o
           WHERE NOT EXISTS (SELECT 1 FROM dbo.order_items i WHERE i.order_id = o.order_id)
    UNION ALL SELECT 'orders: no payment record', COUNT(*) FROM dbo.orders o
           WHERE NOT EXISTS (SELECT 1 FROM dbo.order_payments p WHERE p.order_id = o.order_id)
) x
ORDER BY issue_rows DESC;
-- REPORT NOTE: the dataset has no quantity column, so quantity checks apply to order_item_id.
-- Flag, do not delete: date-sequence anomalies are logged and handled by the qualifying-order rules.
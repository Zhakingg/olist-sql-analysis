USE Olist

SELECT * FROM dbo.product_category_name_translation
WHERE product_category_name = 'product_category_name';

DELETE FROM dbo.product_category_name_translation
WHERE product_category_name = 'product_category_name';

SELECT o.order_status, COUNT(*) AS n
FROM dbo.orders o
WHERE NOT EXISTS (SELECT 1 FROM dbo.order_items i WHERE i.order_id = o.order_id)
GROUP BY o.order_status ORDER BY n DESC;

SELECT order_id, order_status, order_delivered_customer_date
FROM dbo.orders
WHERE (order_status = 'delivered' AND order_delivered_customer_date IS NULL)
   OR (order_status = 'canceled'  AND order_delivered_customer_date IS NOT NULL);

SELECT o.order_id, o.order_status FROM dbo.orders o
WHERE NOT EXISTS (SELECT 1 FROM dbo.order_payments p WHERE p.order_id = o.order_id);

SELECT payment_type, COUNT(*) AS n FROM dbo.order_payments WHERE payment_value = 0 GROUP BY payment_type;

WITH i AS (SELECT order_id, SUM(price + freight_value) AS item_total FROM dbo.order_items GROUP BY order_id),
     p AS (SELECT order_id, SUM(payment_value) AS pay_total FROM dbo.order_payments GROUP BY order_id)
SELECT COUNT(*) AS orders_compared,
       SUM(CASE WHEN ABS(i.item_total - p.pay_total) > 1 THEN 1 ELSE 0 END) AS mismatches,
       SUM(CASE WHEN p.pay_total - i.item_total > 1 THEN 1 ELSE 0 END)      AS paid_more,
       SUM(CASE WHEN i.item_total - p.pay_total > 1 THEN 1 ELSE 0 END)      AS paid_less
FROM i JOIN p ON p.order_id = i.order_id;

SELECT FORMAT(order_purchase_timestamp,'yyyy-MM') AS ym, COUNT(*) AS orders
FROM dbo.orders GROUP BY FORMAT(order_purchase_timestamp,'yyyy-MM') ORDER BY ym;

-- customer_id vs customer_unique_id
SELECT COUNT(DISTINCT customer_id) AS customer_ids,
       COUNT(DISTINCT customer_unique_id) AS real_customers
FROM dbo.customers;

INSERT INTO dbo.product_category_name_translation VALUES
 ('pc_gamer','pc_gamer'),
 ('portateis_cozinha_e_preparadores_de_alimentos','portable_kitchen_food_preparers');

CREATE OR ALTER VIEW dbo.v_products_clean AS
SELECT p.product_id,
       COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       p.product_weight_g, p.product_photos_qty
FROM dbo.products p
LEFT JOIN dbo.product_category_name_translation t
       ON t.product_category_name = p.product_category_name;
USE Olist

-- Orphan keys (all should return 0)
SELECT COUNT(*) FROM dbo.orders o LEFT JOIN dbo.customers c ON o.customer_id = c.customer_id WHERE c.customer_id IS NULL;
SELECT COUNT(*) FROM dbo.order_items i LEFT JOIN dbo.orders o ON i.order_id = o.order_id WHERE o.order_id IS NULL;
SELECT COUNT(*) FROM dbo.order_items i LEFT JOIN dbo.products p ON i.product_id = p.product_id WHERE p.product_id IS NULL;
SELECT COUNT(*) FROM dbo.order_items i LEFT JOIN dbo.sellers s ON i.seller_id = s.seller_id WHERE s.seller_id IS NULL;

-- Orders with no items / no payments
SELECT COUNT(*) FROM dbo.orders o WHERE NOT EXISTS (SELECT 1 FROM dbo.order_items i WHERE i.order_id = o.order_id);
SELECT COUNT(*) FROM dbo.orders o WHERE NOT EXISTS (SELECT 1 FROM dbo.order_payments p WHERE p.order_id = o.order_id);

-- Range checks
SELECT MIN(price) AS min_price, MAX(price) AS max_price, MIN(freight_value) AS min_freight FROM dbo.order_items;
SELECT MIN(review_score) AS min_s, MAX(review_score) AS max_s FROM dbo.order_reviews;   -- expect 1 to 5
SELECT MIN(payment_value) AS min_pay FROM dbo.order_payments;                            -- 0 values may exist
SELECT MIN(order_purchase_timestamp) AS first_order, MAX(order_purchase_timestamp) AS last_order FROM dbo.orders;

-- Illogical dates
SELECT COUNT(*) FROM dbo.orders WHERE order_delivered_customer_date < order_purchase_timestamp;
SELECT COUNT(*) FROM dbo.orders WHERE order_approved_at < order_purchase_timestamp;

-- Products with no English category translation
SELECT COUNT(*) FROM dbo.products p
LEFT JOIN dbo.product_category_name_translation t ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL AND t.product_category_name IS NULL;

-- Do payments reconcile with items?
SELECT TOP 10 o.order_id, i.item_total, p.pay_total
FROM dbo.orders o
JOIN (SELECT order_id, SUM(price + freight_value) AS item_total FROM dbo.order_items GROUP BY order_id) i ON i.order_id = o.order_id
JOIN (SELECT order_id, SUM(payment_value) AS pay_total FROM dbo.order_payments GROUP BY order_id) p ON p.order_id = o.order_id
WHERE ABS(i.item_total - p.pay_total) > 1;
SELECT 'customers' AS tbl, COUNT(*) AS n FROM dbo.customers UNION ALL
SELECT 'geolocation', COUNT(*) FROM dbo.geolocation_main UNION ALL
SELECT 'orders', COUNT(*) FROM dbo.orders UNION ALL
SELECT 'order_items', COUNT(*) FROM dbo.order_items UNION ALL
SELECT 'order_payments', COUNT(*) FROM dbo.order_payments UNION ALL
SELECT 'order_reviews', COUNT(*) FROM dbo.order_reviews UNION ALL
SELECT 'products', COUNT(*) FROM dbo.products UNION ALL
SELECT 'sellers', COUNT(*) FROM dbo.sellers UNION ALL
SELECT 'category_translation', COUNT(*) FROM dbo.product_category_name_translation;

SELECT TOP 5 * FROM dbo.orders;
SELECT TOP 5 * FROM dbo.customers;
SELECT TOP 5 * FROM dbo.order_reviews WHERE review_comment_message IS NOT NULL;

-- Are date columns populated or all NULL?
SELECT COUNT(*) AS total,
       COUNT(order_delivered_customer_date) AS delivered_dates
FROM dbo.orders;
USE Olist

SELECT TOP 5 * FROM dbo.orders;
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- orders
SELECT
  COUNT(*) AS total_orders,
  SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END)              AS null_approved,
  SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END)   AS null_carrier,
  SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END)  AS null_delivered,
  SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END)  AS null_estimated
FROM dbo.orders;

-- Are NULL delivery dates explained by status?
SELECT order_status, COUNT(*) AS n,
       SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivered
FROM dbo.orders
GROUP BY order_status
ORDER BY n DESC;

-- products
SELECT
  COUNT(*) AS total_products,
  SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_category,
  SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END)      AS null_weight
FROM dbo.products;

-- reviews
SELECT
  COUNT(*) AS total_reviews,
  SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END)   AS null_title,
  SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS null_message
FROM dbo.order_reviews;

SELECT COUNT(*) FROM dbo.order_reviews WHERE LTRIM(RTRIM(review_comment_message)) = '';
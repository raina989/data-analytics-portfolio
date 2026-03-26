-- =====================================================
-- E-COMMERCE ANALYTICS - SQL QUERIES
-- =====================================================

-- 1. OVERVIEW: Total sales, orders, customers, sellers
-- =====================================================
SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    COUNT(DISTINCT oi.seller_id) AS total_sellers,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_order_value,
    ROUND(AVG(oi.price * oi.product_count), 2) AS avg_items_per_order
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- =====================================================

-- 2. SALES TREND BY MONTH
-- =====================================================
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(AVG(oi.price), 2) AS avg_order_value
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY month;

-- =====================================================

-- 3. TOP 10 PRODUCT CATEGORIES BY SALES
-- =====================================================
SELECT 
    p.product_category_name_english AS category,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_price,
    COUNT(oi.product_id) AS units_sold
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
JOIN olist_orders_dataset o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;

-- =====================================================

-- 4. CUSTOMER SEGMENTATION (By Spending)
-- =====================================================
WITH customer_spending AS (
    SELECT 
        o.customer_id,
        ROUND(SUM(oi.price), 2) AS total_spent,
        COUNT(DISTINCT o.order_id) AS order_count,
        ROUND(AVG(oi.price), 2) AS avg_order_value
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.customer_id
)
SELECT 
    CASE 
        WHEN total_spent < 100 THEN 'Low Spender (< $100)'
        WHEN total_spent BETWEEN 100 AND 500 THEN 'Medium Spender ($100-$500)'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'High Spender ($500-$1000)'
        ELSE 'VIP Spender (> $1000)'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spent), 2) AS avg_spent,
    ROUND(AVG(order_count), 1) AS avg_orders
FROM customer_spending
GROUP BY customer_segment
ORDER BY avg_spent DESC;

-- =====================================================

-- 5. REVIEW SCORES BY CATEGORY
-- =====================================================
SELECT 
    p.product_category_name_english AS category,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(DISTINCT r.review_id) AS review_count,
    ROUND(SUM(oi.price), 2) AS category_revenue
FROM olist_order_reviews_dataset r
JOIN olist_orders_dataset o ON r.order_id = o.order_id
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
JOIN olist_products_dataset p ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name_english
HAVING COUNT(DISTINCT r.review_id) > 10
ORDER BY avg_review_score DESC;

-- =====================================================

-- 6. DELIVERY TIME ANALYSIS
-- =====================================================
SELECT 
    AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS avg_delivery_days,
    AVG(DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date)) AS avg_days_early_late,
    COUNT(CASE 
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 
    END) AS late_deliveries,
    COUNT(*) AS total_deliveries,
    ROUND(100.0 * COUNT(CASE 
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 
    END) / COUNT(*), 2) AS late_delivery_percentage
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- =====================================================

-- 7. SELLER PERFORMANCE RANKING
-- =====================================================
SELECT 
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS orders_fulfilled,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(r.review_score), 2) AS avg_seller_rating,
    RANK() OVER (ORDER BY SUM(oi.price) DESC) AS revenue_rank
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o ON oi.order_id = o.order_id
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id
ORDER BY total_revenue DESC
LIMIT 20;

-- =====================================================

-- 8. PAYMENT METHOD PREFERENCES
-- =====================================================
SELECT 
    payment_type,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS avg_payment_value,
    ROUND(100.0 * COUNT(DISTINCT order_id) / SUM(COUNT(DISTINCT order_id)) OVER(), 2) AS percentage_of_orders
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_payment_value DESC;
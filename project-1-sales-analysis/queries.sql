-- =====================================================
-- SUPERSTORE SALES ANALYSIS - SQL QUERIES
-- =====================================================

-- 1. OVERVIEW: Total sales, profit, and quantity sold
-- Shows overall business performance metrics
SELECT 
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    SUM(quantity) AS total_quantity_sold,
    ROUND(AVG(profit / NULLIF(sales, 0)) * 100, 2) AS avg_profit_margin_percentage
FROM superstore;

-- =====================================================

-- 2. SALES BY REGION
-- Identifies which regions perform best
SELECT 
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS number_of_orders,
    ROUND(AVG(profit / NULLIF(sales, 0)) * 100, 2) AS profit_margin_percentage
FROM superstore
GROUP BY region
ORDER BY total_sales DESC;

-- =====================================================

-- 3. TOP 10 PRODUCTS BY PROFIT
-- Shows the most profitable products
SELECT 
    product_name,
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM superstore
GROUP BY product_name, category, sub_category
ORDER BY total_profit DESC
LIMIT 10;

-- =====================================================

-- 4. BOTTOM 10 PRODUCTS BY PROFIT (LOSSES)
-- Identifies products that are losing money
SELECT 
    product_name,
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM superstore
GROUP BY product_name, category, sub_category
ORDER BY total_profit ASC
LIMIT 10;

-- =====================================================

-- 5. MONTHLY SALES TREND (2023-2024)
-- Shows seasonality and growth patterns
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    ROUND(SUM(sales), 2) AS monthly_sales,
    ROUND(SUM(profit), 2) AS monthly_profit,
    COUNT(DISTINCT order_id) AS order_count
FROM superstore
WHERE order_date >= '2023-01-01'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- =====================================================

-- 6. SALES BY CATEGORY AND SUB-CATEGORY
-- Drill-down analysis of product categories
SELECT 
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit / NULLIF(sales, 0)) * 100, 2) AS profit_margin
FROM superstore
GROUP BY category, sub_category
ORDER BY category, total_sales DESC;

-- =====================================================

-- 7. TOP 10 CUSTOMERS BY SPENDING
-- Identifies most valuable customers for loyalty programs
SELECT 
    customer_id,
    customer_name,
    ROUND(SUM(sales), 2) AS total_spent,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(AVG(sales), 2) AS avg_order_value
FROM superstore
GROUP BY customer_id, customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- =====================================================

-- 8. SALES BY SHIP MODE
-- Analyzes shipping preferences and profitability
SELECT 
    ship_mode,
    ROUND(SUM(sales), 2) AS total_sales,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(AVG(profit / NULLIF(sales, 0)) * 100, 2) AS avg_profit_margin
FROM superstore
GROUP BY ship_mode
ORDER BY total_sales DESC;

-- =====================================================

-- 9. DISCOUNT IMPACT ANALYSIS
-- Shows how discounts affect profitability
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount > 0 AND discount <= 0.2 THEN 'Low (1-20%)'
        WHEN discount > 0.2 AND discount <= 0.5 THEN 'Medium (21-50%)'
        ELSE 'High (50%+)'
    END AS discount_level,
    ROUND(AVG(sales), 2) AS avg_sales_per_order,
    ROUND(AVG(profit), 2) AS avg_profit_per_order,
    ROUND(AVG(profit / NULLIF(sales, 0)) * 100, 2) AS avg_profit_margin,
    COUNT(*) AS number_of_transactions
FROM superstore
GROUP BY discount_level
ORDER BY discount_level;

-- =====================================================

-- 10. STATE-LEVEL PERFORMANCE (TOP 10 STATES)
-- Geographic breakdown for regional strategy
SELECT 
    state,
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM superstore
GROUP BY state, region
ORDER BY total_sales DESC
LIMIT 10;

-- =====================================================

-- 11. YEAR-OVER-YEAR GROWTH
-- Calculates growth rate between years
WITH yearly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS year,
        ROUND(SUM(sales), 2) AS total_sales
    FROM superstore
    GROUP BY EXTRACT(YEAR FROM order_date)
)
SELECT 
    year,
    total_sales,
    LAG(total_sales) OVER (ORDER BY year) AS previous_year_sales,
    ROUND(((total_sales - LAG(total_sales) OVER (ORDER BY year)) / 
           LAG(total_sales) OVER (ORDER BY year)) * 100, 2) AS growth_percentage
FROM yearly_sales
ORDER BY year;

-- =====================================================

-- 12. RETURNING VS NEW CUSTOMERS (If you have order dates per customer)
-- Shows customer loyalty patterns
WITH customer_first_order AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date
    FROM superstore
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN o.order_date = c.first_order_date THEN 'New Customer'
        ELSE 'Returning Customer'
    END AS customer_type,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(o.sales), 2) AS total_sales,
    ROUND(AVG(o.profit / NULLIF(o.sales, 0)) * 100, 2) AS avg_profit_margin
FROM superstore o
JOIN customer_first_order c ON o.customer_id = c.customer_id
GROUP BY customer_type;
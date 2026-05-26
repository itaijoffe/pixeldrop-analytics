-- ============================================================
-- 08_business_questions.sql
-- PixelDrop | SQL Cleaning Project
-- Step 8: Answer Business Questions using Clean Views
--
-- PURPOSE: Using the clean views created in Script 07,
--          we answer real business questions across three
--          categories: Sales Performance, Customer Insights,
--          and Operations & Returns.
--
-- ALL QUERIES USE: vw_order_summary, vw_clean_orders,
--                 vw_clean_customers, products, returns
--
-- KEY FINDINGS SUMMARY:
--   - Total revenue: $6,006,804 across 2023-2024
--   - Best month: July 2023 ($288,285)
--   - Top category: Sneakers (36% of revenue)
--   - Top product by revenue: High Top Force ($1,036,384)
--   - Top product by units: Air Hoodie (4,888 units)
--   - AOV: $521 per order
--   - Repeat customer rate: 79.63%
--   - Return rate: 7.69% (below industry average)
--   - Loyal customers (both years): 1,935
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- SECTION 1: SALES PERFORMANCE
-- ════════════════════════════════════════════════════════════

-- ── Q1: Total Revenue 2023 vs 2024 ───────────────────────────
-- Business question: How did revenue compare year over year?
-- Finding: 2023 ($3,041,054) slightly outperformed 2024 ($2,965,749)
--          Revenue dropped ~2.5% — worth investigating root cause

SELECT
    YEAR(order_date) AS year,
    SUM(line_total) AS total_revenue
FROM vw_order_summary
GROUP BY YEAR(order_date)
ORDER BY year DESC;


-- ── Q2: Highest Revenue Month ────────────────────────────────
-- Business question: Which single month generated the most revenue?
-- Finding: July 2023 ($288,285) — possible summer drop/promotion spike

SELECT TOP 1
    YEAR(order_date)  AS year,
    MONTH(order_date) AS month,
    SUM(line_total) AS total_revenue
FROM vw_order_summary
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY total_revenue DESC;


-- ── Q3: Revenue by Category ───────────────────────────────────
-- Business question: Which product category drives the most revenue?
-- Finding: Sneakers dominate at $2.2M (36% of total revenue)
--          Accessories underperform at $212K — potential growth area

SELECT
    category,
    SUM(line_total) AS total_revenue
FROM vw_order_summary
GROUP BY category
ORDER BY total_revenue DESC;


-- ── Q4: Top 5 Products by Revenue ────────────────────────────
-- Business question: Which products generate the most revenue?
-- Finding: High Top Force leads at $1M+ — nearly double 4th place
--          3 of top 5 are premium items (sneakers + jacket)

SELECT TOP 5
    product_name,
    SUM(line_total) AS total_revenue
FROM vw_order_summary
GROUP BY product_name
ORDER BY total_revenue DESC;


-- ── Q5: Top 5 Products by Units Sold ─────────────────────────
-- Business question: Which products sell the most units?
-- Finding: COMPLETELY different list from Q4!
--          Cheap items (Canvas Tote, Slide Pro) lead in volume
--          Only Retro Runner Sneaker appears in BOTH lists
--          → Premium products: high revenue, low volume
--          → Budget products: high volume, low revenue

SELECT TOP 5
    product_name,
    SUM(quantity) AS units_sold
FROM vw_order_summary
GROUP BY product_name
ORDER BY units_sold DESC;


-- ── Q6: Average Order Value (AOV) ────────────────────────────
-- Business question: What is the average spend per order?
-- Finding: $521 AOV — high for retail, reflects premium product mix
--          Track this monthly — a drop signals customers buying cheaper items

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(line_total) AS total_revenue,
    ROUND(SUM(line_total) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM vw_order_summary;


-- ════════════════════════════════════════════════════════════
-- SECTION 2: CUSTOMER INSIGHTS
-- ════════════════════════════════════════════════════════════

-- ── Q7: Unique Customers Who Ordered ─────────────────────────
-- Business question: How many verified customers placed orders?
-- Finding: 2,125 unique customers ordered out of 3,618 verified
--          59% purchase rate — 41% signed up but never ordered
--          → Re-engagement opportunity for marketing team

SELECT
    COUNT(DISTINCT customer_name) AS total_customers
FROM vw_order_summary
WHERE customer_name IS NOT NULL;


-- ── Q8: Revenue by State (Top 10) ────────────────────────────
-- Business question: Which states generate the most revenue?
-- Finding: Georgia leads surprisingly ($381,852) — unusual for streetwear
--          NY and FL follow as expected
--          → Investigate what's driving GA performance

SELECT TOP 10
    state,
    SUM(line_total) AS total_revenue
FROM vw_order_summary
WHERE state IS NOT NULL
GROUP BY state
ORDER BY total_revenue DESC;


-- ── Q9: Average Order Value by State (Top 10) ────────────────
-- Business question: Where do customers spend the most per order?
-- Finding: GA leads AOV too ($527) — confirming GA customers are
--          high-value, not just high-volume
--          All states within $25 of each other — very consistent behaviour

SELECT TOP 10
    state,
    ROUND(SUM(line_total) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM vw_order_summary
WHERE state IS NOT NULL
GROUP BY state
ORDER BY avg_order_value DESC;


-- ── Q10: Repeat Customer Rate ─────────────────────────────────
-- Business question: What % of customers ordered more than once?
-- Finding: 79.63% repeat rate — 8 out of 10 customers came back!
--          Excellent loyalty for a streetwear brand
-- TECHNIQUE: CTE counts orders per customer, outer query calculates %

WITH order_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM vw_order_summary
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS repeat_rate_pct
FROM order_counts;


-- ── Q11: Most Popular Payment Method ─────────────────────────
-- Business question: Which payment methods do customers prefer?
-- Finding: All 5 methods within 150 orders of each other
--          → Very even distribution, PixelDrop's payment mix is optimal

-- Overall
SELECT
    payment_method,
    COUNT(DISTINCT order_id) AS order_count
FROM vw_order_summary
GROUP BY payment_method
ORDER BY order_count DESC;

-- Broken down by state
SELECT
    state,
    payment_method,
    COUNT(DISTINCT order_id) AS order_count
FROM vw_order_summary
WHERE state IS NOT NULL
GROUP BY state, payment_method
ORDER BY state, order_count DESC;


-- ════════════════════════════════════════════════════════════
-- SECTION 3: OPERATIONS & RETURNS
-- ════════════════════════════════════════════════════════════

-- ── Q12: Overall Return Rate ──────────────────────────────────
-- Business question: What % of orders were returned?
-- Finding: 7.69% return rate — well below fashion industry avg (20-30%)
--          886 returns out of 11,526 orders — healthy for the business
-- TECHNIQUE: LEFT JOIN returns to orders, COUNT DISTINCT on each side

SELECT
    COUNT(DISTINCT t1.order_id) AS total_orders,
    COUNT(DISTINCT t2.order_id) AS returned_orders,
    CAST(ROUND(100.0 * COUNT(DISTINCT t2.order_id)
         / COUNT(DISTINCT t1.order_id), 2) AS DECIMAL(10,2)) AS return_rate_pct
FROM vw_clean_orders AS t1
LEFT JOIN returns AS t2 
ON t1.order_id = t2.order_id;


-- ── Q13: Return Rate by Product ───────────────────────────────
-- Business question: Which product has the highest return rate?
-- Finding: Air Hoodie leads at 6.47% — likely sizing issues (common for hoodies)
--          Puffer Jacket lowest at 4.55% — customers satisfied with premium item
-- TECHNIQUE: Start from products table, LEFT JOIN both order_items and returns
--            separately to avoid row multiplication

SELECT
    t1.product_name,
    COUNT(DISTINCT t2.order_id) AS total_orders,
    COUNT(DISTINCT t3.return_id) AS total_returns,
    CAST(ROUND(100.0 * COUNT(DISTINCT t3.return_id)
         / COUNT(DISTINCT t2.order_id), 2) AS DECIMAL(10,2)) AS return_rate_pct
FROM products AS t1
LEFT JOIN order_items AS t2 
ON t1.product_id = t2.product_id
LEFT JOIN returns  AS t3 
ON t1.product_id = t3.product_id
GROUP BY t1.product_name
ORDER BY return_rate_pct DESC;


-- ── Q14: Average Shipping Days by Order Status ────────────────
-- Business question: Does shipping time vary by order status?
-- Finding: All statuses average 7 days — consistent shipping performance
--          In real data: refunded orders often have longer shipping times

SELECT
    order_status,
    AVG(shipping_days) AS avg_shipping_days
FROM vw_clean_orders
WHERE shipping_days IS NOT NULL
GROUP BY order_status;


-- ── Q15: Orders with Shipping Days > 10 by State ─────────────
-- Business question: Which states receive the most slow deliveries?
-- Finding: All states affected fairly evenly — no major geographic bias
--          GA and NJ lead — worth flagging to logistics team

SELECT
    shipping_state,
    COUNT(DISTINCT order_id) AS total_slow_orders
FROM vw_clean_orders
WHERE shipping_days > 10
GROUP BY shipping_state
ORDER BY total_slow_orders DESC;


-- ── Q16: Discount Usage Rate ──────────────────────────────────
-- Business question: What % of line items had a discount applied?
-- Finding: 54.51% of line items had discounts — more than half!
--          High discount rate may be eating into profit margins
--          → Business should review if all discounts are necessary
-- NOTE: Measured at line item level (not order level) because
--       discount is applied per product, not per order

SELECT
    COUNT(*) AS total_line_items,
    SUM(CASE WHEN discount > 0 THEN 1 ELSE 0 END) AS discounted_items,
    CAST(ROUND(100.0 * SUM(CASE WHEN discount > 0 THEN 1 ELSE 0 END)
         / COUNT(*), 2) AS DECIMAL(10,2)) AS discount_rate_pct
FROM vw_order_summary;


-- ════════════════════════════════════════════════════════════
-- SECTION 4: ADVANCED ANALYSIS
-- ════════════════════════════════════════════════════════════

-- ── Q17: Product Revenue Rank Within Category ─────────────────
-- Business question: Which product leads each category?
-- Finding: High Top Force dominates Sneakers ($1M+)
--          Puffer Jacket leads Hoodies despite being most expensive
--          Cargo Pants leads Bottoms — workwear trend in streetwear
-- TECHNIQUE: CTE calculates revenue, RANK() OVER PARTITION BY
--            resets ranking for each category

WITH product_revenue AS (
    SELECT
        category,
        product_name,
        SUM(line_total) AS revenue
    FROM vw_order_summary
    GROUP BY category, product_name
)
SELECT
    category,
    product_name,
    revenue,
    RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank_in_category
FROM product_revenue
ORDER BY category, rank_in_category;


-- ── Q18: Month-over-Month Revenue Growth ─────────────────────
-- Business question: How does revenue grow or shrink month to month?
-- Finding: July 2023 peak (+12%), August 2023 big drop (-16%)
--          February consistently weak (-12% in 2023)
--          Revenue fluctuates between -16% and +12% — normal retail seasonality
-- TECHNIQUE: CTE builds monthly totals, LAG() looks back one row
--            to get previous month revenue for comparison

WITH monthly_revenue AS (
    SELECT
        YEAR(order_date)  AS year,
        MONTH(order_date) AS month,
        SUM(line_total) AS total_revenue
    FROM vw_order_summary
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT
    year,
    month,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY year, month) AS prev_month_revenue,
    ROUND(100.0 * (total_revenue - LAG(total_revenue) OVER (ORDER BY year, month))
          / LAG(total_revenue) OVER (ORDER BY year, month), 2) AS growth_pct
FROM monthly_revenue
ORDER BY year, month;


-- ── Q19: Loyal Customers (Ordered in Both 2023 AND 2024) ──────
-- Business question: How many customers are truly loyal?
-- Finding: 1,935 out of 2,125 customers ordered in both years = 91%!
--          Exceptional retention rate for a streetwear brand
-- TECHNIQUE: Two IN subqueries — customer must appear in BOTH year filters

-- Count of loyal customers
SELECT COUNT(DISTINCT customer_id) AS loyal_customers
FROM vw_order_summary
WHERE customer_id IN (
    SELECT customer_id 
    FROM vw_order_summary 
    WHERE YEAR(order_date) = 2023
)
AND customer_id IN (
    SELECT customer_id 
    FROM vw_order_summary
    WHERE YEAR(order_date) = 2024
)
AND customer_id IS NOT NULL;

-- Full list with details
SELECT DISTINCT
    customer_id,
    customer_name,
    segment
FROM vw_order_summary
WHERE customer_id IN (
    SELECT customer_id 
    FROM vw_order_summary 
    WHERE YEAR(order_date) = 2023
)
AND customer_id IN (
    SELECT customer_id 
    FROM vw_order_summary 
    WHERE YEAR(order_date) = 2024
)
AND customer_id IS NOT NULL
ORDER BY customer_id;


-- ── Q20: Customers with Highest Return Rate ───────────────────
-- Business question: Which customers return the most? Is it product-related?
-- Finding: Harper T. and Lucas M. return 75% of their orders
--          Returns spread across different products — behavioural pattern
--          NOT a product quality issue — likely serial returners
--          → Customer service team should review these accounts
-- NOTE: HAVING >= 3 orders filters out single-order customers
--       whose 100% return rate isn't meaningful

-- Part 1: Top 10 customers by return rate (min 3 orders)
SELECT TOP 10
    customer_name,
    COUNT(DISTINCT t1.order_id)  AS total_orders,
    COUNT(DISTINCT t2.return_id) AS total_returns,
    CAST(ROUND(100.0 * COUNT(DISTINCT t2.return_id)
         / COUNT(DISTINCT t1.order_id), 2) AS DECIMAL(10,2)) AS return_rate_pct
FROM vw_order_summary AS t1
LEFT JOIN returns AS t2 
ON t1.order_id = t2.order_id
WHERE t1.customer_name IS NOT NULL
GROUP BY customer_name
HAVING COUNT(DISTINCT t1.order_id) >= 3
ORDER BY return_rate_pct DESC;

-- Part 2: Which products do high-return customers buy?
SELECT TOP 10
    t1.customer_name,
    t3.product_name,
    COUNT(DISTINCT t2.return_id) AS returns
FROM vw_order_summary AS t1
LEFT JOIN returns AS t2 
ON t1.order_id = t2.order_id
LEFT JOIN products AS t3 
ON t2.product_id = t3.product_id
WHERE t1.customer_name IN (
    'Harper T.', 'Lucas M.', 'Chloe P.',
    'Emma Johnson', 'Ethan Thompson'
)
GROUP BY t1.customer_name,t3.product_name
ORDER BY t1.customer_name,returns DESC;


-- ── Q21: CTE Chain — Revenue by Category and Month ───────────
-- Business question: How does each category perform month by month?
-- Finding: Reveals seasonal patterns per category
--          e.g. Hoodies peak in winter months, Sneakers consistent year-round
-- TECHNIQUE: Two-CTE chain
--   CTE 1 (order_details): Joins orders + items + products, calculates line_total
--   CTE 2 (category_monthly): Aggregates CTE 1 by category and month
--   This is a real-world pattern used in enterprise data pipelines

WITH order_details AS (
    -- CTE 1: Build flat order + product table
    SELECT
        t1.order_id,
        t1.order_date,
        t3.category,
        CAST(t2.quantity * t2.unit_price * (1 - t2.discount / 100)
             AS DECIMAL(10,2)) AS line_total
    FROM vw_clean_orders AS t1
    LEFT JOIN order_items AS t2 
    ON t1.order_id = t2.order_id
    LEFT JOIN products AS t3 
    ON t2.product_id = t3.product_id
),
category_monthly AS (
    -- CTE 2: Summarise by category and month
    SELECT
        YEAR(order_date) AS year,
        MONTH(order_date) AS month,
        category,
        SUM(line_total) AS revenue
    FROM order_details
    GROUP BY YEAR(order_date), MONTH(order_date), category
)
-- Final output: ordered chronologically, highest revenue category first per month
SELECT *
FROM category_monthly
ORDER BY year, month, revenue DESC;

-- ============================================================
-- SQL PROJECT COMPLETE!
-- Total queries: 21 business questions answered
-- 
-- Next steps:
--   → Project 2: Pandas analysis (deeper EDA + visualisations)
--   → Project 3: Power BI dashboard
--   → Capstone: Full pipeline SQL → Pandas → Power BI
-- ============================================================

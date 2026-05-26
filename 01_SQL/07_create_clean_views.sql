-- ============================================================
-- 07_create_clean_views.sql
-- PixelDrop | SQL Cleaning Project
-- Step 7: Create clean views for analysis
--
-- PURPOSE: Raw tables stay untouched. Views are saved SELECT
--          queries that look and behave like tables.
--          Analysts query the views — not the raw tables.
--          This separates raw data from clean analysis data.
--
-- VIEWS CREATED:
--   vw_clean_customers  → verified customers only
--   vw_clean_orders     → valid orders only  
--   vw_order_summary    → full joined analysis view
--
-- vw_order_summary joins all 5 tables and calculates
-- line_total per order item — this is the main view
-- used for all business questions, Power BI, and Pandas.
--
-- NOTE: Views are live — they always reflect the current
--       state of the underlying tables. No need to refresh.
--
-- RESULTS:
--   vw_clean_customers → 3,618 verified customers
--   vw_clean_orders    → 11,834 valid orders
--   vw_order_summary   → full analysis-ready dataset
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- VIEW 1: vw_clean_customers
-- Filters out:
--   - Invalid emails (is_valid_email = 0)
--   - Duplicate emails (is_duplicate_email = 1)
--   - Customers with no name
-- ════════════════════════════════════════════════════════════

CREATE VIEW vw_clean_customers AS
SELECT
    customer_id,
    customer_name,
    email,
    phone,
    state,
    signup_date,
    segment
FROM customers
WHERE is_valid_email     = 1    -- remove invalid emails
  AND is_duplicate_email = 0    -- remove duplicate accounts
  AND customer_name IS NOT NULL; -- remove nameless customers

-- Verify
SELECT COUNT(*) AS clean_customer_count FROM vw_clean_customers;
-- Expected: 3,618


-- ════════════════════════════════════════════════════════════
-- VIEW 2: vw_clean_orders
-- Filters out:
--   - Ghost orders with no line items (is_valid_order = 0)
--   - Orders with no order_id (safety check)
-- ════════════════════════════════════════════════════════════

CREATE VIEW vw_clean_orders AS
SELECT
    order_id,
    order_date,
    customer_id,
    shipping_state,
    payment_method,
    order_status,
    shipping_days
FROM orders
WHERE is_valid_order = 1        -- remove ghost orders
  AND order_id IS NOT NULL;     -- safety check

-- Verify
SELECT COUNT(*) AS clean_order_count FROM vw_clean_orders;
-- Expected: 11,834


-- ════════════════════════════════════════════════════════════
-- VIEW 3: vw_order_summary
-- The main analysis view — joins all tables together.
-- Includes a calculated line_total column per order item.
--
-- JOINS:
--   vw_clean_orders     → base (clean orders only)
--   order_items         → line items per order
--   products            → product details
--   vw_clean_customers  → customer details
--
-- WHY LEFT JOIN for customers?
--   Some orders belong to customers filtered out by
--   vw_clean_customers (invalid email etc.). LEFT JOIN
--   keeps all orders — customer columns show NULL for
--   unverified customers. This is honest — we have the
--   order but can't verify the customer.
--
-- line_total formula:
--   quantity × unit_price × (1 - discount/100)
--   Example: 2 × $89.99 × (1 - 10/100) = $161.98
-- ════════════════════════════════════════════════════════════

CREATE VIEW vw_order_summary AS
SELECT
    -- Order details
    t1.order_id,
    t1.order_date,
    t1.order_status,
    t1.payment_method,
    t1.shipping_days,
    t1.shipping_state,

    -- Line item details
    t2.quantity,
    t2.unit_price,
    t2.discount,

    -- Calculated revenue per line item
    CAST(t2.quantity * t2.unit_price * (1 - t2.discount / 100) AS DECIMAL(10,2)) AS line_total,

    -- Product details
    t3.product_name,
    t3.category,
    t3.cost_price,
    t3.retail_price,

    -- Customer details (NULL if customer was filtered out)
    t4.customer_id,
    t4.customer_name,
    t4.state         AS customer_state,
    t4.segment,
    t4.signup_date

FROM vw_clean_orders AS t1
LEFT JOIN order_items        AS t2 ON t1.order_id    = t2.order_id
LEFT JOIN products           AS t3 ON t2.product_id  = t3.product_id
LEFT JOIN vw_clean_customers AS t4 ON t1.customer_id = t4.customer_id;


-- ════════════════════════════════════════════════════════════
-- FINAL VERIFICATION
-- Quick sanity checks on the main analysis view
-- ════════════════════════════════════════════════════════════

-- Preview the view
SELECT TOP 20 * FROM vw_order_summary;

-- Row count
SELECT COUNT(*) AS total_rows FROM vw_order_summary;

-- Check for NULLs in key columns
SELECT
    SUM(CASE WHEN order_id      IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN product_name  IS NULL THEN 1 ELSE 0 END) AS null_product,
    SUM(CASE WHEN line_total    IS NULL THEN 1 ELSE 0 END) AS null_line_total,
    SUM(CASE WHEN unit_price    IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN quantity      IS NULL THEN 1 ELSE 0 END) AS null_quantity
FROM vw_order_summary;
-- Expected: 0 for all key columns

-- Revenue sanity check
SELECT
    SUM(line_total)  AS total_revenue,
    COUNT(*)         AS total_line_items,
    AVG(line_total)  AS avg_line_total,
    MIN(line_total)  AS min_line_total,
    MAX(line_total)  AS max_line_total
FROM vw_order_summary;

-- Revenue by category
SELECT
    category,
    SUM(line_total)     AS total_revenue,
    COUNT(*)            AS total_orders,
    AVG(line_total)     AS avg_order_value
FROM vw_order_summary
GROUP BY category
ORDER BY total_revenue DESC;

-- ============================================================
-- DATABASE IS CLEAN AND READY FOR ANALYSIS!
-- Next steps:
--   → SQL business questions (see business questions doc)
--   → Export vw_order_summary for Pandas analysis
--   → Connect Power BI to PixelDropDB
-- ============================================================

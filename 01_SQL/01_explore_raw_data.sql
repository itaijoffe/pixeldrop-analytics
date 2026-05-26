-- ============================================================
-- 01_explore_raw_data.sql
-- PixelDrop | SQL Cleaning Project
-- Step 1: Explore & understand the raw data before touching it
-- 
-- PURPOSE: This script is READ ONLY. Nothing is changed here.
--          We run this first to understand what we are dealing with
--          before writing any cleaning logic.
-- RESULT:  Identified duplicates, nulls, and inconsistent values
--          across all 5 tables.
-- ============================================================


-- ── ROW COUNTS ───────────────────────────────────────────────
-- How many rows in each table?
SELECT 'customers'  AS table_name, COUNT(*) AS row_count FROM customers  UNION ALL
SELECT 'products',                 COUNT(*)              FROM products    UNION ALL
SELECT 'orders',                   COUNT(*)              FROM orders      UNION ALL
SELECT 'order_items',              COUNT(*)              FROM order_items UNION ALL
SELECT 'returns',                  COUNT(*)              FROM returns;

-- Expected results:
-- customers   → 4,500
-- products    → 15
-- orders      → 12,000
-- order_items → 29,037
-- returns     → 1,500


-- ── CUSTOMERS: NULL CHECK ─────────────────────────────────────
-- Count missing values in each column
SELECT
    SUM(CASE WHEN customer_id   IS NULL OR customer_id   = '' THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN customer_name IS NULL OR customer_name = '' THEN 1 ELSE 0 END) AS null_name,
    SUM(CASE WHEN email         IS NULL OR email         = '' THEN 1 ELSE 0 END) AS null_email,
    SUM(CASE WHEN phone         IS NULL OR phone         = '' THEN 1 ELSE 0 END) AS null_phone,
    SUM(CASE WHEN state         IS NULL OR state         = '' THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN signup_date   IS NULL OR signup_date   = '' THEN 1 ELSE 0 END) AS null_signup_date,
    SUM(CASE WHEN segment       IS NULL OR segment       = '' THEN 1 ELSE 0 END) AS null_segment
FROM customers;

-- Result: 15 null names, 41 null phones


-- ── CUSTOMERS: SEGMENT VALUES ─────────────────────────────────
-- Spot inconsistent segment values (should be 4 clean values)
SELECT segment, COUNT(*) AS count
FROM customers
GROUP BY segment
ORDER BY count DESC;

-- Found: occasional, Occ, N, New, Loyal, Lyl, Vip, V.I.P
-- Expected clean values: New, Occasional, Loyal, VIP


-- ── CUSTOMERS: STATE VALUES ───────────────────────────────────
-- Spot inconsistent state values (should be 2-letter codes)
SELECT state, COUNT(*) AS count
FROM customers
GROUP BY state
ORDER BY count DESC;

-- Found: california, Calif., ca, CA all meaning the same state


-- ── ORDERS: DUPLICATE CHECK ───────────────────────────────────
-- Find order_ids that appear more than once
SELECT order_id, COUNT(*) AS occurrences
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- Result: 307 duplicate order_ids found (315 rows to delete)


-- ── ORDERS: STATUS VALUES ─────────────────────────────────────
-- Spot inconsistent order status values
SELECT order_status, COUNT(*) AS count
FROM orders
GROUP BY order_status
ORDER BY count DESC;

-- Found: Done, Complete, COMPLETED, pending, In Progress, 
--        Cancelled, Canceled, REFUNDED, Refund


-- ── ORDERS: PAYMENT METHOD VALUES ────────────────────────────
-- Spot inconsistent payment method values
SELECT payment_method, COUNT(*) AS count
FROM orders
GROUP BY payment_method
ORDER BY count DESC;

-- Found: PAYPAL, pp, Pay Pal, CC, credit card, CREDIT,
--        ApplePay, ShopPay, Debit, debit card


-- ── ORDER_ITEMS: BAD VALUES CHECK ────────────────────────────
-- Count bad quantities, impossible discounts, and null prices
SELECT
    SUM(CASE WHEN TRY_CAST(quantity    AS INT)   <= 0  THEN 1 ELSE 0 END) AS bad_quantity,
    SUM(CASE WHEN TRY_CAST(discount    AS FLOAT) > 100 THEN 1 ELSE 0 END) AS bad_discount,
    SUM(CASE WHEN unit_price IS NULL OR unit_price = '' THEN 1 ELSE 0 END) AS null_price
FROM order_items;

-- Result: 562 bad quantities, 566 impossible discounts, 540 null prices


-- ── PRODUCTS: NAME CHECK ──────────────────────────────────────
-- Spot typos and inconsistent product names
SELECT product_name, COUNT(*) AS count
FROM products
GROUP BY product_name
ORDER BY count DESC;

-- Found: AIR HOODIE, Drrop Tee (typo), Chain Neklace (typo),
--        zip hoodie, CARGO PANTS — all need standardising

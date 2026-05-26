-- ============================================================
-- 05_clean_numbers.sql
-- PixelDrop | SQL Cleaning Project
-- Step 5: Clean all numeric columns across all tables
--
-- PURPOSE: Numeric columns have mixed formats, impossible values,
--          and missing data that will break any calculations.
--          We strip symbols, fix formats, remove bad rows,
--          and fill in missing values where possible.
--
-- TECHNIQUE:
--   REPLACE()     → strip $ signs, swap commas for dots
--   TRY_CAST()    → safely convert strings to numbers
--   COALESCE()    → replace NULLs with a default value
--   DELETE        → remove rows with no business value
--   ALTER COLUMN  → change column type after data is clean
--
-- COLUMNS CLEANED:
--   order_items → unit_price, quantity, discount
--   returns     → refund_amount
--   orders      → shipping_days
--
-- RESULT:
--   824 bad quantity rows deleted
--   560 impossible discount rows deleted
--   All prices converted to DECIMAL(10,2)
--   NULL discounts filled with 0
--   NULL/overpaid refunds corrected from products table
--   999 shipping day outliers set to NULL
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- ORDER_ITEMS — unit_price
-- Dirty:  $89.99 | 89,99 | $90 | 89.99 | (blank)
-- Clean:  89.99 as DECIMAL(10,2)
-- TECHNIQUE: Chain two REPLACE() calls to strip $ and swap ,
--            Then TRY_CAST to convert to decimal
-- ════════════════════════════════════════════════════════════

-- Preview — check conversion looks correct
SELECT
    unit_price AS original_price,
    TRY_CAST(REPLACE(REPLACE(unit_price, '$', ''), ',', '.') AS DECIMAL(10,2)) AS clean_price
FROM order_items;

-- Update — convert all prices to clean decimal
UPDATE order_items
SET unit_price = TRY_CAST(REPLACE(REPLACE(unit_price, '$', ''), ',', '.') AS DECIMAL(10,2));

-- Fix NULLs — fill missing prices from the products table
-- If we know which product it is, we know the retail price
UPDATE oi
SET oi.unit_price = p.retail_price
FROM order_items AS oi
JOIN products AS p ON oi.product_id = p.product_id
WHERE oi.unit_price IS NULL;

-- Change column type now that data is clean
ALTER TABLE order_items
ALTER COLUMN unit_price DECIMAL(10,2);

-- Verify
SELECT COUNT(*) AS null_prices FROM order_items WHERE unit_price IS NULL;
-- Expected: 0


-- ════════════════════════════════════════════════════════════
-- ORDER_ITEMS — quantity
-- Problem: 562 bad rows (negatives, zeros, NULLs)
-- Fix:     DELETE these rows — a line item with no valid
--          quantity has zero business value and would make
--          revenue calculations incorrect.
-- NOTE:    We chose DELETE over COALESCE(qty, 0) because
--          0 quantity means "we know it's zero" which is
--          misleading. NULL means "we don't know" which is honest.
--          Deleting is cleaner for analysis.
-- ════════════════════════════════════════════════════════════

-- Preview — how many rows will be deleted?
SELECT COUNT(*) AS rows_to_delete
FROM order_items
WHERE quantity IS NULL
   OR TRY_CAST(quantity AS INT) <= 0;
-- Result: 824 rows

-- Delete bad rows
DELETE FROM order_items
WHERE quantity IS NULL
   OR TRY_CAST(quantity AS INT) <= 0;

-- Verify
SELECT COUNT(*) AS remaining_bad
FROM order_items
WHERE quantity IS NULL OR TRY_CAST(quantity AS INT) <= 0;
-- Expected: 0

-- Check remaining row count
SELECT COUNT(*) AS total_rows FROM order_items;
-- Expected: ~27,651 rows


-- ════════════════════════════════════════════════════════════
-- ORDER_ITEMS — discount
-- Problem 1: 566 rows with discount > 100% (impossible)
-- Problem 2: NULL discounts (customer got no discount)
-- Fix 1:    DELETE rows with impossible discounts
-- Fix 2:    COALESCE NULLs to 0
-- NOTE:     NULL discount = no discount applied = 0
--           This is a valid use of COALESCE because 0 is
--           the correct business meaning here.
-- ════════════════════════════════════════════════════════════

-- Preview — how many impossible discounts?
SELECT COUNT(*) AS rows_to_delete
FROM order_items
WHERE TRY_CAST(discount AS DECIMAL) > 100;
-- Result: 560 rows

-- Delete impossible discounts
DELETE FROM order_items
WHERE TRY_CAST(discount AS DECIMAL) > 100;

-- Fix NULLs — replace with 0 (no discount)
UPDATE order_items
SET discount = COALESCE(discount, 0)
WHERE discount IS NULL;

-- Verify
SELECT COUNT(*) AS bad_discounts
FROM order_items
WHERE TRY_CAST(discount AS DECIMAL) > 100
   OR discount IS NULL;
-- Expected: 0


-- ════════════════════════════════════════════════════════════
-- RETURNS — refund_amount
-- Problem 1: 76 NULL refund amounts
-- Problem 2: 31 overpaid refunds (refund > retail price)
-- Fix 1:    Fill NULLs with retail_price (assume full refund)
-- Fix 2:    Cap overpaid refunds at retail_price
-- ════════════════════════════════════════════════════════════

-- Check nulls
SELECT COUNT(*) AS null_refunds
FROM returns
WHERE refund_amount IS NULL OR refund_amount = '';
-- Result: 76 rows

-- Check overpaid refunds
SELECT COUNT(*) AS overpaid
FROM returns AS r
JOIN products AS p ON r.product_id = p.product_id
WHERE TRY_CAST(r.refund_amount AS DECIMAL(10,2)) > TRY_CAST(p.retail_price AS DECIMAL(10,2));
-- Result: 31 rows

-- Fix NULLs — fill from products retail price
UPDATE r
SET r.refund_amount = p.retail_price
FROM returns AS r
JOIN products AS p ON r.product_id = p.product_id
WHERE r.refund_amount IS NULL OR r.refund_amount = '';

-- Fix overpaid — cap at retail price
UPDATE r
SET r.refund_amount = p.retail_price
FROM returns AS r
JOIN products AS p ON r.product_id = p.product_id
WHERE TRY_CAST(r.refund_amount AS DECIMAL(10,2)) > TRY_CAST(p.retail_price AS DECIMAL(10,2));

-- Change column type
ALTER TABLE returns
ALTER COLUMN refund_amount DECIMAL(10,2);

-- Verify
SELECT COUNT(*) AS remaining_issues
FROM returns
WHERE refund_amount IS NULL;
-- Expected: 0


-- ════════════════════════════════════════════════════════════
-- ORDERS — shipping_days
-- Problem 1: Negative shipping days (impossible)
-- Problem 2: 999 = placeholder for unknown (outlier)
-- Fix:       Set both to NULL — genuinely unknown values
-- NOTE:      We use NULL not 0 because 0 would mean
--            "delivered same day" which isn't what we know.
-- ════════════════════════════════════════════════════════════

-- Check issues
SELECT
    SUM(CASE WHEN TRY_CAST(shipping_days AS INT) < 0   THEN 1 ELSE 0 END) AS negative,
    SUM(CASE WHEN shipping_days IS NULL                  THEN 1 ELSE 0 END) AS nulls,
    SUM(CASE WHEN TRY_CAST(shipping_days AS INT) = 999  THEN 1 ELSE 0 END) AS outliers
FROM orders;

-- Fix 999 outliers
UPDATE orders
SET shipping_days = NULL
WHERE TRY_CAST(shipping_days AS INT) = 999;

-- Fix negative shipping days
UPDATE orders
SET shipping_days = NULL
WHERE TRY_CAST(shipping_days AS INT) < 0;

-- Verify
SELECT COUNT(*) AS remaining_issues
FROM orders
WHERE TRY_CAST(shipping_days AS INT) = 999
   OR TRY_CAST(shipping_days AS INT) < 0;
-- Expected: 0

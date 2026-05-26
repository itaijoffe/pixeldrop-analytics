-- ============================================================
-- 06_flag_invalid.sql
-- PixelDrop | SQL Cleaning Project
-- Step 6: Flag suspicious and invalid data with new columns
--
-- PURPOSE: Instead of deleting suspicious data, we ADD flag
--          columns that mark it. This is how real companies
--          handle it — analysts can then choose to include
--          or exclude flagged rows in their analysis.
--
--          This approach is more professional than deleting
--          because it preserves the original data and gives
--          analysts full control.
--
-- FLAGS ADDED:
--   customers.is_valid_email      → 1 = valid, 0 = invalid
--   customers.is_duplicate_email  → 1 = duplicate, 0 = unique
--   orders.is_valid_order         → 1 = has items, 0 = ghost order
--
-- TECHNIQUE:
--   LIKE '%@%.%'    → basic email format validation
--   GROUP BY/HAVING → find duplicate emails
--   NOT IN subquery → find orders with no line items
--   ROW_NUMBER()    → standardise order_id format
--
-- RESULT:
--   151 invalid emails flagged
--   Duplicate emails flagged
--   166 ghost orders flagged (orders with no items)
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- STEP 1: ADD FLAG COLUMNS
-- We add the columns first, then populate them with UPDATEs
-- ════════════════════════════════════════════════════════════

ALTER TABLE customers ADD is_valid_email     INT;
ALTER TABLE customers ADD is_duplicate_email INT;
ALTER TABLE orders    ADD is_valid_order     INT;


-- ════════════════════════════════════════════════════════════
-- CUSTOMERS — is_valid_email
-- Rule: A valid email must contain @ followed by a . 
-- Pattern: LIKE '%@%.%'
--   %   = anything
--   @   = must have @
--   %   = anything
--   .   = must have a dot after @
--   %   = anything after the dot
-- ════════════════════════════════════════════════════════════

-- Preview — count valid vs invalid
SELECT
    CASE WHEN email LIKE '%@%.%' THEN 1 ELSE 0 END AS is_valid_email,
    COUNT(*) AS count
FROM customers
GROUP BY CASE WHEN email LIKE '%@%.%' THEN 1 ELSE 0 END;
-- Result: 151 invalid, 4349 valid

-- Update flag
UPDATE customers
SET is_valid_email =
    CASE
        WHEN email LIKE '%@%.%' THEN 1
        ELSE 0
    END;

-- Verify
SELECT is_valid_email, COUNT(*) AS count
FROM customers
GROUP BY is_valid_email;


-- ════════════════════════════════════════════════════════════
-- CUSTOMERS — is_duplicate_email
-- Rule: If the same email appears more than once across
--       different customer_ids, it's a duplicate.
-- TECHNIQUE: Subquery finds emails with count > 1,
--            outer CASE flags any customer whose email
--            appears in that list.
-- ════════════════════════════════════════════════════════════

-- Preview — which emails are duplicated?
SELECT email, COUNT(*) AS count
FROM customers
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Update flag
UPDATE customers
SET is_duplicate_email =
    CASE
        WHEN email IN (
            SELECT email
            FROM customers
            GROUP BY email
            HAVING COUNT(*) > 1
        ) THEN 1
        ELSE 0
    END;

-- Verify
SELECT is_duplicate_email, COUNT(*) AS count
FROM customers
GROUP BY is_duplicate_email;


-- ════════════════════════════════════════════════════════════
-- FIX: Standardise order_id format before flagging orders
-- Problem: order_ids have 3 mixed formats:
--   ORD-10001 | 10001 | ord10001
-- We need them all as ORD-XXXXX for JOINs to work correctly
-- between orders and order_items tables.
-- ════════════════════════════════════════════════════════════

-- Fix orders table
UPDATE orders
SET order_id =
    CASE
        WHEN order_id LIKE 'ORD-%' THEN order_id                                    -- already correct
        WHEN order_id LIKE 'ord%'  THEN 'ORD-' + SUBSTRING(order_id, 4, LEN(order_id)) -- remove 'ord', add 'ORD-'
        ELSE 'ORD-' + order_id                                                      -- just a number, add prefix
    END;

-- Fix order_items table (same logic)
UPDATE order_items
SET order_id =
    CASE
        WHEN order_id LIKE 'ORD-%' THEN order_id
        WHEN order_id LIKE 'ord%'  THEN 'ORD-' + SUBSTRING(order_id, 4, LEN(order_id))
        ELSE 'ORD-' + order_id
    END;

-- Verify both tables — should show only 'ORD' prefix
SELECT DISTINCT LEFT(order_id, 3) AS prefix, COUNT(*) AS count
FROM orders
GROUP BY LEFT(order_id, 3);

SELECT DISTINCT LEFT(order_id, 3) AS prefix, COUNT(*) AS count
FROM order_items
GROUP BY LEFT(order_id, 3);


-- ════════════════════════════════════════════════════════════
-- ORDERS — is_valid_order
-- Rule: A valid order must have at least one matching row
--       in the order_items table.
-- Orders with no items are "ghost orders" — failed checkouts
-- or system errors. They exist in orders but have no products.
-- ════════════════════════════════════════════════════════════

-- Preview — how many ghost orders?
SELECT COUNT(*) AS ghost_orders
FROM orders
WHERE order_id NOT IN (
    SELECT DISTINCT order_id
    FROM order_items
);
-- Result: 166 ghost orders

-- Update flag
UPDATE orders
SET is_valid_order =
    CASE
        WHEN order_id IN (
            SELECT DISTINCT order_id
            FROM order_items
        ) THEN 1
        ELSE 0
    END;

-- Verify
SELECT is_valid_order, COUNT(*) AS count
FROM orders
GROUP BY is_valid_order;
-- Expected: 166 invalid (0), 11834 valid (1)

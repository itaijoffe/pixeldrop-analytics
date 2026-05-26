-- ============================================================
-- 02_remove_duplicates.sql
-- PixelDrop | SQL Cleaning Project
-- Step 2: Remove duplicate order IDs from the orders table
--
-- PURPOSE: The orders table contains duplicate order_ids caused
--          by data entry errors and system glitches.
--          We keep the FIRST occurrence of each order (ordered
--          by date) and delete all subsequent duplicates.
--
-- TECHNIQUE: ROW_NUMBER() window function inside a CTE.
--            ROW_NUMBER() assigns 1 to the first row per group,
--            2 to the second, etc. We delete anything > 1.
--
-- RESULT:   315 duplicate rows removed.
--           Orders table reduced from 12,000 → 11,685 rows.
-- ============================================================


-- ── STEP 1: PREVIEW (always check before deleting!) ──────────
-- See exactly how many rows will be deleted
WITH duplicates AS (
    SELECT 
        order_id,
        ROW_NUMBER() OVER (
            PARTITION BY order_id   -- group by order_id
            ORDER BY order_date     -- keep the earliest order
        ) AS row_num
    FROM orders
)
SELECT COUNT(*) AS rows_to_delete
FROM duplicates
WHERE row_num > 1;

-- Result: 315 rows


-- ── STEP 2: DELETE DUPLICATES ─────────────────────────────────
-- Same CTE logic — swap SELECT for DELETE
WITH duplicates AS (
    SELECT 
        order_id,
        ROW_NUMBER() OVER (
            PARTITION BY order_id 
            ORDER BY order_date
        ) AS row_num
    FROM orders
)
DELETE FROM duplicates
WHERE row_num > 1;

-- Result: (315 rows affected)


-- ── STEP 3: VERIFY ───────────────────────────────────────────
-- Confirm zero duplicates remain
SELECT 
    order_id,
    COUNT(*) AS occurrences
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Expected: 0 rows returned = success!

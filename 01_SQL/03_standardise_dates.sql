-- ============================================================
-- 03_standardise_dates.sql
-- PixelDrop | SQL Cleaning Project
-- Step 3: Standardise all date columns to YYYY-MM-DD format
--
-- PURPOSE: Date columns contain 5 different formats mixed together:
--          2023-01-05 | 01/05/2023 | 05-01-2023 | Jan 05 2023 | 2023/01/05
--          SQL cannot sort, filter, or calculate with mixed formats.
--          We standardise everything to YYYY-MM-DD (ISO standard).
--
-- TECHNIQUE: TRY_CONVERT(DATE, column, format_code)
--            Tries each format code — returns NULL if it fails.
--            CASE tries them in order and uses the first that works.
--
-- FORMAT CODES:
--          101 = mm/dd/yyyy
--          105 = dd-mm-yyyy  
--          111 = yyyy/mm/dd
--          120 = yyyy-mm-dd
--
-- TABLES:  customers (signup_date)
--          orders    (order_date)
--          returns   (return_date)
--
-- RESULT:  All date columns standardised to YYYY-MM-DD.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- CUSTOMERS — signup_date
-- ════════════════════════════════════════════════════════════

-- STEP 1: Preview clean dates before updating
SELECT 
    customer_id,
    customer_name,
    signup_date AS original_date,
    CASE
        WHEN TRY_CONVERT(DATE, signup_date, 101) IS NOT NULL THEN TRY_CONVERT(DATE, signup_date, 101)
        WHEN TRY_CONVERT(DATE, signup_date, 120) IS NOT NULL THEN TRY_CONVERT(DATE, signup_date, 120)
        WHEN TRY_CONVERT(DATE, signup_date, 105) IS NOT NULL THEN TRY_CONVERT(DATE, signup_date, 105)
        WHEN TRY_CONVERT(DATE, signup_date, 111) IS NOT NULL THEN TRY_CONVERT(DATE, signup_date, 111)
        ELSE NULL
    END AS clean_signup_date
FROM customers;

-- STEP 2: Update signup_date
UPDATE customers
SET signup_date =
    CASE
        WHEN TRY_CONVERT(DATE, signup_date, 101) IS NOT NULL THEN TRY_CONVERT(DATE, signup_date, 101)
        WHEN TRY_CONVERT(DATE, signup_date, 120) IS NOT NULL THEN TRY_CONVERT(DATE, signup_date, 120)
        WHEN TRY_CONVERT(DATE, signup_date, 105) IS NOT NULL THEN TRY_CONVERT(DATE, signup_date, 105)
        WHEN TRY_CONVERT(DATE, signup_date, 111) IS NOT NULL THEN TRY_CONVERT(DATE, signup_date, 111)
        ELSE NULL
    END;

-- STEP 3: Verify
SELECT TOP 10 customer_id, signup_date FROM customers;
-- All dates should now show as YYYY-MM-DD


-- ════════════════════════════════════════════════════════════
-- ORDERS — order_date
-- ════════════════════════════════════════════════════════════

-- STEP 1: Preview
SELECT 
    order_id,
    order_date AS original_date,
    CASE
        WHEN TRY_CONVERT(DATE, order_date, 101) IS NOT NULL THEN TRY_CONVERT(DATE, order_date, 101)
        WHEN TRY_CONVERT(DATE, order_date, 120) IS NOT NULL THEN TRY_CONVERT(DATE, order_date, 120)
        WHEN TRY_CONVERT(DATE, order_date, 105) IS NOT NULL THEN TRY_CONVERT(DATE, order_date, 105)
        WHEN TRY_CONVERT(DATE, order_date, 111) IS NOT NULL THEN TRY_CONVERT(DATE, order_date, 111)
        ELSE NULL
    END AS clean_order_date
FROM orders;

-- STEP 2: Update order_date
UPDATE orders
SET order_date =
    CASE
        WHEN TRY_CONVERT(DATE, order_date, 101) IS NOT NULL THEN TRY_CONVERT(DATE, order_date, 101)
        WHEN TRY_CONVERT(DATE, order_date, 120) IS NOT NULL THEN TRY_CONVERT(DATE, order_date, 120)
        WHEN TRY_CONVERT(DATE, order_date, 105) IS NOT NULL THEN TRY_CONVERT(DATE, order_date, 105)
        WHEN TRY_CONVERT(DATE, order_date, 111) IS NOT NULL THEN TRY_CONVERT(DATE, order_date, 111)
        ELSE NULL
    END;

-- STEP 3: Verify
SELECT TOP 10 order_id, order_date FROM orders;


-- ════════════════════════════════════════════════════════════
-- RETURNS — return_date
-- ════════════════════════════════════════════════════════════

-- STEP 1: Preview
SELECT 
    return_id,
    return_date AS original_date,
    CASE
        WHEN TRY_CONVERT(DATE, return_date, 101) IS NOT NULL THEN TRY_CONVERT(DATE, return_date, 101)
        WHEN TRY_CONVERT(DATE, return_date, 120) IS NOT NULL THEN TRY_CONVERT(DATE, return_date, 120)
        WHEN TRY_CONVERT(DATE, return_date, 105) IS NOT NULL THEN TRY_CONVERT(DATE, return_date, 105)
        WHEN TRY_CONVERT(DATE, return_date, 111) IS NOT NULL THEN TRY_CONVERT(DATE, return_date, 111)
        ELSE NULL
    END AS clean_return_date
FROM returns;

-- STEP 2: Update return_date
UPDATE returns
SET return_date =
    CASE
        WHEN TRY_CONVERT(DATE, return_date, 101) IS NOT NULL THEN TRY_CONVERT(DATE, return_date, 101)
        WHEN TRY_CONVERT(DATE, return_date, 120) IS NOT NULL THEN TRY_CONVERT(DATE, return_date, 120)
        WHEN TRY_CONVERT(DATE, return_date, 105) IS NOT NULL THEN TRY_CONVERT(DATE, return_date, 105)
        WHEN TRY_CONVERT(DATE, return_date, 111) IS NOT NULL THEN TRY_CONVERT(DATE, return_date, 111)
        ELSE NULL
    END;

-- STEP 3: Verify
SELECT TOP 10 return_id, return_date FROM returns;

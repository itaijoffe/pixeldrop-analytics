-- ============================================================
-- 04_standardise_text.sql
-- PixelDrop | SQL Cleaning Project
-- Step 4: Standardise all text columns across all tables
--
-- PURPOSE: Text columns contain mixed casing, abbreviations,
--          typos, and inconsistent values that all mean the
--          same thing. We map every dirty value to one 
--          canonical clean value.
--
-- TECHNIQUE: UPPER(TRIM(column)) IN ('VALUE1','VALUE2') THEN 'Clean'
--            UPPER() normalises casing before matching.
--            TRIM() removes leading/trailing spaces.
--            This way we catch all variants regardless of case.
--
-- TABLES & COLUMNS CLEANED:
--          customers  → segment, state, customer_name
--          orders     → order_status, payment_method, shipping_state
--          returns    → return_status, reason
--          products   → product_name, category
--
-- RULE: Always run SELECT preview first, check for NULLs,
--       then run UPDATE, then verify.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- CUSTOMERS — segment
-- Dirty:  occasional, Occ, N, New, Loyal, Lyl, Vip, V.I.P
-- Clean:  New | Occasional | Loyal | VIP
-- ════════════════════════════════════════════════════════════

-- Preview
SELECT 
    customer_id,
    segment AS original_segment,
    CASE
        WHEN UPPER(TRIM(segment)) IN ('OCC', 'OCCASIONAL') THEN 'Occasional'
        WHEN UPPER(TRIM(segment)) IN ('NEW', 'N')          THEN 'New'
        WHEN UPPER(TRIM(segment)) IN ('V.I.P', 'VIP')      THEN 'VIP'
        WHEN UPPER(TRIM(segment)) IN ('LOYAL', 'LYL')      THEN 'Loyal'
        ELSE NULL
    END AS clean_segment
FROM customers;

-- Update
UPDATE customers
SET segment =
    CASE
        WHEN UPPER(TRIM(segment)) IN ('OCC', 'OCCASIONAL') THEN 'Occasional'
        WHEN UPPER(TRIM(segment)) IN ('NEW', 'N')          THEN 'New'
        WHEN UPPER(TRIM(segment)) IN ('V.I.P', 'VIP')      THEN 'VIP'
        WHEN UPPER(TRIM(segment)) IN ('LOYAL', 'LYL')      THEN 'Loyal'
        ELSE NULL
    END;

-- Verify — should return exactly 4 values
SELECT DISTINCT segment FROM customers ORDER BY segment;


-- ════════════════════════════════════════════════════════════
-- CUSTOMERS — state
-- Dirty:  california, Calif., ca, CA, ohio, oh, OH, etc.
-- Clean:  2-letter state codes (CA, NY, TX, FL, etc.)
-- NOTE:   Using LOWER(TRIM()) here — all IN values are lowercase
-- ════════════════════════════════════════════════════════════

-- Preview
SELECT 
    customer_id,
    state AS original_state,
    CASE
        WHEN LOWER(TRIM(state)) IN ('florida','fla.','fl')           THEN 'FL'
        WHEN LOWER(TRIM(state)) IN ('new york','n.y','ny')           THEN 'NY'
        WHEN LOWER(TRIM(state)) IN ('texas','tx','tex.')             THEN 'TX'
        WHEN LOWER(TRIM(state)) IN ('california','calif.','ca')      THEN 'CA'
        WHEN LOWER(TRIM(state)) IN ('illinois','ill.','il')          THEN 'IL'
        WHEN LOWER(TRIM(state)) IN ('washington','wash.','wa')       THEN 'WA'
        WHEN LOWER(TRIM(state)) IN ('colorado','colo.','co')         THEN 'CO'
        WHEN LOWER(TRIM(state)) IN ('georgia','ga','ga.')            THEN 'GA'
        WHEN LOWER(TRIM(state)) IN ('arizona','ariz.','az')          THEN 'AZ'
        WHEN LOWER(TRIM(state)) IN ('north carolina','n.c','nc')     THEN 'NC'
        WHEN LOWER(TRIM(state)) IN ('ohio','oh')                     THEN 'OH'
        WHEN LOWER(TRIM(state)) IN ('michigan','mich.','mi')         THEN 'MI'
        WHEN LOWER(TRIM(state)) IN ('new jersey','n.j','nj')         THEN 'NJ'
        WHEN LOWER(TRIM(state)) IN ('virginia','va.','va')           THEN 'VA'
        WHEN LOWER(TRIM(state)) IN ('massachusetts','mass.','ma')    THEN 'MA'
        ELSE NULL
    END AS clean_state
FROM customers;

-- Update
UPDATE customers
SET state =
    CASE
        WHEN LOWER(TRIM(state)) IN ('florida','fla.','fl')           THEN 'FL'
        WHEN LOWER(TRIM(state)) IN ('new york','n.y','ny')           THEN 'NY'
        WHEN LOWER(TRIM(state)) IN ('texas','tx','tex.')             THEN 'TX'
        WHEN LOWER(TRIM(state)) IN ('california','calif.','ca')      THEN 'CA'
        WHEN LOWER(TRIM(state)) IN ('illinois','ill.','il')          THEN 'IL'
        WHEN LOWER(TRIM(state)) IN ('washington','wash.','wa')       THEN 'WA'
        WHEN LOWER(TRIM(state)) IN ('colorado','colo.','co')         THEN 'CO'
        WHEN LOWER(TRIM(state)) IN ('georgia','ga','ga.')            THEN 'GA'
        WHEN LOWER(TRIM(state)) IN ('arizona','ariz.','az')          THEN 'AZ'
        WHEN LOWER(TRIM(state)) IN ('north carolina','n.c','nc')     THEN 'NC'
        WHEN LOWER(TRIM(state)) IN ('ohio','oh')                     THEN 'OH'
        WHEN LOWER(TRIM(state)) IN ('michigan','mich.','mi')         THEN 'MI'
        WHEN LOWER(TRIM(state)) IN ('new jersey','n.j','nj')         THEN 'NJ'
        WHEN LOWER(TRIM(state)) IN ('virginia','va.','va')           THEN 'VA'
        WHEN LOWER(TRIM(state)) IN ('massachusetts','mass.','ma')    THEN 'MA'
        ELSE NULL
    END;

-- Verify — should return exactly 15 state codes
SELECT DISTINCT state FROM customers ORDER BY state;


-- ════════════════════════════════════════════════════════════
-- CUSTOMERS — customer_name
-- Dirty:  grace young | DYLAN WILSON | LUKE EDWARDS
-- Clean:  Grace Young | Dylan Wilson | Luke Edwards
-- TECHNIQUE: CHARINDEX finds the space, SUBSTRING cuts
--            first and last name separately, UPPER/LOWER
--            applies proper casing to each part.
-- ════════════════════════════════════════════════════════════

-- Preview
SELECT
    customer_name AS original_name,
    UPPER(LEFT(TRIM(customer_name), 1))
    + LOWER(SUBSTRING(TRIM(customer_name), 2, CHARINDEX(' ', TRIM(customer_name)) - 2))
    + ' '
    + UPPER(SUBSTRING(TRIM(customer_name), CHARINDEX(' ', TRIM(customer_name)) + 1, 1))
    + LOWER(SUBSTRING(TRIM(customer_name), CHARINDEX(' ', TRIM(customer_name)) + 2, LEN(customer_name)))
    AS clean_name
FROM customers;

-- Update
UPDATE customers
SET customer_name =
    UPPER(LEFT(TRIM(customer_name), 1))
    + LOWER(SUBSTRING(TRIM(customer_name), 2, CHARINDEX(' ', TRIM(customer_name)) - 2))
    + ' '
    + UPPER(SUBSTRING(TRIM(customer_name), CHARINDEX(' ', TRIM(customer_name)) + 1, 1))
    + LOWER(SUBSTRING(TRIM(customer_name), CHARINDEX(' ', TRIM(customer_name)) + 2, LEN(customer_name)));

-- Verify
SELECT TOP 20 customer_name FROM customers;


-- ════════════════════════════════════════════════════════════
-- ORDERS — order_status
-- Dirty:  Done, Complete, COMPLETED, pending, In Progress,
--         Cancelled, Canceled, REFUNDED, Refund
-- Clean:  Completed | Pending | Cancelled | Refunded
-- ════════════════════════════════════════════════════════════

-- Preview
SELECT
    order_id,
    order_status AS original_status,
    CASE
        WHEN UPPER(TRIM(order_status)) IN ('COMPLETE','COMPLETED','DONE')     THEN 'Completed'
        WHEN UPPER(TRIM(order_status)) IN ('REFUNDED','REFUND')               THEN 'Refunded'
        WHEN UPPER(TRIM(order_status)) IN ('PENDING','IN PROGRESS')           THEN 'Pending'
        WHEN UPPER(TRIM(order_status)) IN ('CANCELLED','CANCELED')            THEN 'Cancelled'
        ELSE NULL
    END AS clean_status
FROM orders;

-- Update
UPDATE orders
SET order_status =
    CASE
        WHEN UPPER(TRIM(order_status)) IN ('COMPLETE','COMPLETED','DONE')     THEN 'Completed'
        WHEN UPPER(TRIM(order_status)) IN ('REFUNDED','REFUND')               THEN 'Refunded'
        WHEN UPPER(TRIM(order_status)) IN ('PENDING','IN PROGRESS')           THEN 'Pending'
        WHEN UPPER(TRIM(order_status)) IN ('CANCELLED','CANCELED')            THEN 'Cancelled'
        ELSE NULL
    END;

-- Verify — should return exactly 4 values
SELECT DISTINCT order_status FROM orders ORDER BY order_status;


-- ════════════════════════════════════════════════════════════
-- ORDERS — payment_method
-- Dirty:  PAYPAL, pp, Pay Pal, CC, credit card, CREDIT,
--         ApplePay, ShopPay, Debit, debit card
-- Clean:  PayPal | Credit Card | Apple Pay | Debit Card | Shop Pay
-- ════════════════════════════════════════════════════════════

-- Preview
SELECT
    order_id,
    payment_method AS original_payment,
    CASE
        WHEN UPPER(TRIM(payment_method)) IN ('PP','PAY PAL','PAYPAL')               THEN 'PayPal'
        WHEN UPPER(TRIM(payment_method)) IN ('CC','CREDIT','CREDIT CARD','CREDITCARD') THEN 'Credit Card'
        WHEN UPPER(TRIM(payment_method)) IN ('APPLEPAY','APPLE PAY')                THEN 'Apple Pay'
        WHEN UPPER(TRIM(payment_method)) IN ('DEBIT CARD','DEBIT')                  THEN 'Debit Card'
        WHEN UPPER(TRIM(payment_method)) IN ('SHOPPAY','SHOP PAY')                  THEN 'Shop Pay'
        ELSE NULL
    END AS clean_payment
FROM orders;

-- Update
UPDATE orders
SET payment_method =
    CASE
        WHEN UPPER(TRIM(payment_method)) IN ('PP','PAY PAL','PAYPAL')               THEN 'PayPal'
        WHEN UPPER(TRIM(payment_method)) IN ('CC','CREDIT','CREDIT CARD','CREDITCARD') THEN 'Credit Card'
        WHEN UPPER(TRIM(payment_method)) IN ('APPLEPAY','APPLE PAY')                THEN 'Apple Pay'
        WHEN UPPER(TRIM(payment_method)) IN ('DEBIT CARD','DEBIT')                  THEN 'Debit Card'
        WHEN UPPER(TRIM(payment_method)) IN ('SHOPPAY','SHOP PAY')                  THEN 'Shop Pay'
        ELSE NULL
    END;

-- Verify — should return exactly 5 values
SELECT DISTINCT payment_method FROM orders ORDER BY payment_method;


-- ════════════════════════════════════════════════════════════
-- ORDERS — shipping_state
-- Same mapping as customers.state (15 US state codes)
-- NOTE: NULLs after update were filled from customers table
--       using a JOIN on customer_id (see fix below)
-- ════════════════════════════════════════════════════════════

-- Preview
SELECT
    order_id,
    shipping_state AS original_state,
    CASE
        WHEN LOWER(TRIM(shipping_state)) IN ('florida','fla.','fl')           THEN 'FL'
        WHEN LOWER(TRIM(shipping_state)) IN ('new york','n.y','ny')           THEN 'NY'
        WHEN LOWER(TRIM(shipping_state)) IN ('texas','tx','tex.')             THEN 'TX'
        WHEN LOWER(TRIM(shipping_state)) IN ('california','calif.','ca')      THEN 'CA'
        WHEN LOWER(TRIM(shipping_state)) IN ('illinois','ill.','il')          THEN 'IL'
        WHEN LOWER(TRIM(shipping_state)) IN ('washington','wash.','wa')       THEN 'WA'
        WHEN LOWER(TRIM(shipping_state)) IN ('colorado','colo.','co')         THEN 'CO'
        WHEN LOWER(TRIM(shipping_state)) IN ('georgia','ga','ga.')            THEN 'GA'
        WHEN LOWER(TRIM(shipping_state)) IN ('arizona','ariz.','az')          THEN 'AZ'
        WHEN LOWER(TRIM(shipping_state)) IN ('north carolina','n.c','nc')     THEN 'NC'
        WHEN LOWER(TRIM(shipping_state)) IN ('ohio','oh')                     THEN 'OH'
        WHEN LOWER(TRIM(shipping_state)) IN ('michigan','mich.','mi')         THEN 'MI'
        WHEN LOWER(TRIM(shipping_state)) IN ('new jersey','n.j','nj')         THEN 'NJ'
        WHEN LOWER(TRIM(shipping_state)) IN ('virginia','va.','va')           THEN 'VA'
        WHEN LOWER(TRIM(shipping_state)) IN ('massachusetts','mass.','ma')    THEN 'MA'
        ELSE NULL
    END AS clean_state
FROM orders;

-- Update
UPDATE orders
SET shipping_state =
    CASE
        WHEN LOWER(TRIM(shipping_state)) IN ('florida','fla.','fl')           THEN 'FL'
        WHEN LOWER(TRIM(shipping_state)) IN ('new york','n.y','ny')           THEN 'NY'
        WHEN LOWER(TRIM(shipping_state)) IN ('texas','tx','tex.')             THEN 'TX'
        WHEN LOWER(TRIM(shipping_state)) IN ('california','calif.','ca')      THEN 'CA'
        WHEN LOWER(TRIM(shipping_state)) IN ('illinois','ill.','il')          THEN 'IL'
        WHEN LOWER(TRIM(shipping_state)) IN ('washington','wash.','wa')       THEN 'WA'
        WHEN LOWER(TRIM(shipping_state)) IN ('colorado','colo.','co')         THEN 'CO'
        WHEN LOWER(TRIM(shipping_state)) IN ('georgia','ga','ga.')            THEN 'GA'
        WHEN LOWER(TRIM(shipping_state)) IN ('arizona','ariz.','az')          THEN 'AZ'
        WHEN LOWER(TRIM(shipping_state)) IN ('north carolina','n.c','nc')     THEN 'NC'
        WHEN LOWER(TRIM(shipping_state)) IN ('ohio','oh')                     THEN 'OH'
        WHEN LOWER(TRIM(shipping_state)) IN ('michigan','mich.','mi')         THEN 'MI'
        WHEN LOWER(TRIM(shipping_state)) IN ('new jersey','n.j','nj')         THEN 'NJ'
        WHEN LOWER(TRIM(shipping_state)) IN ('virginia','va.','va')           THEN 'VA'
        WHEN LOWER(TRIM(shipping_state)) IN ('massachusetts','mass.','ma')    THEN 'MA'
        ELSE NULL
    END;

-- Fix: Fill remaining NULLs from customers table
-- Some shipping states didn't match — we used the customer's
-- home state as a fallback rather than losing the data.
UPDATE o
SET o.shipping_state = c.state
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.shipping_state IS NULL;

-- Verify — should return exactly 15 state codes, 0 NULLs
SELECT DISTINCT shipping_state FROM orders ORDER BY shipping_state;


-- ════════════════════════════════════════════════════════════
-- RETURNS — return_status
-- Dirty:  approved, APPROVED, Accepted, pending, Under Review,
--         rejected, REJECTED, Denied
-- Clean:  Approved | Pending | Rejected
-- ════════════════════════════════════════════════════════════

-- Preview
SELECT
    return_id,
    return_status AS original_status,
    CASE
        WHEN UPPER(TRIM(return_status)) IN ('ACCEPTED','APPROVED')    THEN 'Approved'
        WHEN UPPER(TRIM(return_status)) IN ('PENDING','UNDER REVIEW') THEN 'Pending'
        WHEN UPPER(TRIM(return_status)) IN ('DENIED','REJECTED')      THEN 'Rejected'
        ELSE NULL
    END AS clean_status
FROM returns;

-- Update
UPDATE returns
SET return_status =
    CASE
        WHEN UPPER(TRIM(return_status)) IN ('ACCEPTED','APPROVED')    THEN 'Approved'
        WHEN UPPER(TRIM(return_status)) IN ('PENDING','UNDER REVIEW') THEN 'Pending'
        WHEN UPPER(TRIM(return_status)) IN ('DENIED','REJECTED')      THEN 'Rejected'
        ELSE NULL
    END;

-- Verify
SELECT DISTINCT return_status FROM returns ORDER BY return_status;


-- ════════════════════════════════════════════════════════════
-- RETURNS — reason
-- Dirty:  WRONG SIZE, Size issue, DEFECTIVE, Damaged,
--         Changed Mind, Dont want, DON'T WANT, Wrong Item, etc.
-- Clean:  Wrong Size | Defective | Changed Mind | Wrong Item | Not As Described
-- NOTE:   DON''T WANT uses escaped apostrophe (two single quotes)
-- ════════════════════════════════════════════════════════════

-- Preview
SELECT
    return_id,
    reason AS original_reason,
    CASE
        WHEN UPPER(TRIM(reason)) IN ('WRONG SIZE','SIZE ISSUE','WRONG SIZE ORDERED')                  THEN 'Wrong Size'
        WHEN UPPER(TRIM(reason)) IN ('DEFECTIVE','DAMAGED','FAULTY')                                  THEN 'Defective'
        WHEN UPPER(TRIM(reason)) IN ('CHANGED MIND','NO LONGER NEEDED','DONT WANT','DON''T WANT')     THEN 'Changed Mind'
        WHEN UPPER(TRIM(reason)) IN ('WRONG ITEM','INCORRECT ITEM SENT')                              THEN 'Wrong Item'
        WHEN UPPER(TRIM(reason)) IN ('NOT AS DESCRIBED','MISLEADING LISTING')                         THEN 'Not As Described'
        ELSE NULL
    END AS clean_reason
FROM returns;

-- Update
UPDATE returns
SET reason =
    CASE
        WHEN UPPER(TRIM(reason)) IN ('WRONG SIZE','SIZE ISSUE','WRONG SIZE ORDERED')                  THEN 'Wrong Size'
        WHEN UPPER(TRIM(reason)) IN ('DEFECTIVE','DAMAGED','FAULTY')                                  THEN 'Defective'
        WHEN UPPER(TRIM(reason)) IN ('CHANGED MIND','NO LONGER NEEDED','DONT WANT','DON''T WANT')     THEN 'Changed Mind'
        WHEN UPPER(TRIM(reason)) IN ('WRONG ITEM','INCORRECT ITEM SENT')                              THEN 'Wrong Item'
        WHEN UPPER(TRIM(reason)) IN ('NOT AS DESCRIBED','MISLEADING LISTING')                         THEN 'Not As Described'
        ELSE NULL
    END;

-- Verify
SELECT DISTINCT reason FROM returns ORDER BY reason;


-- ════════════════════════════════════════════════════════════
-- PRODUCTS — product_name
-- Dirty:  AIR HOODIE, Drrop Tee (typo), Chain Neklace (typo),
--         zip hoodie, SlidePro, CARGO PANTS, etc.
-- Clean:  Canonical product names matching the product catalogue
-- NOTE:   Only 15 rows so we use exact matching (=) not IN
--         ELSE product_name keeps original if no match found
-- ════════════════════════════════════════════════════════════

-- Update product_name
UPDATE products
SET product_name =
    CASE
        WHEN UPPER(TRIM(product_name)) = 'AIR HOODIE'           THEN 'Air Hoodie'
        WHEN UPPER(TRIM(product_name)) = 'BUCKET HAT'           THEN 'Bucket Hat'
        WHEN UPPER(TRIM(product_name)) = 'CANVAS TOTE'          THEN 'Canvas Tote'
        WHEN UPPER(TRIM(product_name)) = 'CARGO PANTS'          THEN 'Cargo Pants'
        WHEN UPPER(TRIM(product_name)) = 'CHAIN NEKLACE'        THEN 'Chain Necklace'
        WHEN UPPER(TRIM(product_name)) = 'CLASSIC T'            THEN 'Classic Tee'
        WHEN UPPER(TRIM(product_name)) = 'DRROP TEE'            THEN 'Drop Tee'
        WHEN UPPER(TRIM(product_name)) = 'GRAPHIC TEE VOL2'     THEN 'Graphic Tee Vol2'
        WHEN UPPER(TRIM(product_name)) = 'HIGHTOP FORCE'        THEN 'High Top Force'
        WHEN UPPER(TRIM(product_name)) = 'JOGGER SLIM'          THEN 'Jogger Slim'
        WHEN UPPER(TRIM(product_name)) = 'PIXEL CAP SNAPBACK'   THEN 'PixelCap Snapback'
        WHEN UPPER(TRIM(product_name)) = 'PUFFA JACKET'         THEN 'Puffer Jacket'
        WHEN UPPER(TRIM(product_name)) = 'RETRO RUNNER SNEAKER' THEN 'Retro Runner Sneaker'
        WHEN UPPER(TRIM(product_name)) = 'SLIDEPRO'             THEN 'Slide Pro'
        WHEN UPPER(TRIM(product_name)) = 'ZIP HOODIE'           THEN 'Zip Hoodie'
        ELSE product_name
    END;


-- ════════════════════════════════════════════════════════════
-- PRODUCTS — category
-- Dirty:  HOODIES, hoodies, SHOES, Tees, T-Shirts, 
--         BOTTOMS, accessories
-- Clean:  Hoodies | Sneakers | T-Shirts | Bottoms | Accessories | Caps
-- ════════════════════════════════════════════════════════════

-- Update category
UPDATE products
SET category =
    CASE
        WHEN UPPER(TRIM(category)) IN ('HOODIES','HOODIE')  THEN 'Hoodies'
        WHEN UPPER(TRIM(category)) IN ('SHOES','SNEAKERS')  THEN 'Sneakers'
        WHEN UPPER(TRIM(category)) IN ('TEES','T-SHIRTS')   THEN 'T-Shirts'
        WHEN UPPER(TRIM(category)) IN ('BOTTOMS','BOTTOM')  THEN 'Bottoms'
        WHEN UPPER(TRIM(category)) = 'ACCESSORIES'          THEN 'Accessories'
        WHEN UPPER(TRIM(category)) = 'CAPS'                 THEN 'Caps'
        ELSE category
    END;

-- Also fix missing cost_price for Puffer Jacket
UPDATE products
SET cost_price = 80.00
WHERE product_name = 'Puffer Jacket';

-- Verify products table is fully clean
SELECT product_name, category, cost_price, retail_price
FROM products
ORDER BY category, product_name;

/*
===============================================================================
PROJECT: SQL DATA WAREHOUSE
SCRIPT: Gold Layer Quality Checks
DATABASE: MySQL Workbench
===============================================================================

SCRIPT PURPOSE:

    This script performs data quality checks to validate the integrity,
    consistency, and accuracy of the Gold Layer.

QUALITY CHECKS:

    1. Check uniqueness of customer surrogate keys.
    2. Check uniqueness of product surrogate keys.
    3. Validate relationships between fact and dimension views.
    4. Identify missing customer and product dimension keys.

EXPECTED RESULTS:

    - No duplicate customer keys.
    - No duplicate product keys.
    - No missing customer keys in the fact view.
    - No missing product keys in the fact view.

USAGE:

    Run these checks after creating the Gold Layer views:

        gold.dim_customers
        gold.dim_products
        gold.fact_sales

REQUIREMENT:

    MySQL 8.0+

===============================================================================
*/


-- Select Gold database
USE gold;


/*
===============================================================================
1. QUALITY CHECK: gold.dim_customers
===============================================================================

PURPOSE:
    Verify that customer_key is unique in the customer dimension view.

EXPECTATION:
    No rows should be returned.

===============================================================================
*/

-- Check duplicate customer surrogate keys

SELECT
    customer_key,
    COUNT(*) AS duplicate_count

FROM gold.dim_customers

GROUP BY customer_key

HAVING COUNT(*) > 1;


/*
===============================================================================
2. QUALITY CHECK: gold.dim_products
===============================================================================

PURPOSE:
    Verify that product_key is unique in the product dimension view.

EXPECTATION:
    No rows should be returned.

===============================================================================
*/

-- Check duplicate product surrogate keys

SELECT
    product_key,
    COUNT(*) AS duplicate_count

FROM gold.dim_products

GROUP BY product_key

HAVING COUNT(*) > 1;


/*
===============================================================================
3. QUALITY CHECK: gold.fact_sales
===============================================================================

PURPOSE:
    Validate the relationships between the sales fact view and
    customer and product dimension views.

CHECKS:
    1. Verify that every sales record has a matching customer.
    2. Verify that every sales record has a matching product.
    3. Identify records with missing dimension keys.

EXPECTATION:
    No rows should be returned.

===============================================================================
*/

-- Check referential integrity between fact and dimension views

SELECT
    f.order_number,
    f.customer_key,
    f.product_key,
    c.customer_id,
    p.product_id

FROM gold.fact_sales AS f

-- Connect sales fact with customer dimension
LEFT JOIN gold.dim_customers AS c
    ON c.customer_key = f.customer_key

-- Connect sales fact with product dimension
LEFT JOIN gold.dim_products AS p
    ON p.product_key = f.product_key

-- Identify missing customer or product matches
WHERE p.product_key IS NULL
   OR c.customer_key IS NULL;


/*
===============================================================================
4. ADDITIONAL QUALITY CHECKS (RECOMMENDED)
===============================================================================

PURPOSE:
    Provide additional validation of Gold Layer records.

===============================================================================
*/


-- ---------------------------------------------------------------------------
-- 4.1 Check missing customer keys in fact_sales
-- Expected Result: No rows.
-- ---------------------------------------------------------------------------

SELECT *
FROM gold.fact_sales
WHERE customer_key IS NULL;


-- ---------------------------------------------------------------------------
-- 4.2 Check missing product keys in fact_sales
-- Expected Result: No rows.
-- ---------------------------------------------------------------------------

SELECT *
FROM gold.fact_sales
WHERE product_key IS NULL;


-- ---------------------------------------------------------------------------
-- 4.3 Check total records in Gold Layer
-- ---------------------------------------------------------------------------

SELECT
    'dim_customers' AS view_name,
    COUNT(*) AS total_records
FROM gold.dim_customers

UNION ALL

SELECT
    'dim_products',
    COUNT(*)
FROM gold.dim_products

UNION ALL

SELECT
    'fact_sales',
    COUNT(*)
FROM gold.fact_sales;


/*
===============================================================================
END OF GOLD LAYER QUALITY CHECKS
===============================================================================
*/

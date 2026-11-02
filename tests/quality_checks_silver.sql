/*
===============================================================================
PROJECT: SQL DATA WAREHOUSE
SCRIPT: Silver Layer Quality Checks
DATABASE: MySQL Workbench
===============================================================================

SCRIPT PURPOSE:

    This script performs data quality checks on all six Silver layer tables.

    It checks:
        1. NULL values and duplicate primary keys.
        2. Unwanted spaces in string columns.
        3. Data standardization and consistency.
        4. Invalid date ranges and date orders.
        5. Negative or missing numerical values.
        6. Data consistency between related columns.

EXPECTED RESULTS:

    - No duplicate primary keys.
    - No unwanted spaces.
    - No invalid or negative values.
    - Standardized values.
    - Valid date ranges.
    - Consistent sales calculations.

USAGE:

    Run this script after executing:

        CALL silver.load_silver();

REQUIREMENT:

    MySQL 8.0+

===============================================================================
*/


-- Select Silver database
USE silver;


/*
===============================================================================
1. QUALITY CHECKS: silver.crm_cust_info
===============================================================================

PURPOSE:
    Validate customer information, identify duplicate customer IDs,
    check unwanted spaces, and verify standardized marital status.
*/


-- ---------------------------------------------------------------------------
-- 1.1 Check NULLs or Duplicate Customer IDs
-- Expected Result: No rows.
-- ---------------------------------------------------------------------------

SELECT
    cst_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1
    OR cst_id IS NULL;


-- ---------------------------------------------------------------------------
-- 1.2 Check Unwanted Spaces in Customer Key
-- Expected Result: No rows.
-- ---------------------------------------------------------------------------

SELECT
    cst_key
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);


-- ---------------------------------------------------------------------------
-- 1.3 Check Customer Name Spaces
-- Expected Result: No rows.
-- ---------------------------------------------------------------------------

SELECT
    cst_firstname,
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
   OR cst_lastname != TRIM(cst_lastname);


-- ---------------------------------------------------------------------------
-- 1.4 Check Marital Status Standardization
-- Expected Values: Single, Married, n/a.
-- ---------------------------------------------------------------------------

SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;


-- ---------------------------------------------------------------------------
-- 1.5 Check Gender Standardization
-- Expected Values: Female, Male, n/a.
-- ---------------------------------------------------------------------------

SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info;


/*
===============================================================================
2. QUALITY CHECKS: silver.crm_prd_info
===============================================================================

PURPOSE:
    Validate product IDs, product names, product costs, product lines,
    and product date ranges.
*/


-- ---------------------------------------------------------------------------
-- 2.1 Check NULLs or Duplicate Product IDs
-- Expected Result: No rows.
-- ---------------------------------------------------------------------------

SELECT
    prd_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1
    OR prd_id IS NULL;


-- ---------------------------------------------------------------------------
-- 2.2 Check Unwanted Spaces in Product Names
-- Expected Result: No rows.
-- ---------------------------------------------------------------------------

SELECT
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);


-- ---------------------------------------------------------------------------
-- 2.3 Check NULL or Negative Product Costs
-- Expected Result: No rows.
-- ---------------------------------------------------------------------------

SELECT
    prd_id,
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0
   OR prd_cost IS NULL;


-- ---------------------------------------------------------------------------
-- 2.4 Check Product Line Standardization
-- Expected Values:
-- Mountain, Road, Other Sales, Touring, n/a.
-- ---------------------------------------------------------------------------

SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;


-- ---------------------------------------------------------------------------
-- 2.5 Check Invalid Product Date Orders
-- Expected Result: No rows.
-- Start Date must not be greater than End Date.
-- ---------------------------------------------------------------------------

SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


/*
===============================================================================
3. QUALITY CHECKS: silver.crm_sales_details
===============================================================================

PURPOSE:
    Validate sales dates, order dates, shipping dates, due dates,
    sales amounts, quantities, and prices.
*/


-- ---------------------------------------------------------------------------
-- 3.1 Check Invalid Sales Dates in Bronze
-- Expected Result: No rows.
--
-- MySQL Conversion:
-- LEN()       -> CHAR_LENGTH()
-- VARCHAR     -> CHAR
-- NULLIF()    -> NULLIF()
-- ---------------------------------------------------------------------------

SELECT
    sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt IS NULL
   OR sls_due_dt <= 0
   OR CHAR_LENGTH(CAST(sls_due_dt AS CHAR)) != 8
   OR sls_due_dt > 20500101
   OR sls_due_dt < 19000101;


-- ---------------------------------------------------------------------------
-- 3.2 Check Invalid Date Orders in Silver
-- Expected Result: No rows.
--
-- Order date must not be later than shipping date or due date.
-- ---------------------------------------------------------------------------

SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;


-- ---------------------------------------------------------------------------
-- 3.3 Check Sales Calculation Consistency
-- Expected Result: No rows.
--
-- Formula:
-- Sales = Quantity * Price
--
-- Also checks NULL, zero, and negative values.
-- ---------------------------------------------------------------------------

SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY
    sls_sales,
    sls_quantity,
    sls_price;


/*
===============================================================================
4. QUALITY CHECKS: silver.erp_cust_az12
===============================================================================

PURPOSE:
    Validate customer birthdates and standardized gender values.
*/


-- ---------------------------------------------------------------------------
-- 4.1 Identify Out-of-Range Birthdates
-- Expected Birthdate Range:
-- 1924-01-01 to Current Date.
--
-- MySQL Conversion:
-- GETDATE() -> CURDATE()
-- ---------------------------------------------------------------------------

SELECT DISTINCT
    bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'
   OR bdate > CURDATE();


-- ---------------------------------------------------------------------------
-- 4.2 Check Gender Standardization
-- Expected Values: Female, Male, n/a.
-- ---------------------------------------------------------------------------

SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;


/*
===============================================================================
5. QUALITY CHECKS: silver.erp_loc_a101
===============================================================================

PURPOSE:
    Verify country names and codes are standardized.
*/


-- ---------------------------------------------------------------------------
-- 5.1 Check Country Standardization
-- Expected:
-- Germany, United States, n/a, and other valid country values.
-- ---------------------------------------------------------------------------

SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;


/*
===============================================================================
6. QUALITY CHECKS: silver.erp_px_cat_g1v2
===============================================================================

PURPOSE:
    Validate product category, subcategory, and maintenance information.
*/


-- ---------------------------------------------------------------------------
-- 6.1 Check Unwanted Spaces
-- Expected Result: No rows.
-- ---------------------------------------------------------------------------

SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
   OR subcat != TRIM(subcat)
   OR maintenance != TRIM(maintenance);


-- ---------------------------------------------------------------------------
-- 6.2 Check Maintenance Standardization
-- Expected Result: Distinct valid maintenance values.
-- ---------------------------------------------------------------------------

SELECT DISTINCT
    maintenance
FROM silver.erp_px_cat_g1v2;


/*
===============================================================================
END OF SILVER LAYER QUALITY CHECKS
===============================================================================
*/

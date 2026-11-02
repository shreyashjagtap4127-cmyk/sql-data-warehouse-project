/*
===============================================================================
PROJECT: SQL DATA WAREHOUSE
STORED PROCEDURE: Load Silver Layer (Bronze -> Silver)
DATABASE: MySQL Workbench
===============================================================================

PURPOSE:
    Load cleaned and transformed data from Bronze layer into Silver layer.

OPERATIONS:
    1. Truncate Silver tables.
    2. Clean customer information.
    3. Transform product information.
    4. Clean and validate sales information.
    5. Standardize ERP customer information.
    6. Standardize ERP location information.
    7. Load ERP product category information.
    8. Track execution time.
    9. Handle SQL errors.

EXECUTION:
    CALL silver.load_silver();

REQUIREMENT:
    MySQL 8.0+

===============================================================================
*/


-- Select Silver database
USE silver;


/*
===============================================================================
CREATE STORED PROCEDURE
===============================================================================
*/

DELIMITER $$

CREATE PROCEDURE silver.load_silver()

BEGIN

    /*
    ---------------------------------------------------------------------------
    1. DECLARE VARIABLES
    ---------------------------------------------------------------------------
    */

    DECLARE start_time DATETIME;
    DECLARE end_time DATETIME;

    DECLARE batch_start_time DATETIME;
    DECLARE batch_end_time DATETIME;

    DECLARE error_message TEXT;
    DECLARE error_number INT;


    /*
    ---------------------------------------------------------------------------
    2. ERROR HANDLER
    ---------------------------------------------------------------------------
    */

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN

        GET DIAGNOSTICS CONDITION 1
            error_number = MYSQL_ERRNO,
            error_message = MESSAGE_TEXT;

        SELECT
            'ERROR DURING SILVER LAYER LOADING' AS status,
            error_number AS error_code,
            error_message AS error_description;

    END;


    /*
    ---------------------------------------------------------------------------
    START LOADING
    ---------------------------------------------------------------------------
    */

    SET batch_start_time = NOW();

    SELECT '========================================' AS message;
    SELECT 'STARTING SILVER LAYER LOADING' AS message;
    SELECT '========================================' AS message;


    /*
    ===========================================================================
    SECTION 1: CRM TABLES
    ===========================================================================
    */

    SELECT 'LOADING CRM TABLES' AS message;


    /*
    ---------------------------------------------------------------------------
    TABLE 1: silver.crm_cust_info
    ---------------------------------------------------------------------------

    TRANSFORMATIONS:
        - Remove duplicate customer records.
        - Keep the latest customer record.
        - Remove unwanted spaces.
        - Standardize marital status.
        - Standardize gender.
        - Handle missing creation dates.

    ---------------------------------------------------------------------------
    */

    SET start_time = NOW();

    TRUNCATE TABLE silver.crm_cust_info;

    INSERT INTO silver.crm_cust_info
    (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )

    SELECT
        cst_id,
        cst_key,

        TRIM(cst_firstname),
        TRIM(cst_lastname),

        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'S'
                THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M'
                THEN 'Married'
            ELSE 'n/a'
        END,

        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F'
                THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M'
                THEN 'Male'
            ELSE 'n/a'
        END,

        cst_create_date

    FROM
    (
        SELECT
            *,
            ROW_NUMBER() OVER
            (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS flag_last

        FROM bronze.crm_cust_info

        WHERE cst_id IS NOT NULL

    ) AS t

    WHERE flag_last = 1;


    SET end_time = NOW();

    SELECT
        'crm_cust_info completed' AS status,
        TIMESTAMPDIFF(SECOND, start_time, end_time) AS duration_seconds;


    /*
    ---------------------------------------------------------------------------
    TABLE 2: silver.crm_prd_info
    ---------------------------------------------------------------------------

    TRANSFORMATIONS:
        - Extract category ID.
        - Extract product key.
        - Replace NULL product cost with zero.
        - Standardize product line.
        - Calculate product end date.

    ---------------------------------------------------------------------------
    */

    SET start_time = NOW();

    TRUNCATE TABLE silver.crm_prd_info;

    INSERT INTO silver.crm_prd_info
    (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )

    SELECT
        prd_id,

        -- Extract category ID
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,

        -- Extract product key
        SUBSTRING(prd_key, 7, CHAR_LENGTH(prd_key)) AS prd_key,

        prd_nm,

        -- Replace NULL cost with zero
        IFNULL(prd_cost, 0) AS prd_cost,

        -- Standardize product line
        CASE
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,

        DATE(prd_start_dt) AS prd_start_dt,

        -- Calculate end date as one day before next start date
        DATE_SUB(next_start_dt, INTERVAL 1 DAY) AS prd_end_dt

    FROM
    (
        -- Calculate next product start date using LEAD()
        SELECT
            *,
            LEAD(prd_start_dt) OVER
            (
                PARTITION BY prd_key
                ORDER BY prd_start_dt
            ) AS next_start_dt

        FROM bronze.crm_prd_info

    ) AS product_data;


    SET end_time = NOW();

    SELECT
        'crm_prd_info completed' AS status,
        TIMESTAMPDIFF(SECOND, start_time, end_time) AS duration_seconds;


    /*
    ---------------------------------------------------------------------------
    TABLE 3: silver.crm_sales_details
    ---------------------------------------------------------------------------

    TRANSFORMATIONS:
        - Convert YYYYMMDD integer dates into DATE format.
        - Handle invalid dates.
        - Recalculate incorrect sales amounts.
        - Derive invalid product prices.

    ---------------------------------------------------------------------------
    */

    SET start_time = NOW();

    TRUNCATE TABLE silver.crm_sales_details;

    INSERT INTO silver.crm_sales_details
    (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )

    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        -- Convert order date
        CASE
            WHEN sls_order_dt IS NULL
                 OR sls_order_dt = 0
                 OR CHAR_LENGTH(CAST(sls_order_dt AS CHAR)) != 8
            THEN NULL
            ELSE STR_TO_DATE(
                CAST(sls_order_dt AS CHAR), '%Y%m%d'
            )
        END AS sls_order_dt,

        -- Convert shipping date
        CASE
            WHEN sls_ship_dt IS NULL
                 OR sls_ship_dt = 0
                 OR CHAR_LENGTH(CAST(sls_ship_dt AS CHAR)) != 8
            THEN NULL
            ELSE STR_TO_DATE(
                CAST(sls_ship_dt AS CHAR), '%Y%m%d'
            )
        END AS sls_ship_dt,

        -- Convert due date
        CASE
            WHEN sls_due_dt IS NULL
                 OR sls_due_dt = 0
                 OR CHAR_LENGTH(CAST(sls_due_dt AS CHAR)) != 8
            THEN NULL
            ELSE STR_TO_DATE(
                CAST(sls_due_dt AS CHAR), '%Y%m%d'
            )
        END AS sls_due_dt,

        -- Recalculate incorrect sales
        CASE
            WHEN sls_sales IS NULL
                 OR sls_sales <= 0
                 OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,

        sls_quantity,

        -- Calculate price if missing or invalid
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS sls_price

    FROM bronze.crm_sales_details;


    SET end_time = NOW();

    SELECT
        'crm_sales_details completed' AS status,
        TIMESTAMPDIFF(SECOND, start_time, end_time) AS duration_seconds;


    /*
    ===========================================================================
    SECTION 2: ERP TABLES
    ===========================================================================
    */

    SELECT 'LOADING ERP TABLES' AS message;


    /*
    ---------------------------------------------------------------------------
    TABLE 4: silver.erp_cust_az12
    ---------------------------------------------------------------------------

    TRANSFORMATIONS:
        - Remove NAS prefix from customer ID.
        - Set future birthdates to NULL.
        - Standardize gender.

    ---------------------------------------------------------------------------
    */

    SET start_time = NOW();

    TRUNCATE TABLE silver.erp_cust_az12;

    INSERT INTO silver.erp_cust_az12
    (
        cid,
        bdate,
        gen
    )

    SELECT

        CASE
            WHEN cid LIKE 'NAS%'
                THEN SUBSTRING(cid, 4, CHAR_LENGTH(cid))
            ELSE cid
        END AS cid,

        CASE
            WHEN bdate > CURDATE()
                THEN NULL
            ELSE bdate
        END AS bdate,

        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
                THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
                THEN 'Male'
            ELSE 'n/a'
        END AS gen

    FROM bronze.erp_cust_az12;


    SET end_time = NOW();

    SELECT
        'erp_cust_az12 completed' AS status,
        TIMESTAMPDIFF(SECOND, start_time, end_time) AS duration_seconds;


    /*
    ---------------------------------------------------------------------------
    TABLE 5: silver.erp_loc_a101
    ---------------------------------------------------------------------------

    TRANSFORMATIONS:
        - Remove hyphens from customer ID.
        - Convert DE into Germany.
        - Convert US and USA into United States.
        - Handle NULL and blank country values.

    ---------------------------------------------------------------------------
    */

    SET start_time = NOW();

    TRUNCATE TABLE silver.erp_loc_a101;

    INSERT INTO silver.erp_loc_a101
    (
        cid,
        cntry
    )

    SELECT

        REPLACE(cid, '-', '') AS cid,

        CASE
            WHEN TRIM(cntry) = 'DE'
                THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA')
                THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL
                THEN 'n/a'
            ELSE TRIM(cntry)
        END AS cntry

    FROM bronze.erp_loc_a101;


    SET end_time = NOW();

    SELECT
        'erp_loc_a101 completed' AS status,
        TIMESTAMPDIFF(SECOND, start_time, end_time) AS duration_seconds;


    /*
    ---------------------------------------------------------------------------
    TABLE 6: silver.erp_px_cat_g1v2
    ---------------------------------------------------------------------------

    TRANSFORMATIONS:
        - Copy ERP product category information.
        - Preserve category, subcategory, and maintenance values.

    ---------------------------------------------------------------------------
    */

    SET start_time = NOW();

    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    INSERT INTO silver.erp_px_cat_g1v2
    (
        id,
        cat,
        subcat,
        maintenance
    )

    SELECT
        id,
        cat,
        subcat,
        maintenance

    FROM bronze.erp_px_cat_g1v2;


    SET end_time = NOW();

    SELECT
        'erp_px_cat_g1v2 completed' AS status,
        TIMESTAMPDIFF(SECOND, start_time, end_time) AS duration_seconds;


    /*
    ===========================================================================
    FINAL: LOADING COMPLETED
    ===========================================================================
    */

    SET batch_end_time = NOW();

    SELECT
        'SILVER LAYER LOADING COMPLETED SUCCESSFULLY' AS final_status,
        TIMESTAMPDIFF(
            SECOND,
            batch_start_time,
            batch_end_time
        ) AS total_duration_seconds;

END$$


DELIMITER ;

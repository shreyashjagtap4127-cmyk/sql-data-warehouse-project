/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' database.

    If tables already exist, they are dropped and recreated.

    Silver Layer Purpose:
        - Clean and standardize Bronze Layer data.
        - Handle missing and invalid values.
        - Remove duplicate records.
        - Transform raw data into structured data.

Tables Created:
    CRM:
        1. crm_cust_info
        2. crm_prd_info
        3. crm_sales_details

    ERP:
        4. erp_loc_a101
        5. erp_cust_az12
        6. erp_px_cat_g1v2

WARNING:
    Existing tables will be dropped, and all their data will be deleted.
===============================================================================
*/


-- ============================================================================
-- 1. Create CRM Customer Information Table
-- ============================================================================

DROP TABLE IF EXISTS silver.crm_cust_info;

CREATE TABLE silver.crm_cust_info (
    cst_id              INT,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(50),
    cst_lastname        VARCHAR(50),
    cst_marital_status  VARCHAR(50),
    cst_gndr            VARCHAR(50),
    cst_create_date     DATE,
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- 2. Create CRM Product Information Table
-- ============================================================================

DROP TABLE IF EXISTS silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    prd_id              INT,
    cat_id              VARCHAR(50),
    prd_key             VARCHAR(50),
    prd_nm              VARCHAR(50),
    prd_cost            INT,
    prd_line            VARCHAR(50),
    prd_start_dt        DATE,
    prd_end_dt          DATE,
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- 3. Create CRM Sales Details Table
-- ============================================================================

DROP TABLE IF EXISTS silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details (
    sls_ord_num         VARCHAR(50),
    sls_prd_key         VARCHAR(50),
    sls_cust_id         INT,
    sls_order_dt        DATE,
    sls_ship_dt         DATE,
    sls_due_dt          DATE,
    sls_sales           INT,
    sls_quantity        INT,
    sls_price           INT,
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- 4. Create ERP Location Table
-- ============================================================================

DROP TABLE IF EXISTS silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101 (
    cid                 VARCHAR(50),
    cntry               VARCHAR(50),
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- 5. Create ERP Customer Table
-- ============================================================================

DROP TABLE IF EXISTS silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12 (
    cid                 VARCHAR(50),
    bdate               DATE,
    gen                 VARCHAR(50),
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- 6. Create ERP Product Category Table
-- ============================================================================

DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2 (
    id                  VARCHAR(50),
    cat                 VARCHAR(50),
    subcat              VARCHAR(50),
    maintenance         VARCHAR(50),
    dwh_create_date     DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- END OF SCRIPT
-- ============================================================================

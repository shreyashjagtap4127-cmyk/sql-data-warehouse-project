/*
===============================================================================
Stored Procedure: Load Bronze Layer
===============================================================================
Script Purpose:
    This procedure prepares the Bronze Layer by truncating all existing
    records from the six Bronze tables.

    CSV bulk loading is performed separately using LOAD DATA LOCAL INFILE
    because MySQL does not support LOAD DATA inside stored procedures.

Tables:
    CRM:
        1. crm_cust_info
        2. crm_prd_info
        3. crm_sales_details

    ERP:
        4. erp_loc_a101
        5. erp_cust_az12
        6. erp_px_cat_g1v2
===============================================================================
*/

DROP PROCEDURE IF EXISTS bronze.load_bronze;

DELIMITER $$

CREATE PROCEDURE bronze.load_bronze()

BEGIN

    DECLARE batch_start_time DATETIME;
    DECLARE batch_end_time DATETIME;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @error_message = MESSAGE_TEXT,
            @error_number = MYSQL_ERRNO;

        SELECT
            'ERROR OCCURRED DURING BRONZE LOADING' AS Status,
            @error_message AS Error_Message,
            @error_number AS Error_Number;
    END;

    SET batch_start_time = NOW();

    SELECT '========================================' AS Message;
    SELECT 'Loading Bronze Layer' AS Message;
    SELECT '========================================' AS Message;

    -- CRM TABLES

    SELECT '----------------------------------------' AS Message;
    SELECT 'Loading CRM Tables' AS Message;
    SELECT '----------------------------------------' AS Message;

    SELECT 'Truncating Table: bronze.crm_cust_info' AS Message;
    TRUNCATE TABLE bronze.crm_cust_info;

    SELECT 'Truncating Table: bronze.crm_prd_info' AS Message;
    TRUNCATE TABLE bronze.crm_prd_info;

    SELECT 'Truncating Table: bronze.crm_sales_details' AS Message;
    TRUNCATE TABLE bronze.crm_sales_details;


    -- ERP TABLES

    SELECT '----------------------------------------' AS Message;
    SELECT 'Loading ERP Tables' AS Message;
    SELECT '----------------------------------------' AS Message;

    SELECT 'Truncating Table: bronze.erp_loc_a101' AS Message;
    TRUNCATE TABLE bronze.erp_loc_a101;

    SELECT 'Truncating Table: bronze.erp_cust_az12' AS Message;
    TRUNCATE TABLE bronze.erp_cust_az12;

    SELECT 'Truncating Table: bronze.erp_px_cat_g1v2' AS Message;
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;


    SET batch_end_time = NOW();

    SELECT '========================================' AS Message;
    SELECT 'Bronze Layer Preparation Completed' AS Message;

    SELECT
        TIMESTAMPDIFF(SECOND, batch_start_time, batch_end_time)
        AS Total_Duration_Seconds;

    SELECT '========================================' AS Message;

END $$

DELIMITER ;

/*
===============================================================================
Bulk Insert: Bronze Layer
===============================================================================
Script Purpose:
    Import CSV files into Bronze layer tables using LOAD DATA LOCAL INFILE.

    FIRST ROW:
        Skips the CSV header.

    FIELD TERMINATOR:
        Comma (,)

    ENCLOSED BY:
        Double quotation marks (")
===============================================================================
*/

-- 1. Load CRM Customer Information
LOAD DATA LOCAL INFILE 'C:/Users/nitro v/Downloads/sql-data-warehouse-project (1)/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
INTO TABLE bronze.crm_cust_info
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


-- 2. Load CRM Product Information
LOAD DATA LOCAL INFILE 'C:/Users/nitro v/Downloads/sql-data-warehouse-project (1)/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
INTO TABLE bronze.crm_prd_info
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


-- 3. Load CRM Sales Details
LOAD DATA LOCAL INFILE 'C:/Users/nitro v/Downloads/sql-data-warehouse-project (1)/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
INTO TABLE bronze.crm_sales_details
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


-- 4. Load ERP Location
LOAD DATA LOCAL INFILE 'C:/Users/nitro v/Downloads/sql-data-warehouse-project (1)/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv'
INTO TABLE bronze.erp_loc_a101
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


-- 5. Load ERP Customer
LOAD DATA LOCAL INFILE 'C:/Users/nitro v/Downloads/sql-data-warehouse-project (1)/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
INTO TABLE bronze.erp_cust_az12
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


-- 6. Load ERP Product Category
LOAD DATA LOCAL INFILE 'C:/Users/nitro v/Downloads/sql-data-warehouse-project (1)/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
INTO TABLE bronze.erp_px_cat_g1v2
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

/*
===============================================================================
Stored Procedure: Check Bronze Layer
===============================================================================
Script Purpose:
    This procedure verifies the data loaded into all Bronze Layer tables.

    It displays:
        1. Table Name
        2. Total Number of Records

===============================================================================
*/
SELECT 'crm_cust_info' AS Table_Name, COUNT(*) AS Total_Rows
FROM bronze.crm_cust_info

UNION ALL

SELECT 'crm_prd_info', COUNT(*)
FROM bronze.crm_prd_info

UNION ALL

SELECT 'crm_sales_details', COUNT(*)
FROM bronze.crm_sales_details

UNION ALL

SELECT 'erp_loc_a101', COUNT(*)
FROM bronze.erp_loc_a101

UNION ALL

SELECT 'erp_cust_az12', COUNT(*)
FROM bronze.erp_cust_az12

UNION ALL

SELECT 'erp_px_cat_g1v2', COUNT(*)
FROM bronze.erp_px_cat_g1v2;

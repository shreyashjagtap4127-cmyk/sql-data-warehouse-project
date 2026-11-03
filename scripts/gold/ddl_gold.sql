/*
===============================================================================
PROJECT: SQL DATA WAREHOUSE
SCRIPT: Gold Layer - Create Views
DATABASE: MySQL Workbench
===============================================================================

SCRIPT PURPOSE:

    This script creates views for the Gold layer of the Data Warehouse.

    The Gold layer represents the final business-ready data using
    Star Schema architecture.

    It contains:
        1. Customer Dimension
        2. Product Dimension
        3. Sales Fact

VIEWS CREATED:

    1. gold.dim_customers
    2. gold.dim_products
    3. gold.fact_sales

DATA SOURCE:

    Silver Layer

USAGE:

    These views can be queried directly for analytics,
    reporting, and business intelligence.

REQUIREMENT:

    MySQL 8.0+

===============================================================================
*/


-- ============================================================================
-- CREATE GOLD DATABASE
-- ============================================================================

CREATE DATABASE IF NOT EXISTS gold;

USE gold;


/*
===============================================================================
1. CREATE DIMENSION: gold.dim_customers
===============================================================================

PURPOSE:

    Create a customer dimension by combining customer information
    from CRM and ERP tables.

TRANSFORMATIONS:

    1. Generate a surrogate customer key using ROW_NUMBER().
    2. Retrieve customer ID and customer number.
    3. Retrieve first name and last name.
    4. Retrieve country information from ERP.
    5. Retrieve marital status from CRM.
    6. Use CRM gender as the primary source.
    7. Use ERP gender as a fallback.
    8. Retrieve customer birthdate and creation date.

===============================================================================
*/


-- Drop existing customer dimension view
DROP VIEW IF EXISTS gold.dim_customers;


-- Create customer dimension view
CREATE VIEW gold.dim_customers AS

SELECT

    -- Generate unique surrogate customer key
    ROW_NUMBER() OVER (
        ORDER BY ci.cst_id
    ) AS customer_key,

    -- Customer information
    ci.cst_id AS customer_id,

    ci.cst_key AS customer_number,

    ci.cst_firstname AS first_name,

    ci.cst_lastname AS last_name,

    -- Retrieve country from ERP location table
    la.cntry AS country,

    -- Retrieve marital status from CRM
    ci.cst_marital_status AS marital_status,

    -- CRM is the primary source for gender
    -- ERP is used as a fallback
    CASE
        WHEN ci.cst_gndr != 'n/a'
            THEN ci.cst_gndr

        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    -- Retrieve birthdate from ERP customer table
    ca.bdate AS birthdate,

    -- Customer creation date
    ci.cst_create_date AS create_date

FROM silver.crm_cust_info AS ci

-- Join ERP customer information
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid

-- Join ERP location information
LEFT JOIN silver.erp_loc_a101 AS la
    ON ci.cst_key = la.cid;


/*
===============================================================================
2. CREATE DIMENSION: gold.dim_products
===============================================================================

PURPOSE:

    Create a product dimension by combining CRM product information
    with ERP product category information.

TRANSFORMATIONS:

    1. Generate a surrogate product key.
    2. Retrieve product ID and product number.
    3. Retrieve product name.
    4. Retrieve category and subcategory.
    5. Retrieve maintenance information.
    6. Retrieve product cost and product line.
    7. Include only current products.
    8. Exclude historical product records.

===============================================================================
*/


-- Drop existing product dimension view
DROP VIEW IF EXISTS gold.dim_products;


-- Create product dimension view
CREATE VIEW gold.dim_products AS

SELECT

    -- Generate unique surrogate product key
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    ) AS product_key,

    -- Product information
    pn.prd_id AS product_id,

    pn.prd_key AS product_number,

    pn.prd_nm AS product_name,

    -- Product category information
    pn.cat_id AS category_id,

    pc.cat AS category,

    pc.subcat AS subcategory,

    pc.maintenance AS maintenance,

    -- Product cost
    pn.prd_cost AS cost,

    -- Product line
    pn.prd_line AS product_line,

    -- Product start date
    pn.prd_start_dt AS start_date

FROM silver.crm_prd_info AS pn

-- Join ERP product category information
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id

-- Filter out historical product records
WHERE pn.prd_end_dt IS NULL;


/*
===============================================================================
3. CREATE FACT TABLE: gold.fact_sales
===============================================================================

PURPOSE:

    Create a sales fact view by combining sales transactions
    with customer and product dimensions.

TRANSFORMATIONS:

    1. Retrieve order number.
    2. Retrieve product surrogate key.
    3. Retrieve customer surrogate key.
    4. Retrieve order, shipping, and due dates.
    5. Retrieve sales amount.
    6. Retrieve quantity and price.

JOINS:

    CRM Sales Details
        |
        |-- LEFT JOIN --> gold.dim_products
        |
        |-- LEFT JOIN --> gold.dim_customers

===============================================================================
*/


-- Drop existing sales fact view
DROP VIEW IF EXISTS gold.fact_sales;


-- Create sales fact view
CREATE VIEW gold.fact_sales AS

SELECT

    -- Sales transaction information
    sd.sls_ord_num AS order_number,

    -- Retrieve product surrogate key
    pr.product_key AS product_key,

    -- Retrieve customer surrogate key
    cu.customer_key AS customer_key,

    -- Sales date information
    sd.sls_order_dt AS order_date,

    sd.sls_ship_dt AS shipping_date,

    sd.sls_due_dt AS due_date,

    -- Sales measures
    sd.sls_sales AS sales_amount,

    sd.sls_quantity AS quantity,

    sd.sls_price AS price

FROM silver.crm_sales_details AS sd

-- Join product dimension using product number
LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_number

-- Join customer dimension using customer ID
LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id;


/*
===============================================================================
GOLD LAYER VIEW CREATION COMPLETED
===============================================================================

VIEWS CREATED:

    1. gold.dim_customers
    2. gold.dim_products
    3. gold.fact_sales

The Gold layer is now ready for analytical queries and reporting.

===============================================================================
*/

SELECT 'Gold Layer Views Created Successfully' AS status;

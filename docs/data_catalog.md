# Data Catalog for Gold Layer

## Overview

The Gold Layer represents the business-level data in the Data Warehouse. It is designed to support analytical queries, reporting, and business intelligence.

The Gold Layer follows a **Star Schema architecture**, consisting of dimension views and a fact view.

It contains three main views:

1. `gold.dim_customers` – Customer Dimension
2. `gold.dim_products` – Product Dimension
3. `gold.fact_sales` – Sales Fact

**Database:** MySQL Workbench
**Source Layer:** Silver Layer
**Architecture:** Star Schema
**Implementation:** SQL Views

---

## 1. gold.dim_customers

**Purpose:** Stores customer details enriched with demographic and geographic information by combining CRM and ERP data.

| Column Name     | MySQL Data Type | Description                                                                           |
| --------------- | --------------- | ------------------------------------------------------------------------------------- |
| customer_key    | BIGINT          | Surrogate key generated using ROW_NUMBER() to uniquely identify each customer record. |
| customer_id     | INT             | Unique numerical identifier assigned to each customer.                                |
| customer_number | VARCHAR(50)     | Alphanumeric identifier representing the customer, used for tracking and referencing. |
| first_name      | VARCHAR(50)     | Customer's first name, as recorded in the system.                                     |
| last_name       | VARCHAR(50)     | Customer's last name or family name.                                                  |
| country         | VARCHAR(50)     | Country of residence of the customer, such as Australia or Germany.                   |
| marital_status  | VARCHAR(50)     | Marital status of the customer, such as Married, Single, or n/a.                      |
| gender          | VARCHAR(50)     | Gender of the customer, such as Male, Female, or n/a.                                 |
| birthdate       | DATE            | Customer's date of birth, stored in YYYY-MM-DD format.                                |
| create_date     | DATE            | Date when the customer record was created in the system.                              |

### Source Tables

* `silver.crm_cust_info`
* `silver.erp_cust_az12`
* `silver.erp_loc_a101`

### Transformation Logic

* Generates customer surrogate keys using `ROW_NUMBER()`.
* Combines customer details from CRM and ERP.
* Retrieves country information from the ERP location table.
* Uses CRM gender as the primary source.
* Uses ERP gender as a fallback when CRM gender is unavailable.
* Retrieves customer birthdate from ERP.

---

## 2. gold.dim_products

**Purpose:** Provides detailed information about products, including product names, categories, subcategories, maintenance requirements, costs, and product lines.

| Column Name    | MySQL Data Type | Description                                                                          |
| -------------- | --------------- | ------------------------------------------------------------------------------------ |
| product_key    | BIGINT          | Surrogate key generated using ROW_NUMBER() to uniquely identify each product record. |
| product_id     | INT             | Unique identifier assigned to the product for internal tracking.                     |
| product_number | VARCHAR(50)     | Structured alphanumeric code representing the product.                               |
| product_name   | VARCHAR(50)     | Descriptive name of the product, including details such as type, color, and size.    |
| category_id    | VARCHAR(50)     | Unique identifier for the product category.                                          |
| category       | VARCHAR(50)     | Broader classification of the product, such as Bikes or Components.                  |
| subcategory    | VARCHAR(50)     | Detailed classification of the product within its category.                          |
| maintenance    | VARCHAR(50)     | Indicates the maintenance classification or requirement of the product.              |
| cost           | INT             | Cost or base price of the product, measured in monetary units.                       |
| product_line   | VARCHAR(50)     | Product line or series to which the product belongs, such as Road or Mountain.       |
| start_date     | DATE            | Date when the product became available for sale or use.                              |

### Source Tables

* `silver.crm_prd_info`
* `silver.erp_px_cat_g1v2`

### Transformation Logic

* Generates product surrogate keys using `ROW_NUMBER()`.
* Extracts product and category information from CRM.
* Retrieves category, subcategory, and maintenance information from ERP.
* Combines product and category information using LEFT JOIN.
* Filters out historical product records using `prd_end_dt IS NULL`.

---

## 3. gold.fact_sales

**Purpose:** Stores transactional sales information for analytical purposes. It combines sales transactions with customer and product dimension information.

| Column Name   | MySQL Data Type | Description                                                                  |
| ------------- | --------------- | ---------------------------------------------------------------------------- |
| order_number  | VARCHAR(50)     | Unique alphanumeric identifier for each sales order, such as SO54496.        |
| product_key   | BIGINT          | Surrogate key linking the sales transaction to the product dimension.        |
| customer_key  | BIGINT          | Surrogate key linking the sales transaction to the customer dimension.       |
| order_date    | DATE            | Date when the customer placed the order.                                     |
| shipping_date | DATE            | Date when the product was shipped to the customer.                           |
| due_date      | DATE            | Date when the order payment was due.                                         |
| sales_amount  | INT             | Total monetary value of the sale for the line item, in whole currency units. |
| quantity      | INT             | Number of product units ordered for the sales line item.                     |
| price         | INT             | Price per unit of the product, in whole currency units.                      |

### Source Tables

* `silver.crm_sales_details`
* `gold.dim_products`
* `gold.dim_customers`

### Transformation Logic

* Retrieves transactional sales information from CRM.
* Connects sales records with the product dimension using product number.
* Connects sales records with the customer dimension using customer ID.
* Retrieves customer and product surrogate keys.
* Preserves order dates, shipping dates, due dates, sales amounts, quantities, and prices.
* Uses LEFT JOIN to retain sales records even when matching dimension information is unavailable.

---

## 4. Gold Layer Summary

| View Name          | View Type      | Purpose                                                 |
| ------------------ | -------------- | ------------------------------------------------------- |
| gold.dim_customers | Dimension View | Stores customer demographic and geographic information. |
| gold.dim_products  | Dimension View | Stores product details and category information.        |
| gold.fact_sales    | Fact View      | Stores sales transactions and measures.                 |

## 5. Star Schema Relationships

The Gold Layer follows a Star Schema structure.

**Fact Table:** `gold.fact_sales`

**Dimension Views:**

* `gold.dim_customers`
* `gold.dim_products`

### Relationships

| Fact Table Column       | Dimension View Column      | Relationship       |
| ----------------------- | -------------------------- | ------------------ |
| fact_sales.customer_key | dim_customers.customer_key | Customer Dimension |
| fact_sales.product_key  | dim_products.product_key   | Product Dimension  |

### Star Schema Diagram

```text
                  gold.dim_customers
                         |
                         |
                    customer_key
                         |
                         |
                  gold.fact_sales
                         |
                         |
                     product_key
                         |
                         |
                   gold.dim_products
```

## 6. MySQL Data Type Reference

| SQL Server Data Type | MySQL Workbench Data Type |
| -------------------- | ------------------------- |
| INT                  | INT                       |
| BIGINT               | BIGINT                    |
| NVARCHAR(50)         | VARCHAR(50)               |
| VARCHAR(50)          | VARCHAR(50)               |
| DATE                 | DATE                      |
| DATETIME             | DATETIME                  |
| DECIMAL(p,s)         | DECIMAL(p,s)              |

**Note:** MySQL uses `VARCHAR` for variable-length character data. It does not require the SQL Server `NVARCHAR` type.

**Important:** The dimension and fact objects in this project are views, not physically stored tables. The data types listed above describe the intended output types. Actual view-column types are determined by the underlying Silver columns and expressions. Surrogate keys generated by `ROW_NUMBER()` are represented as BIGINT in MySQL.

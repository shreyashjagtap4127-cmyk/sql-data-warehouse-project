# Naming Conventions

## Overview

This document defines the naming conventions used for databases, tables, views, columns, stored procedures, and other objects in the MySQL Data Warehouse project.

Consistent naming conventions improve readability, maintainability, and understanding of the database structure.

## Table of Contents

1. General Principles
2. Database and Table Naming Conventions

   * Bronze Layer Rules
   * Silver Layer Rules
   * Gold Layer Rules
3. Column Naming Conventions

   * Surrogate Keys
   * Technical Columns
4. Stored Procedure Naming Conventions
5. View Naming Conventions

---

## 1. General Principles

The following naming principles are followed throughout the Data Warehouse project.

* **Naming Style:** Use `snake_case`, with lowercase letters and underscores (`_`) to separate words.
* **Language:** Use English for all database object names.
* **Avoid Reserved Words:** Do not use MySQL reserved keywords as database, table, column, or view names.
* **Meaningful Names:** Use descriptive names that clearly indicate the purpose of each database object.
* **Consistency:** Follow the same naming structure across all three Data Warehouse layers.
* **MySQL Compatibility:** Use MySQL-supported identifiers and data types.

---

## 2. Database and Table Naming Conventions

The Data Warehouse uses three separate MySQL databases to represent the Bronze, Silver, and Gold layers.

### Bronze Layer Rules

* The Bronze layer stores raw data imported from external source systems.
* Table names must begin with the source system name.
* Original source table names should be preserved wherever possible.

**Naming Pattern:**

`<sourcesystem>_<entity>`

Where:

* `<sourcesystem>`: Source system name, such as `crm` or `erp`.
* `<entity>`: Original entity or table name from the source system.

**Examples:**

| Table Name          | Description                                 |
| ------------------- | ------------------------------------------- |
| `crm_cust_info`     | Raw customer information from CRM.          |
| `crm_prd_info`      | Raw product information from CRM.           |
| `crm_sales_details` | Raw sales information from CRM.             |
| `erp_cust_az12`     | Raw customer information from ERP.          |
| `erp_loc_a101`      | Raw customer location information from ERP. |
| `erp_px_cat_g1v2`   | Raw product category information from ERP.  |

### Silver Layer Rules

* The Silver layer stores cleaned, standardized, and transformed data.
* Table names follow the same source system naming pattern as the Bronze layer.
* Original entity names are retained to maintain traceability between Bronze and Silver.

**Naming Pattern:**

`<sourcesystem>_<entity>`

**Examples:**

| Table Name          | Description                               |
| ------------------- | ----------------------------------------- |
| `crm_cust_info`     | Cleaned customer information.             |
| `crm_prd_info`      | Cleaned product information.              |
| `crm_sales_details` | Cleaned sales information.                |
| `erp_cust_az12`     | Standardized ERP customer information.    |
| `erp_loc_a101`      | Standardized ERP location information.    |
| `erp_px_cat_g1v2`   | Cleaned ERP product category information. |

### Gold Layer Rules

* The Gold layer contains business-ready analytical views.
* Object names must be meaningful and business-oriented.
* Names must begin with a category prefix that identifies the object's purpose.

**Naming Pattern:**

`<category>_<entity>`

Where:

* `<category>`: Describes the object type, such as `dim` or `fact`.
* `<entity>`: Descriptive business entity, such as `customers`, `products`, or `sales`.

**Examples:**

| View Name       | Description                                           |
| --------------- | ----------------------------------------------------- |
| `dim_customers` | Customer dimension view.                              |
| `dim_products`  | Product dimension view.                               |
| `fact_sales`    | Sales fact view containing transactional information. |

### Glossary of Category Patterns

| Pattern   | Meaning                   | Example                                    |
| --------- | ------------------------- | ------------------------------------------ |
| `dim_`    | Dimension view            | `dim_customers`, `dim_products`            |
| `fact_`   | Fact view                 | `fact_sales`                               |
| `report_` | Analytical reporting view | `report_customers`, `report_sales_monthly` |

---

## 3. Column Naming Conventions

Column names must clearly describe the information they store.

* Use lowercase letters.
* Separate multiple words using underscores.
* Use meaningful and descriptive column names.
* Avoid spaces and special characters in column names.

### Surrogate Keys

* All surrogate keys in dimension views must use the suffix `_key`.
* Surrogate keys are generated using `ROW_NUMBER()` in this project.

**Naming Pattern:**

`<entity>_key`

**Examples:**

| Column Name    | Description                       |
| -------------- | --------------------------------- |
| `customer_key` | Surrogate key in `dim_customers`. |
| `product_key`  | Surrogate key in `dim_products`.  |

### Technical Columns

* All technical columns must begin with the prefix `dwh_`.
* These columns store system-generated metadata related to data loading and processing.

**Naming Pattern:**

`dwh_<column_name>`

**Examples:**

| Column Name       | Description                                                   |
| ----------------- | ------------------------------------------------------------- |
| `dwh_create_date` | Date and time when a record is created in the Data Warehouse. |
| `dwh_load_date`   | Date and time when data is loaded into the Data Warehouse.    |
| `dwh_update_date` | Date and time when a record is updated.                       |

**MySQL Data Types:**

* `DATE` – Stores date values.
* `DATETIME` – Stores date and time values.
* `TIMESTAMP` – Stores timestamp values with MySQL timestamp behavior.

---

## 4. Stored Procedure Naming Conventions

All stored procedures used for data loading must follow a consistent naming pattern.

**Naming Pattern:**

`load_<layer>`

Where:

* `<layer>`: Represents the Data Warehouse layer being loaded.

**Examples:**

| Stored Procedure | Description                                                            |
| ---------------- | ---------------------------------------------------------------------- |
| `load_bronze`    | Loads raw data into the Bronze layer.                                  |
| `load_silver`    | Loads cleaned and transformed data into the Silver layer.              |
| `load_gold`      | Loads data into the Gold layer, if a loading procedure is implemented. |

**MySQL Syntax Example:**

```sql
CREATE PROCEDURE silver.load_silver()
BEGIN
    -- ETL operations for loading Silver layer
END;
```

**Execution:**

```sql
CALL silver.load_silver();
```

---

## 5. View Naming Conventions

All analytical views must follow the Gold layer naming pattern.

**Naming Pattern:**

`<category>_<entity>`

Rules:

* Use `dim_` for dimension views.
* Use `fact_` for fact views.
* Use `report_` for reporting views.
* Use meaningful business-oriented entity names.
* Use lowercase letters and underscores.

**Examples:**

| View Name       | View Type | Description                    |
| --------------- | --------- | ------------------------------ |
| `dim_customers` | Dimension | Customer information.          |
| `dim_products`  | Dimension | Product information.           |
| `fact_sales`    | Fact      | Sales transaction information. |

**MySQL Syntax Example:**

```sql
CREATE VIEW gold.dim_customers AS
SELECT
    customer_key,
    customer_id,
    first_name,
    last_name
FROM ...;
```

---

## 6. MySQL Database Naming Structure

In this project, Bronze, Silver, and Gold are implemented as separate MySQL databases rather than schemas within one database.

**Database Structure:**

```text
MySQL Server
│
├── bronze
│   ├── crm_cust_info
│   ├── crm_prd_info
│   ├── crm_sales_details
│   ├── erp_cust_az12
│   ├── erp_loc_a101
│   └── erp_px_cat_g1v2
│
├── silver
│   ├── crm_cust_info
│   ├── crm_prd_info
│   ├── crm_sales_details
│   ├── erp_cust_az12
│   ├── erp_loc_a101
│   ├── erp_px_cat_g1v2
│   └── load_silver
│
└── gold
    ├── dim_customers
    ├── dim_products
    └── fact_sales
```

---

## 7. SQL Server vs MySQL Terminology

| SQL Server                | MySQL Workbench                             |
| ------------------------- | ------------------------------------------- |
| Schema                    | Database (in this project)                  |
| NVARCHAR                  | VARCHAR                                     |
| GETDATE()                 | NOW()                                       |
| EXEC                      | CALL                                        |
| GO                        | Not required                                |
| CREATE OR ALTER PROCEDURE | DROP PROCEDURE IF EXISTS + CREATE PROCEDURE |
| CREATE VIEW               | CREATE VIEW                                 |
| DROP VIEW                 | DROP VIEW IF EXISTS                         |

---

## Conclusion

Following consistent naming conventions across the Bronze, Silver, and Gold layers improves the readability, organization, and maintainability of the MySQL Data Warehouse.

These conventions also make it easier to identify database objects, understand data transformations, maintain relationships, and develop analytical queries.

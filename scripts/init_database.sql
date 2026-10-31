/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouse'.
    If the database already exists, it is dropped and recreated.

    Additionally, it creates three databases:
    'bronze', 'silver', and 'gold'.

WARNING:
    Running this script will permanently delete existing
    DataWarehouse, bronze, silver, and gold databases.
=============================================================
*/

-- Drop and recreate the DataWarehouse database
DROP DATABASE IF EXISTS DataWarehouse;

-- Create the DataWarehouse database
CREATE DATABASE DataWarehouse;

-- Use DataWarehouse database
USE DataWarehouse;

-- Create Bronze database
CREATE SCHEMA bronze;

-- Create Silver database
CREATE SCHEMA silver;

-- Create Gold database
CREATE SCHEMA gold;

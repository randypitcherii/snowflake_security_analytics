//===========================================================
// Create service account, warehouse, and role structure
// for a Excel BI connection
//===========================================================
// create a BI service account user
USE ROLE SECURITYADMIN;
CREATE USER IF NOT EXISTS
  EXCEL_SNOWALERT_SERVICE_ACCOUNT
  PASSWORD = 'my cool password here' // use your own password, dummy 
  MUST_CHANGE_PASSWORD = FALSE;

// create roles
USE ROLE SECURITYADMIN;
CREATE ROLE IF NOT EXISTS EXCEL_ADMIN_ROLE;
CREATE ROLE IF NOT EXISTS EXCEL_SNOWALERT_USER_ROLE;
GRANT ROLE EXCEL_ADMIN_ROLE          TO ROLE SYSADMIN;
GRANT ROLE EXCEL_SNOWALERT_USER_ROLE TO ROLE SYSADMIN;
GRANT ROLE EXCEL_SNOWALERT_USER_ROLE TO ROLE EXCEL_ADMIN_ROLE;
GRANT ROLE EXCEL_SNOWALERT_USER_ROLE TO USER EXCEL_SNOWALERT_SERVICE_ACCOUNT;

// create warehouse
USE ROLE SYSADMIN;
CREATE WAREHOUSE IF NOT EXISTS
  EXCEL_SNOWALERT_WH
  COMMENT='Warehouse for snowalert dashboard development in Excel'
  WAREHOUSE_SIZE=XSMALL
  AUTO_SUSPEND=60
  INITIALLY_SUSPENDED=TRUE;
GRANT OWNERSHIP ON WAREHOUSE EXCEL_SNOWALERT_WH TO ROLE EXCEL_ADMIN_ROLE;

// permission the role
USE ROLE SECURITYADMIN;
GRANT USAGE ON WAREHOUSE EXCEL_SNOWALERT_WH TO ROLE EXCEL_SNOWALERT_USER_ROLE;
GRANT ROLE SNOWALERT_BI_READ_ROLE           TO ROLE EXCEL_SNOWALERT_USER_ROLE;

// set service account default values
ALTER USER 
  EXCEL_SNOWALERT_SERVICE_ACCOUNT
SET
  DEFAULT_WAREHOUSE = EXCEL_SNOWALERT_WH
  DEFAULT_ROLE = EXCEL_SNOWALERT_USER_ROLE;
//===========================================================
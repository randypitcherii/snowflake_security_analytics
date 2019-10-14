//===========================================================
// Create read roles for the acount_usage schema in the
// snowflake shared db
//===========================================================
// create roles
USE ROLE SECURITYADMIN;
CREATE ROLE ACCOUNT_USAGE_READ_ROLE;
GRANT ROLE ACCOUNT_USAGE_READ_ROLE TO ROLE SYSADMIN; // always do this

// grant the read role to other roles
USE ROLE SECURITYADMIN;
GRANT ROLE ACCOUNT_USAGE_READ_ROLE TO ROLE SNOWALERT;

// permission the read role
USE ROLE ACCOUNTADMIN; // only accountadmin has access to these views by default
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE ACCOUNT_USAGE_READ_ROLE;
//===========================================================
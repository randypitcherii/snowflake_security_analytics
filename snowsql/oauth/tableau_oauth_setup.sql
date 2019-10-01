//===========================================================
// Enable Tableau OAUTH integration
//===========================================================
USE ROLE ACCOUNTADMIN;
CREATE SECURITY INTEGRATION TABLEAU_DESKTOP_OAUTH_INTEGRATION
  TYPE = OAUTH
  OAUTH_CLIENT = TABLEAU_DESKTOP
  ENABLED = TRUE
  BLOCKED_ROLES_LIST = ('SYSADMIN', 'ACCOUNTADMIN', 'SECURITYADMIN'); // Do not allow admin access, ya jabroni
//===========================================================
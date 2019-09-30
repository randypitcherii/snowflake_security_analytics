//===========================================================
// Create BI views of snowalert data
//===========================================================
USE ROLE SNOWALERT;
USE WAREHOUSE SNOWALERT;

CREATE SCHEMA IF NOT EXISTS SNOWALERT.BI;

// Create current users view
CREATE OR REPLACE VIEW
  SNOWALERT.BI.CURRENT_IAM_USERS
AS (
  SELECT
    *
  FROM
    SNOWALERT.AWS.IAM_USER_MONITORING_LANDING_ZONE
  WHERE
    MONITORED_TIME = (
      SELECT 
        MAX(MONITORED_TIME) 
      FROM 
        SNOWALERT.AWS.IAM_USER_MONITORING_LANDING_ZONE
    )
);

// Create current human users view
CREATE OR REPLACE VIEW
  SNOWALERT.BI.CURRENT_IAM_HUMAN_USERS
AS (
  SELECT
    *
  FROM
    SNOWALERT.BI.CURRENT_IAM_USERS
  WHERE
    USER_NAME NOT IN (
        'Jenkins',
        'TravisUploader'
    )
);

// Create current security group view
CREATE OR REPLACE VIEW
  SNOWALERT.BI.CURRENT_SECURITY_GROUPS
AS (
  SELECT
    *
  FROM
    SNOWALERT.AWS.SECURITY_GROUP_MONITORING_LANDING_ZONE
  WHERE
    MONITORED_TIME = (
      SELECT 
        MAX(MONITORED_TIME) 
      FROM 
        SNOWALERT.AWS.SECURITY_GROUP_MONITORING_LANDING_ZONE
    )
);
//===========================================================
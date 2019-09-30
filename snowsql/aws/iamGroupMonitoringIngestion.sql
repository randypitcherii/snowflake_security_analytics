//===========================================================
// Create iam group monitoring objects
//===========================================================
// set context
USE ROLE SNOWALERT;
USE WAREHOUSE SNOWALERT;

// CREATE TABLE
CREATE TABLE IF NOT EXISTS
  SNOWALERT.AWS.IAM_GROUP_MONITORING_LANDING_ZONE (
    RAW_DATA        VARIANT,
    MONITORED_TIME  TIMESTAMP_TZ,  
    ARN             STRING,
    CREATE_DATE     TIMESTAMP_TZ,
    GROUP_ID        STRING,
    GROUP_NAME      STRING,
    PATH            STRING,
    ACCOUNT_ID      STRING(12)
  );

// create pipe
CREATE OR REPLACE PIPE
  SNOWALERT.AWS.IAM_GROUP_MONITORING_PIPE
  AUTO_INGEST=TRUE
AS 
  COPY INTO 
    SNOWALERT.AWS.IAM_GROUP_MONITORING_LANDING_ZONE 
  FROM (
    SELECT 
      $1                                      AS RAW_DATA, 
      TO_TIMESTAMP_TZ(
        REGEXP_SUBSTR(
          METADATA$FILENAME, '\/([^\/]*)\.json', 1, 1, 'e'
        ) || 'Z'
      )                                       AS MONITORED_TIME,
      $1:"Arn" :: STRING                      AS ARN,
      $1:"CreateDate" :: TIMESTAMP_TZ         AS CREATE_DATE,
      $1:"GroupId" :: STRING                  AS GROUP_ID,
      $1:"GroupName" :: STRING                AS GROUP_NAME,
      $1:"Path" :: STRING                     AS PATH,
      $1:"AccountId" :: STRING(12)            AS ACCOUNT_ID
    FROM 
      @SNOWALERT.AWS.SNOWWATCH_S3_STAGE/iam_monitoring/groups/
  );
  
    
// Copy any data that may already exist
COPY INTO 
  SNOWALERT.AWS.IAM_GROUP_MONITORING_LANDING_ZONE 
FROM (
  SELECT 
    $1                                      AS RAW_DATA, 
    TO_TIMESTAMP_TZ(
      REGEXP_SUBSTR(
        METADATA$FILENAME, '\/([^\/]*)\.json', 1, 1, 'e'
      ) || 'Z'
    )                                       AS MONITORED_TIME,
    $1:"Arn" :: STRING                      AS ARN,
    $1:"CreateDate" :: TIMESTAMP_TZ         AS CREATE_DATE,
    $1:"GroupId" :: STRING                  AS GROUP_ID,
    $1:"GroupName" :: STRING                AS GROUP_NAME,
    $1:"Path" :: STRING                     AS PATH,
    $1:"AccountId" :: STRING(12)            AS ACCOUNT_ID
  FROM 
    @SNOWALERT.AWS.SNOWWATCH_S3_STAGE/iam_monitoring/groups/
);

// NOTE: do not forget to add the sqs arn to your s3 bucket for auto_ingest support
SELECT SYSTEM$PIPE_STATUS('SNOWALERT.AWS.IAM_GROUP_MONITORING_PIPE');
//===========================================================

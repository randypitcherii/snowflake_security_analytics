//===========================================================
// Create iam policy monitoring objects
//===========================================================
// set context
USE ROLE SNOWALERT;
USE WAREHOUSE SNOWALERT;

// CREATE TABLE
CREATE TABLE IF NOT EXISTS
  SNOWALERT.AWS.IAM_POLICY_MONITORING_LANDING_ZONE (
    RAW_DATA                          VARIANT,
    MONITORED_TIME                    TIMESTAMP_TZ, 
    ARN                               STRING,
    ATTACHMENT_COUNT                  INT,
    CREATE_DATE                       TIMESTAMP_TZ,
    DEFAULT_VERSION_ID                STRING,
    IS_ATTACHABLE                     BOOLEAN,
    PATH                              STRING,
    PERMISSIONS_BOUNDARY_USAGE_COUNT  INT,
    POLICY_ID                         STRING,
    POLICY_NAME                       STRING,
    UPDATE_DATE                       TIMESTAMP_TZ,
    ACCOUNT_ID                        STRING(12)
  );

// create pipe
CREATE OR REPLACE PIPE
  SNOWALERT.AWS.IAM_POLICY_MONITORING_PIPE
  AUTO_INGEST=TRUE
AS 
  COPY INTO 
    SNOWALERT.AWS.IAM_POLICY_MONITORING_LANDING_ZONE 
  FROM (
    SELECT 
      $1                                          AS RAW_DATA, 
      TO_TIMESTAMP_TZ(
        REGEXP_SUBSTR(
          METADATA$FILENAME, '\/([^\/]*)\.json', 1, 1, 'e'
        ) || 'Z'
      )                                           AS MONITORED_TIME,
      $1:"Arn" :: STRING                          AS ARN,
      $1:"AttachmentCount" :: INT                 AS ATTACHMENT_COUNT,
      $1:"CreateDate" :: TIMESTAMP_TZ             AS CREATE_DATE,
      $1:"DefaultVersionId" :: STRING             AS DEFAULT_VERSION_ID,
      $1:"IsAttachable" :: BOOLEAN                AS IS_ATTACHABLE,
      $1:"Path" :: STRING                         AS PATH,
      $1:"PermissionsBoundaryUsageCount" :: INT   AS PERMISSIONS_BOUNDARY_USAGE_COUNT,
      $1:"PolicyId" :: STRING                     AS POLICY_ID,
      $1:"PolicyName" :: STRING                   AS POLICY_NAME,
      $1:"UpdateDate" :: TIMESTAMP_TZ             AS UPDATE_DATE,
      $1:"AccountId" :: STRING(12)                AS ACCOUNT_ID
    FROM 
      @SNOWALERT.AWS.SNOWWATCH_S3_STAGE/iam_monitoring/policies/
  );
  
    
// Copy any data that may already exist
COPY INTO 
  SNOWALERT.AWS.IAM_POLICY_MONITORING_LANDING_ZONE 
FROM (
  SELECT 
    $1                                          AS RAW_DATA, 
    TO_TIMESTAMP_TZ(
      REGEXP_SUBSTR(
        METADATA$FILENAME, '\/([^\/]*)\.json', 1, 1, 'e'
      ) || 'Z'
    )                                           AS MONITORED_TIME,
    $1:"Arn" :: STRING                          AS ARN,
    $1:"AttachmentCount" :: INT                 AS ATTACHMENT_COUNT,
    $1:"CreateDate" :: TIMESTAMP_TZ             AS CREATE_DATE,
    $1:"DefaultVersionId" :: STRING             AS DEFAULT_VERSION_ID,
    $1:"IsAttachable" :: BOOLEAN                AS IS_ATTACHABLE,
    $1:"Path" :: STRING                         AS PATH,
    $1:"PermissionsBoundaryUsageCount" :: INT   AS PERMISSIONS_BOUNDARY_USAGE_COUNT,
    $1:"PolicyId" :: STRING                     AS POLICY_ID,
    $1:"PolicyName" :: STRING                   AS POLICY_NAME,
    $1:"UpdateDate" :: TIMESTAMP_TZ             AS UPDATE_DATE,
    $1:"AccountId" :: STRING(12)                AS ACCOUNT_ID
  FROM 
    @SNOWALERT.AWS.SNOWWATCH_S3_STAGE/iam_monitoring/policies/
);

// NOTE: do not forget to add the sqs arn to your s3 bucket for auto_ingest support
SELECT SYSTEM$PIPE_STATUS('SNOWALERT.AWS.IAM_POLICY_MONITORING_PIPE');
//===========================================================

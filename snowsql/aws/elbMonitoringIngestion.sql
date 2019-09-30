//===========================================================
// Create elb monitoring objects
//===========================================================
// set context
USE ROLE SNOWALERT;
USE WAREHOUSE SNOWALERT;

// CREATE TABLE
CREATE TABLE IF NOT EXISTS
  SNOWALERT.AWS.ELB_MONITORING_LANDING_ZONE (
    RAW_DATA              VARIANT,
    MONITORED_TIME        TIMESTAMP_TZ,
    HOSTED_ZONE_NAME      STRING,
    HOSTED_ZONE_NAME_ID   STRING,
    CREATED_TIME          TIMESTAMP_TZ,
    DNS_NAME              STRING,
    LOAD_BALANCER_NAME    STRING,
    REGION_NAME           STRING(16),
    SCHEME                STRING,
    VPC_ID                STRING,
    ACCOUNT_ID            STRING(12)
  );

// create pipe
CREATE OR REPLACE PIPE
  SNOWALERT.AWS.ELB_MONITORING_PIPE
  AUTO_INGEST=TRUE
AS 
  COPY INTO 
    SNOWALERT.AWS.ELB_MONITORING_LANDING_ZONE 
  FROM (
    SELECT 
      $1                                        AS RAW_DATA, 
      TO_TIMESTAMP_TZ(
        REGEXP_SUBSTR(
          METADATA$FILENAME, '\/([^\/]*)\.json', 1, 1, 'e'
        ) || 'Z'
      )                                         AS MONITORED_TIME,
      $1:"CanonicalHostedZoneName" :: STRING    AS HOSTED_ZONE_NAME,
      $1:"CanonicalHostedZoneNameID" :: STRING  AS HOSTED_ZONE_NAME_ID,
      TO_TIMESTAMP_TZ($1:"CreatedTime")         AS CREATED_TIME,
      $1:"DNSName" :: STRING                    AS DNS_NAME,
      $1:"LoadBalancerName" :: STRING           AS LOAD_BALANCER_NAME,
      $1:"Region"."RegionName" :: STRING(16)    AS REGION_NAME,
      $1:"Scheme" :: STRING                     AS SCHEME,
      $1:"VPCId" :: STRING                      AS VPC_ID,
      $1:"AccountId" :: STRING(12)              AS ACCOUNT_ID
    FROM 
      @SNOWALERT.AWS.SNOWWATCH_S3_STAGE/elb_monitoring/
  );
  
    
// Copy any data that may already exist
COPY INTO 
  SNOWALERT.AWS.ELB_MONITORING_LANDING_ZONE 
FROM (
  SELECT 
    $1                                        AS RAW_DATA, 
    TO_TIMESTAMP_TZ(
      REGEXP_SUBSTR(
        METADATA$FILENAME, '\/([^\/]*)\.json', 1, 1, 'e'
      ) || 'Z'
    )                                         AS MONITORED_TIME,
    $1:"CanonicalHostedZoneName" :: STRING    AS HOSTED_ZONE_NAME,
    $1:"CanonicalHostedZoneNameID" :: STRING  AS HOSTED_ZONE_NAME_ID,
    TO_TIMESTAMP_TZ($1:"CreatedTime")         AS CREATED_TIME,
    $1:"DNSName" :: STRING                    AS DNS_NAME,
    $1:"LoadBalancerName" :: STRING           AS LOAD_BALANCER_NAME,
    $1:"Region"."RegionName" :: STRING(16)    AS REGION_NAME,
    $1:"Scheme" :: STRING                     AS SCHEME,
    $1:"VPCId" :: STRING                      AS VPC_ID,
    $1:"AccountId" :: STRING(12)              AS ACCOUNT_ID
  FROM 
    @SNOWALERT.AWS.SNOWWATCH_S3_STAGE/elb_monitoring/
);

// NOTE: do not forget to add the sqs arn to your s3 bucket for auto_ingest support
SELECT SYSTEM$PIPE_STATUS('SNOWALERT.AWS.ELB_MONITORING_PIPE');
//===========================================================

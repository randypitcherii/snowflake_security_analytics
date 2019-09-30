//===========================================================
// Create cloudtrail monitoring objects
//===========================================================
// set context
USE ROLE SNOWALERT;
USE WAREHOUSE SNOWALERT;

// CREATE TABLE
CREATE TABLE IF NOT EXISTS
  SNOWALERT.AWS.CLOUDTRAIL_LANDING_ZONE (
    RAW_DATA        VARIANT,
    INGESTION_TIME  TIMESTAMP_TZ
  );
  
// create pipe
CREATE OR REPLACE PIPE
  SNOWALERT.AWS.CLOUDTRAIL_PIPE
  AUTO_INGEST=TRUE
AS 
  COPY INTO 
    SNOWALERT.AWS.CLOUDTRAIL_LANDING_ZONE 
  FROM (
    SELECT 
      $1:"Records"          AS RAW_DATA, 
      CURRENT_TIMESTAMP()   AS INGESTION_TIME
    FROM 
      @SNOWALERT.AWS.CLOUDTRAIL_STAGE
  );

// NOTE: do not forget to add the sqs arn to your s3 bucket for auto_ingest support
SELECT SYSTEM$PIPE_STATUS('SNOWALERT.AWS.CLOUDTRAIL_PIPE');

// stream for cdc processing
CREATE STREAM IF NOT EXISTS
  SNOWALERT.AWS.CLOUDTRAIL_LANDING_ZONE_STREAM 
ON TABLE 
  SNOWALERT.AWS.CLOUDTRAIL_LANDING_ZONE;
//===========================================================


//===========================================================
// Flatten variants
//===========================================================
USE ROLE SNOWALERT;
USE WAREHOUSE SNOWALERT;

// create flattened table
CREATE TABLE IF NOT EXISTS
  SNOWALERT.AWS.CLOUDTRAIL_FLATTENED (
    INSERT_ID                                                   NUMBER IDENTITY START 1 INCREMENT 1,
    INSERT_TIME                                                 TIMESTAMP_LTZ(9),
    RAW                                                         VARIANT,
    HASH_RAW                                                    NUMBER,
    EVENT_TIME                                                  TIMESTAMP_LTZ(9),
    AWS_REGION                                                  STRING,
    EVENT_ID                                                    STRING,
    EVENT_NAME                                                  STRING,
    EVENT_SOURCE                                                STRING,
    EVENT_TYPE                                                  STRING,
    EVENT_VERSION                                               STRING,
    RECIPIENT_ACCOUNT_ID                                        STRING,
    REQUEST_ID                                                  STRING,
    REQUEST_PARAMETERS                                          VARIANT,
    RESPONSE_ELEMENTS                                           VARIANT,
    SOURCE_IP_ADDRESS                                           STRING,
    USER_AGENT                                                  STRING,
    USER_IDENTITY                                               VARIANT,
    USER_IDENTITY_TYPE                                          STRING,
    USER_IDENTITY_PRINCIPAL_ID                                  STRING,
    USER_IDENTITY_ARN                                           STRING,
    USER_IDENTITY_ACCOUNTID                                     STRING,
    USER_IDENTITY_INVOKEDBY                                     STRING,
    USER_IDENTITY_ACCESS_KEY_ID                                 STRING,
    USER_IDENTITY_USERNAME                                      STRING,
    USER_IDENTITY_SESSION_CONTEXT_ATTRIBUTES_MFA_AUTHENTICATED  BOOLEAN,
    USER_IDENTITY_SESSION_CONTEXT_ATTRIBUTES_CREATION_DATE      STRING,
    USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_TYPE           STRING,
    USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_PRINCIPAL_ID   STRING,
    USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_ARN            STRING,
    USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_ACCOUNT_ID     STRING,
    USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_USER_NAME      STRING,
    ERROR_CODE                                                  STRING,
    ERROR_MESSAGE                                               STRING,
    ADDITIONAL_EVENT_DATA                                       VARIANT,
    API_VERSION                                                 STRING,
    READ_ONLY                                                   BOOLEAN,
    RESOURCES                                                   VARIANT,
    SERVICE_EVENT_DETAILS                                       STRING,
    SHARED_EVENT_ID                                             STRING,
    VPC_ENDPOINT_ID                                             STRING
  );

// Task to regularly update flattened table
CREATE OR REPLACE TASK
  SNOWALERT.AWS.CLOUDTRAIL_FLATTENING_TASK
  WAREHOUSE=SNOWALERT
  SCHEDULE= '5 MINUTE'
WHEN
  SYSTEM$STREAM_HAS_DATA('SNOWALERT.AWS.CLOUDTRAIL_LANDING_ZONE_STREAM')
AS 
 INSERT INTO SNOWALERT.AWS.CLOUDTRAIL_FLATTENED (
    INSERT_TIME, RAW, HASH_RAW, EVENT_TIME, AWS_REGION, EVENT_ID, EVENT_NAME, EVENT_SOURCE, EVENT_TYPE,
    EVENT_VERSION, RECIPIENT_ACCOUNT_ID, REQUEST_ID, REQUEST_PARAMETERS, RESPONSE_ELEMENTS, SOURCE_IP_ADDRESS,
    USER_AGENT, USER_IDENTITY, USER_IDENTITY_TYPE, USER_IDENTITY_PRINCIPAL_ID, USER_IDENTITY_ARN,
    USER_IDENTITY_ACCOUNTID, USER_IDENTITY_INVOKEDBY, USER_IDENTITY_ACCESS_KEY_ID, USER_IDENTITY_USERNAME,
    USER_IDENTITY_SESSION_CONTEXT_ATTRIBUTES_MFA_AUTHENTICATED, USER_IDENTITY_SESSION_CONTEXT_ATTRIBUTES_CREATION_DATE,
    USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_TYPE, USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_PRINCIPAL_ID,
    USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_ARN, USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_ACCOUNT_ID,
    USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_USER_NAME, ERROR_CODE, ERROR_MESSAGE, ADDITIONAL_EVENT_DATA,
    API_VERSION, READ_ONLY, RESOURCES, SERVICE_EVENT_DETAILS, SHARED_EVENT_ID, VPC_ENDPOINT_ID
  )
  SELECT 
    CURRENT_TIMESTAMP()                                                             AS INSERT_TIME,
    VALUE                                                                           AS RAW,
    HASH(VALUE)                                                                     AS HASH_RAW,
    TRY_TO_TIMESTAMP(VALUE:"eventTime"::STRING)::TIMESTAMP_LTZ(9)                   AS EVENT_TIME,
    VALUE:"awsRegion"::STRING                                                       AS AWS_REGION,
    VALUE:"eventID"::STRING                                                         AS EVENT_ID,
    VALUE:"eventName"::STRING                                                       AS EVENT_NAME,
    VALUE:"eventSource"::STRING                                                     AS EVENT_SOURCE,
    VALUE:"eventType"::STRING                                                       AS EVENT_TYPE,
    VALUE:"eventVersion"::STRING                                                    AS EVENT_VERSION,
    VALUE:"recipientAccountId"::STRING                                              AS RECIPIENT_ACCOUNT_ID,
    VALUE:"requestID"::STRING                                                       AS REQUEST_ID,
    VALUE:"requestParameters"::VARIANT                                              AS REQUEST_PARAMETERS,
    VALUE:"responseElements"::VARIANT                                               AS RESPONSE_ELEMENTS,
    VALUE:"sourceIPAddress"::STRING                                                 AS SOURCE_IP_ADDRESS,
    VALUE:"userAgent"::STRING                                                       AS USER_AGENT,
    VALUE:"userIdentity"::VARIANT                                                   AS USER_IDENTITY,
    VALUE:"userIdentity"."type"::STRING                                             AS USER_IDENTITY_TYPE,
    VALUE:"userIdentity"."principalId"::STRING                                      AS USER_IDENTITY_PRINCIPAL_ID,
    VALUE:"userIdentity"."arn"::STRING                                              AS USER_IDENTITY_ARN,
    VALUE:"userIdentity"."accountId"::STRING                                        AS USER_IDENTITY_ACCOUNTID,
    VALUE:"userIdentity"."invokedBy"::STRING                                        AS USER_IDENTITY_INVOKEDBY,
    VALUE:"userIdentity"."accessKeyId"::STRING                                      AS USER_IDENTITY_ACCESS_KEY_ID,
    VALUE:"userIdentity"."userName"::STRING                                         AS USER_IDENTITY_USERNAME,
    VALUE:"userIdentity"."sessionContext"."attributes"."mfaAuthenticated"::STRING   AS USER_IDENTITY_SESSION_CONTEXT_ATTRIBUTES_MFA_AUTHENTICATED,
    VALUE:"userIdentity"."sessionContext"."attributes"."creationDate"::STRING       AS USER_IDENTITY_SESSION_CONTEXT_ATTRIBUTES_CREATION_DATE,
    VALUE:"userIdentity"."sessionContext"."sessionIssuer"."type"::STRING            AS USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_TYPE,
    VALUE:"userIdentity"."sessionContext"."sessionIssuer"."principalId"::STRING     AS USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_PRINCIPAL_ID,
    VALUE:"userIdentity"."sessionContext"."sessionIssuer"."arn"::STRING             AS USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_ARN,
    VALUE:"userIdentity"."sessionContext"."sessionIssuer"."accountId"::STRING       AS USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_ACCOUNT_ID,
    VALUE:"userIdentity"."sessionContext"."sessionIssuer"."userName"::STRING        AS USER_IDENTITY_SESSION_CONTEXT_SESSION_ISSUER_USER_NAME,
    VALUE:"errorCode"::STRING                                                       AS ERROR_CODE,
    VALUE:"errorMessage"::STRING                                                    AS ERROR_MESSAGE,
    VALUE:"additionalEventData"::VARIANT                                            AS ADDITIONAL_EVENT_DATA,
    VALUE:"apiVersion"::STRING                                                      AS API_VERSION,
    VALUE:"readOnly"::BOOLEAN                                                       AS READ_ONLY,
    VALUE:"resources"::VARIANT                                                      AS RESOURCES,
    VALUE:"serviceEventDetails"::STRING                                             AS SERVICE_EVENT_DETAILS,
    VALUE:"sharedEventId"::STRING                                                   AS SHARED_EVENT_ID,
    VALUE:"vpcEndpointId"::STRING                                                   AS VPC_ENDPOINT_ID
  FROM 
    SNOWALERT.AWS.CLOUDTRAIL_LANDING_ZONE_STREAM, TABLE(FLATTEN(INPUT => RAW_DATA))
  WHERE 
    ARRAY_SIZE(RAW_DATA) > 0;

// Start (or resume) the Task
ALTER TASK SNOWALERT.AWS.CLOUDTRAIL_FLATTENING_TASK RESUME;
    
// Copy data from the last week. Cloudtrail
// logging can get massive, so best to stick to just a week
// for now
ALTER PIPE SNOWALERT.AWS.CLOUDTRAIL_PIPE REFRESH;
//===========================================================
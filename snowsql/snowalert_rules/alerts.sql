//===========================================================
// Create snowalert alert rules
//===========================================================
USE ROLE SNOWALERT;
USE WAREHOUSE SNOWALERT;

// ec2 instance limit exceeded alert
CREATE OR REPLACE VIEW 
  SNOWALERT.RULES.EC2_INSTANCE_LIMIT_EXCEEDED_ALERT_QUERY 
  COPY GRANTS
  COMMENT='Alert when the ec2 instance limit is exceeded
  @id 0LXRWVPXORVQ'
AS SELECT 
  'AWS' AS ENVIRONMENT,
  ARRAY_CONSTRUCT('CLOUDTRAIL') AS SOURCES,
  'EC2' AS OBJECT,
  'EC2_INSTANCE_LIMIT_EXCEEDED' AS TITLE,
  EVENT_TIME AS EVENT_TIME,
  CURRENT_TIMESTAMP() AS ALERT_TIME,
  USER_IDENTITY_ARN || ' received ec2 Client.InstanceLimitExceeded error at ' || EVENT_TIME || ' in ' || ACCOUNT_NAME || ' ' || AWS_REGION AS DESCRIPTION,
  USER_IDENTITY_ARN AS ACTOR,
  EVENT_NAME AS ACTION,
  'SNOWALERT' AS DETECTOR,
  RAW AS EVENT_DATA,
  ARRAY_CONSTRUCT() AS HANDLERS,
  'HIGH' AS SEVERITY,
  '0LXRWVPXORVQ' AS QUERY_ID
FROM 
  SNOWALERT.AWS.CLOUDTRAIL_FLATTENED
WHERE
  ERROR_CODE='Client.InstanceLimitExceeded'
  AND
  EVENT_TIME > TIMEADD(HOUR, -2, CURRENT_TIMESTAMP()) // only check the last 2 hours to improve performance
;

// new user creation in AWS
CREATE OR REPLACE VIEW 
  SNOWALERT.RULES.NEW_AWS_USER_ALERT_QUERY 
  COPY GRANTS
  COMMENT='Alert when a new AWS user is created in main
  @id 1LXRWVPXORVQ'
AS SELECT 
  'AWS' AS ENVIRONMENT,
  ARRAY_CONSTRUCT('CLOUDTRAIL') AS SOURCES,
  RAW:"responseElements" AS OBJECT,
  'New AWS User Created' AS TITLE,
  EVENT_TIME AS EVENT_TIME,
  CURRENT_TIMESTAMP() AS ALERT_TIME,
  USER_IDENTITY_ARN || ' created new user ' || OBJECT:"user":"arn" || ' in ' || ACCOUNT_NAME || ' ' || AWS_REGION AS DESCRIPTION,
  USER_IDENTITY_ARN AS ACTOR,
  EVENT_NAME AS ACTION,
  'SNOWALERT' AS DETECTOR,
  RAW AS EVENT_DATA,
  ARRAY_CONSTRUCT() AS HANDLERS,
  'HIGH' AS SEVERITY,
  '1LXRWVPXORVQ' AS QUERY_ID
FROM 
  SNOWALERT.AWS.CLOUDTRAIL_FLATTENED
WHERE
  EVENT_SOURCE = 'iam.amazonaws.com'
  AND
  EVENT_NAME = 'CreateUser'
  AND
  ACCOUNT_NAME = 'MAIN'
  AND
  EVENT_TIME > TIMEADD(HOUR, -2, CURRENT_TIMESTAMP()) // only check the last 2 hours to improve performance
;

// new user creation in AWS
CREATE OR REPLACE VIEW 
  SNOWALERT.RULES.NEW_AWS_TRAINING_USER_ALERT_QUERY 
  COPY GRANTS
  COMMENT='Alert when a new AWS user is created in training
  @id 2LXRWVPXORVQ'
AS SELECT 
  'AWS' AS ENVIRONMENT,
  ARRAY_CONSTRUCT('CLOUDTRAIL') AS SOURCES,
  RAW:"responseElements" AS OBJECT,
  'New AWS User Created in Training' AS TITLE,
  EVENT_TIME AS EVENT_TIME,
  CURRENT_TIMESTAMP() AS ALERT_TIME,
  USER_IDENTITY_ARN || ' created new user ' || OBJECT:"user":"arn" || ' in ' || ACCOUNT_NAME || ' ' || AWS_REGION AS DESCRIPTION,
  USER_IDENTITY_ARN AS ACTOR,
  EVENT_NAME AS ACTION,
  'SNOWALERT' AS DETECTOR,
  RAW AS EVENT_DATA,
  ARRAY_CONSTRUCT() AS HANDLERS,
  'MEDIUM' AS SEVERITY,
  '2LXRWVPXORVQ' AS QUERY_ID
FROM 
  SNOWALERT.AWS.CLOUDTRAIL_FLATTENED
WHERE
  EVENT_SOURCE = 'iam.amazonaws.com'
  AND
  EVENT_NAME = 'CreateUser'
  AND
  ACCOUNT_NAME = 'TRAINING'
  AND
  EVENT_TIME > TIMEADD(HOUR, -2, CURRENT_TIMESTAMP()) // only check the last 2 hours to improve performance
;

// IAM access denied
CREATE OR REPLACE VIEW 
  SNOWALERT.RULES.AWS_IAM_ACCESS_DENIED_ALERT_QUERY 
  COPY GRANTS
  COMMENT='Alert when access is denied during an IAM operation
  @id 3LXRWVPXORVQ'
AS SELECT 
  'AWS' AS ENVIRONMENT,
  ARRAY_CONSTRUCT('CLOUDTRAIL') AS SOURCES,
  RAW:"responseElements" AS OBJECT,
  'IAM Access Denied' AS TITLE,
  EVENT_TIME AS EVENT_TIME,
  CURRENT_TIMESTAMP() AS ALERT_TIME,
  USER_IDENTITY_ARN || ' attempted ' || EVENT_NAME || ' in ' || ACCOUNT_NAME || ' ' || AWS_REGION AS DESCRIPTION,
  USER_IDENTITY_ARN AS ACTOR,
  EVENT_NAME AS ACTION,
  'SNOWALERT' AS DETECTOR,
  RAW AS EVENT_DATA,
  ARRAY_CONSTRUCT() AS HANDLERS,
  'MEDIUM' AS SEVERITY,
  '3LXRWVPXORVQ' AS QUERY_ID
FROM 
  SNOWALERT.AWS.CLOUDTRAIL_FLATTENED
WHERE
  EVENT_SOURCE = 'iam.amazonaws.com'
  AND
  ERROR_CODE = 'AccessDenied'
  AND
  EVENT_TIME > TIMEADD(HOUR, -2, CURRENT_TIMESTAMP()) // only check the last 2 hours to improve performance
;

// traffic in AWS from known bad IP
CREATE OR REPLACE VIEW 
  SNOWALERT.RULES.AWS_BAD_IP_ACTIVITY_ALERT_QUERY 
  COPY GRANTS
  COMMENT='Alert when AWS is accessed from a known bad IP
  @id 4LXRWVPXORVQ'
AS SELECT 
  'AWS' AS ENVIRONMENT,
  ARRAY_CONSTRUCT('CLOUDTRAIL') AS SOURCES,
  RAW:"requestParameters" AS OBJECT,
  'AWS Activity from Bad IP' AS TITLE,
  EVENT_TIME AS EVENT_TIME,
  CURRENT_TIMESTAMP() AS ALERT_TIME,
  USER_IDENTITY_ARN || ' attempted ' || EVENT_SOURCE || ' ' || EVENT_NAME || ' in ' || ACCOUNT_NAME || ' ' || AWS_REGION || ' with IP ' || SOURCE_IP_ADDRESS AS DESCRIPTION,
  USER_IDENTITY_ARN AS ACTOR,
  EVENT_NAME AS ACTION,
  'SNOWALERT' AS DETECTOR,
  RAW AS EVENT_DATA,
  ARRAY_CONSTRUCT() AS HANDLERS,
  'HIGH' AS SEVERITY,
  '4LXRWVPXORVQ' AS QUERY_ID
FROM 
  SNOWALERT.AWS.CLOUDTRAIL_FLATTENED
WHERE
  SOURCE_IP_ADDRESS in ('139.198.189.49', '64.134.160.54') // add more here. If this list is large, move to a separate table
  AND
  EVENT_TIME > TIMEADD(HOUR, -2, CURRENT_TIMESTAMP()) // only check the last 2 hours to improve performance
;

// Monitor account admin activity across all of snowflake
CREATE OR REPLACE VIEW 
  SNOWALERT.RULES.ACTIVITY_BY_ADMIN_ALERT_QUERY 
  COPY GRANTS
  COMMENT='Alerts on administrative activity in Snowflake
  @id 417ecdb2f0a7449bb5b49bea44fc6b0a
  @tags admin activity'
AS SELECT 
  'Activity by ACCOUNTADMIN Role'               AS TITLE,
  ARRAY_CONSTRUCT('SNOWALERT.BI.QUERY_HISTORY') AS SOURCES,
  'Snowflake'                                   AS ENVIRONMENT,
  WAREHOUSE_NAME                                AS OBJECT,
  START_TIME                                    AS EVENT_TIME,
  CURRENT_TIMESTAMP()                           AS ALERT_TIME,
  USER_NAME                                     AS ACTOR,
  QUERY_TEXT                                    AS ACTION,
  ACTOR || ' performed ' || QUERY_TEXT          AS DESCRIPTION,
  'SnowAlert'                                   AS DETECTOR,
  OBJECT_CONSTRUCT(*)                           AS EVENT_DATA,
  'MEDIUM'                                      AS SEVERITY,
  '417ecdb2f0a7449bb5b49bea44fc6b0a'            AS QUERY_ID
FROM 
  SNOWALERT.BI.QUERY_HISTORY
WHERE
  ROLE_NAME = 'ACCOUNTADMIN';


// suppression of admin activity by randy
CREATE OR REPLACE VIEW 
  SNOWALERT.RULES.SNOWFLAKE_ACCOUNTADMIN_ACTIVITY_EXCEPTIONS_ALERT_SUPPRESSION 
  COPY GRANTS
  COMMENT='Exceptions for valid snowflake account admin activity'
AS SELECT 
  ID
FROM 
  SNOWALERT.DATA.ALERTS
WHERE 
  QUERY_NAME = 'ACTIVITY_BY_ADMIN_ALERT_QUERY'
  AND 
  ACTOR IN ('RANDYPITCHER', 'SNOWALERT'); // change this to any user who can validly use accountadmin 
//===========================================================
//===========================================================
// Create snowalert alert views
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
  USER_IDENTITY_ARN || ' received ec2 Client.InstanceLimitExceeded error at ' || EVENT_TIME || ' in ' || AWS_REGION AS DESCRIPTION,
  USER_IDENTITY_ARN AS ACTOR,
  EVENT_NAME AS ACTION,
  'SNOWALERT' AS DETECTOR,
  RAW AS EVENT_DATA,
  ARRAY_CONSTRUCT() AS HANDLERS,
  'high' AS SEVERITY,
  '0LXRWVPXORVQ' AS QUERY_ID
FROM 
  SNOWALERT.AWS.CLOUDTRAIL_FLATTENED
WHERE
  ERROR_CODE='Client.InstanceLimitExceeded'
  AND
  EVENT_TIME > TIMEADD(HOUR, -4, CURRENT_TIMESTAMP()) // only check the last 4 hours to improve performance
;
//===========================================================
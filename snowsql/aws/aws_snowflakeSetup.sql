//===========================================================
// Create initial objects for AWS data sources
//===========================================================
// set role
USE ROLE SNOWALERT;

// create schema
CREATE SCHEMA IF NOT EXISTS SNOWALERT.AWS;

// create file formats
CREATE FILE FORMAT IF NOT EXISTS
  SNOWALERT.AWS.SNOWWATCH_JSON_ARRAY_FORMAT
  TYPE=JSON
  STRIP_OUTER_ARRAY=TRUE;
CREATE FILE FORMAT IF NOT EXISTS
  SNOWALERT.AWS.CLOUDTRAIL_JSON_FORMAT
  TYPE=JSON;

// create stages
CREATE STAGE IF NOT EXISTS
  SNOWALERT.AWS.SNOWWATCH_S3_STAGE
  URL= 's3://snowwatch-your_snowwatch_aws_account_here'
  CREDENTIALS=(
    AWS_ROLE='your_role_arn_here'
  )
  FILE_FORMAT=SNOWALERT.AWS.SNOWWATCH_JSON_ARRAY_FORMAT;
CREATE STAGE IF NOT EXISTS
  SNOWALERT.AWS.CLOUDTRAIL_STAGE
  URL= 's3://your_cloudtrail_bucket_here_with_path_to_logs'
  CREDENTIALS=(
    AWS_ROLE='your_role_arn_here'
  )
  FILE_FORMAT=SNOWALERT.AWS.CLOUDTRAIL_JSON_FORMAT;

// confirm stages works
DESC STAGE SNOWALERT.AWS.SNOWWATCH_S3_STAGE;
DESC STAGE SNOWALERT.AWS.CLOUDTRAIL_STAGE;
//===========================================================

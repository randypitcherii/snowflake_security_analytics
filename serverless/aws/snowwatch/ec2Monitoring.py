import datetime
import json
import logging
import os
from serializer import datetimeSerializer
from sessionManager import getSession, getAccountId, parseArnsString

logger = logging.getLogger()
logger.setLevel(logging.INFO)

S3_BUCKET_NAME = os.environ['S3_BUCKET_NAME']
S3_MONITORING_PATH = os.environ['S3_EC2_MONITORING_PATH']
READER_ROLE_ARNS = os.environ['READER_ROLE_ARNS']

def getInstanceName(instance=None):
    """
    This method searches an ec2 instance object
    for the Name tag and returns that value as a string.
    """
    # return the name if possible, return empty string if not possible
    try:
        for tag in instance["Tags"]:
            if "Name" == tag["Key"]:
                return tag["Value"]
    except Exception as e:
        logger.warning(f"could not extract instance name from [{instance}]")
    
    return ""

def getAllInstances(roleArn=None):
    """
    This method returns a list containing each
    ec2 instance from each region in the current AWS account.

    If a roleArn is provided, that role is assumed and instances
    are retreived from that role's AWS account
    """
    session = getSession(roleArn) # if None, the base boto3 session is used
    regions = session.client('ec2').describe_regions()['Regions']
    accountId = getAccountId(session)

    # get list of all instances in each region
    instances = []
    for region in regions:
        reservations = session.client('ec2', region_name=region['RegionName']).describe_instances()["Reservations"]
        for reservation in reservations:
            for instance in reservation['Instances']:
                instance["Region"] = region
                instance["InstanceName"] = getInstanceName(instance)
                instance["AccountId"] = accountId
                instances.append(instance)

    # return list of instances
    return instances

def monitor(event, context):
    """
    This method looks for ec2 instances in each AWS
    account to be monitored and reports
    any found instances to a json file in s3.
    """
    arns = parseArnsString(READER_ROLE_ARNS)

    instances = getAllInstances() # monitor for current account with no role arn
    for arn in arns: instances += getAllInstances(arn) 

    if len(instances) is 0:
        logger.warning("no instances found")
        return

    # get s3 key and body
    key = S3_MONITORING_PATH + '/' + datetime.datetime.utcnow().isoformat() + '.json'
    body = json.dumps(instances, default=datetimeSerializer).encode("utf-8")

    # save to s3
    logger.info(f"creating new monitoring report at s3://{S3_BUCKET_NAME}/{key}")
    s3 = getSession().resource("s3")
    s3.Bucket(S3_BUCKET_NAME).put_object(Key=key, Body=body)

    return "finished monitoring."

import datetime
import json
import logging
import os
from serializer import datetimeSerializer
from sessionManager import getSession, getAccountId, parseArnsString

logger = logging.getLogger()
logger.setLevel(logging.INFO)

S3_BUCKET_NAME = os.environ['S3_BUCKET_NAME']
S3_MONITORING_PATH = os.environ['S3_SG_MONITORING_PATH']
READER_ROLE_ARNS = os.environ['READER_ROLE_ARNS']

def getAllSecurityGroups(roleArn=None):
    """
    This function grabs each security group from each region and returns
    a list of the security groups. 

    If a roleArn is provided, the role is assumed before monitoring
    """
    session = getSession(roleArn) # defaults to local aws account if arn is None
    accountId = getAccountId(session)

    # get list of all groups in each region
    securityGroups = []
    regions = session.client('ec2').describe_regions()['Regions']
    for region in regions:
        ec2 = session.client('ec2', region_name=region['RegionName'])
        for group in ec2.describe_security_groups()['SecurityGroups']:
            group["Region"] = region
            group["AccountId"] = accountId
            securityGroups.append(group)

    # return list of groups
    return securityGroups


def monitor(event, context):
    """
    This method looks for security groups and reports
    any found groups to a json file in s3.
    """
    arns = parseArnsString(READER_ROLE_ARNS)

    # get groups
    groups = getAllSecurityGroups() # defaults to current account
    for arn in arns:
        groups += getAllSecurityGroups(arn)

    if len(groups) is 0:
        logger.warning("no security groups found")
        return

    # get s3 key and body
    key = S3_MONITORING_PATH + '/' + datetime.datetime.utcnow().isoformat() + '.json'
    body = json.dumps(groups, default=datetimeSerializer).encode("utf-8")

    # save to s3
    logger.info(f"creating new monitoring report at s3://{S3_BUCKET_NAME}/{key}")
    s3 = getSession().resource("s3")
    s3.Bucket(S3_BUCKET_NAME).put_object(Key=key, Body=body)

    return "finished monitoring."

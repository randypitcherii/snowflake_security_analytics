import datetime
import json
import logging
import os
from serializer import datetimeSerializer
from sessionManager import getSession, getAccountId, parseArnsString

logger = logging.getLogger()
logger.setLevel(logging.INFO)

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
    for arn in arns: groups += getAllSecurityGroups(arn)
    
    # convert to valid json strings
    jsonStrings = [
        json.dumps(group, default=datetimeSerializer).encode("utf-8") for group in groups
    ]

    # create valid insert data for fivetran response
    monitored_time = datetime.datetime.utcnow().isoformat()
    fivetranInserts = [
        {
            'RAW_DATA': json.loads(jsonString),
            'SNOWWATCH_MONITORED_TIME_UTC': monitored_time
        }
        for jsonString in jsonStrings
    ]

    # return monitoring results to fivetran
    response = {
        'state': 0,
        'hasMore': False,
        'insert': {
            'security_groups': fivetranInserts
        }
    }

    return response

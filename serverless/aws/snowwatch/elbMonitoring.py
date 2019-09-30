import datetime
import json
import logging
import os
from serializer import datetimeSerializer
from sessionManager import getSession, getAccountId, parseArnsString

logger = logging.getLogger()
logger.setLevel(logging.INFO)

S3_BUCKET_NAME = os.environ['S3_BUCKET_NAME']
S3_MONITORING_PATH = os.environ['S3_ELB_MONITORING_PATH']
READER_ROLE_ARNS = os.environ['READER_ROLE_ARNS']

def getAllV1ELBs(roleArn=None):
    """
    This function grabs each classic elb from each region and returns
    a list of them.

    If a roleArn is provided, that role is assumed before monitoring
    """
    session = getSession(roleArn) # defaults to local session if roleArn is None
    accountId = getAccountId(session)

    # get list of all load balancers in each region
    elbs = []
    regions = session.client('ec2').describe_regions()['Regions']
    for region in regions:
        elbClient = session.client('elb', region_name=region['RegionName'])
        for elb in elbClient.describe_load_balancers()['LoadBalancerDescriptions']:
            # add data before adding elb to list of elbs
            elb["Region"] = region
            elb["AccountId"] = accountId
            elbs.append(elb)

    # return list of load balancers
    return elbs


def getAllV2ELBs(roleArn=None):
    """
    This function grabs each v2 elb from each region and returns
    a list of them.

    If a roleArn is provided, that role is assumed before monitoring
    """
    session = getSession(roleArn) # defaults to local session if roleArn is None
    accountId = getAccountId(session)

    # get list of all load balancers in each region
    elbs = []
    regions = session.client('ec2').describe_regions()['Regions']
    for region in regions:
        elbClient = session.client('elbv2', region_name=region['RegionName'])
        for elb in elbClient.describe_load_balancers()['LoadBalancers']:
            # add additional data
            elb["Region"] = region
            elb["AccountId"] = accountId

            # add listeners to see which SSL policies are attached to this elb
            elbArn = elb['LoadBalancerArn']
            listeners = elbClient.describe_listeners(LoadBalancerArn=elbArn)
            elb["Listeners"] = listeners # add listeners as feild in the ELB

            elbs.append(elb)

    # return list of load balancers
    return elbs

def monitor(event, context):
    """
    This method looks for elastic load balancers and reports
    any found elbs to a json file in s3.
    """
    arns = parseArnsString(READER_ROLE_ARNS)

    # get elbs
    v1ELBs = getAllV1ELBs()
    v2ELBs = getAllV2ELBs()
    elbs = [] + v1ELBs + v2ELBs
    for arn in arns:
        elbs += getAllV1ELBs(arn) + getAllV2ELBs(arn)

    if len(elbs) is 0:
        logger.warning("no elastic load balancers found")
        return

    # get s3 key and body
    key = S3_MONITORING_PATH + '/' + datetime.datetime.utcnow().isoformat() + '.json'
    body = json.dumps(elbs, default=datetimeSerializer).encode("utf-8")

    # save to s3
    logger.info(f"creating new monitoring report at s3://{S3_BUCKET_NAME}/{key}")
    s3 = getSession().resource("s3")
    s3.Bucket(S3_BUCKET_NAME).put_object(Key=key, Body=body)

    return "finished monitoring."

import datetime
import json
import logging
import os
from serializer import datetimeSerializer
from sessionManager import getSession, getAccountId, parseArnsString

logger = logging.getLogger()
logger.setLevel(logging.INFO)

S3_BUCKET_NAME = os.environ['S3_BUCKET_NAME']
S3_MONITORING_PATH = os.environ['S3_IAM_MONITORING_PATH']
READER_ROLE_ARNS = os.environ['READER_ROLE_ARNS']

def getAllIAMData(roleArn=None):
    """
    This function gets all user, group, policy, and role data
    from IAM and returns a dict of 4 lists containing this information.

    If a roleArn is provided, that role is assumed before monitoring.
    """
    session = getSession(roleArn) # if no arn, the base boto3 session is used
    accountId = getAccountId(session)

    # define lists to hold each of the 4 types of iam data
    userDetails, groupDetails, roleDetails, policyDetails = [], [], [], []

    # get paginated iam data
    iamClient = session.client('iam')
    authDetails = iamClient.get_account_authorization_details()
    while True:
        userDetails.extend(authDetails['UserDetailList'])
        groupDetails.extend(authDetails['GroupDetailList'])
        roleDetails.extend(authDetails['RoleDetailList'])
        policyDetails.extend(authDetails['Policies'])

        # break the loop if there are no more results
        if not authDetails['IsTruncated']:
            break
        
        # fetch next results
        authDetails = iamClient.get_account_authorization_details(Marker=authDetails['Marker'])
    
    # add MFA data for each user
    for user in userDetails:
        user['MFADevices'] = iamClient.list_mfa_devices(UserName=user['UserName'])['MFADevices']
    
    # add account id to each detail
    for detail in userDetails:   detail['AccountId'] = accountId
    for detail in groupDetails:  detail['AccountId'] = accountId
    for detail in roleDetails:   detail['AccountId'] = accountId
    for detail in policyDetails: detail['AccountId'] = accountId
        
    # return iam data
    return {
        'users':    userDetails,
        'groups':   groupDetails,
        'roles':    roleDetails,
        'policies': policyDetails
    }


def monitor(event, context):
    """
    This method looks for iam data and reports 4 different
    kinds of data into 4 different JSON files stored in s3
    """
    arns = parseArnsString(READER_ROLE_ARNS)

    # gather iamData
    iamData = getAllIAMData()
    for arn in arns:
        additionalIamData = getAllIAMData(arn)
        iamData['users']    += additionalIamData['users']
        iamData['groups']   += additionalIamData['groups']
        iamData['roles']    += additionalIamData['roles']
        iamData['policies'] += additionalIamData['policies']

    # report each type of data
    s3Client = getSession().resource("s3")
    reportName = datetime.datetime.utcnow().isoformat() + '.json' # same report name for each data type
    for typeOfIamData in iamData:
        # get s3 key and body
        key = S3_MONITORING_PATH + f"/{typeOfIamData}/" + reportName
        body = json.dumps(iamData[typeOfIamData], default=datetimeSerializer).encode("utf-8")

        # save to s3
        logger.info(f"creating new monitoring report at s3://{S3_BUCKET_NAME}/{key}")
        s3Client.Bucket(S3_BUCKET_NAME).put_object(Key=key, Body=body)

    return "finished monitoring."

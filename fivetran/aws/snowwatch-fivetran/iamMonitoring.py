import datetime
import json
import logging
import os
from serializer import datetimeSerializer
from sessionManager import getSession, getAccountId, parseArnsString

logger = logging.getLogger()
logger.setLevel(logging.INFO)

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
    
    # convert to valid json strings
    userJsonStrings = [ json.dumps(user, default=datetimeSerializer).encode("utf-8") for user in iamData['users'] ]
    groupJsonStrings = [ json.dumps(group, default=datetimeSerializer).encode("utf-8") for group in iamData['groups'] ]
    roleJsonStrings = [ json.dumps(role, default=datetimeSerializer).encode("utf-8") for role in iamData['roles'] ]
    policyJsonStrings = [ json.dumps(policy, default=datetimeSerializer).encode("utf-8") for policy in iamData['policies'] ]

    # create valid insert data for fivetran response
    monitored_time = datetime.datetime.utcnow().isoformat()
    iamInsertData = {
        'IAM_USERS': [{
            'RAW_DATA': json.loads(jsonString),
            'SNOWWATCH_MONITORED_TIME_UTC': monitored_time
        } for jsonString in userJsonStrings ],
        'IAM_GROUPS': [{
            'RAW_DATA': json.loads(jsonString),
            'SNOWWATCH_MONITORED_TIME_UTC': monitored_time
        } for jsonString in groupJsonStrings ],
        'IAM_ROLES': [{
            'RAW_DATA': json.loads(jsonString),
            'SNOWWATCH_MONITORED_TIME_UTC': monitored_time
        } for jsonString in roleJsonStrings ],
        'IAM_POLICIES': [{
            'RAW_DATA': json.loads(jsonString),
            'SNOWWATCH_MONITORED_TIME_UTC': monitored_time
        } for jsonString in policyJsonStrings ]
    }

    # return monitoring results to fivetran
    response = {
        'state': 0,
        'hasMore': False,
        'insert': iamInsertData
    }
    return response

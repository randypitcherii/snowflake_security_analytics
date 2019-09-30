import boto3
from boto3.session import Session

def getSession(roleArn=None):
    """
    This method returns a boto3 session. If a roleArn is provided,
    an attempt will be made to assume that role and return a session
    that uses that role. If not, the base boto3 session is returned.
    """
    if roleArn is None:
        return boto3
    
    # get assumed role credentials
    stsClient = boto3.client('sts')
    assumeRoleResponse = stsClient.assume_role(RoleArn=roleArn, RoleSessionName='snowwatch')
    credentials = assumeRoleResponse['Credentials']

    # return session built from assumed credentials 
    return Session(
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken']
    )


def getAccountId(session=None):
    """
    uses STS to get the account ID of the given boto3Session
    """
    if session is None:
        raise ValueError("session cannot be none")

    stsClient = session.client('sts')
    return stsClient.get_caller_identity().get('Account')


def parseArnsString(arnsString=None):
    """
    This function returns a list of arns from the
    comma-separated arnsString string. If the string is empty
    or None, an empty list is returned.
    """
    if arnsString is None or arnsString is '':
        return []
    else:
        return arnsString.split(',')
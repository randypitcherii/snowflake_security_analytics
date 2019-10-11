![](/static/sw-logo-large.png)

# SNOWWATCH Serverless Stack for Fivetran
This serverless deployment monitors the following resources in AWS
- IAM Roles, Policies, Users, and Groups
- EC2
- ELBs
- Security Groups

The default behavior is to only monitor the account that snowwatch is deployed to. However, multi-account monitoring is supported through the use of IAM Roles deployed to external accounts. 

For convenience, the [`snowwatch-reader-role`](../snowwatch-reader-role) serverless stack can be deployed to these external accounts to create a single role with inline permissions needed for monitoring. Deploy those first and keep note of the resulting role ARNs.

These Lambda functions are designed to be used as custom Lambda sources in [Fivetran](https://fivetran.com/)

# Installation
Run the following commands AFTER deploying the [`snowwatch-reader-role`](../snowwatch-reader-role) stack in all target AWS accounts. You'll need to have the resulting role ARN for each external account you wish to monitor in this deployment

```
npm i
./node_modules/serverless/bin/serverless deploy \
  --reader_role_arns < comma-separated list of role arns (arn1,arn2,arn3). This is optional.> \
  --account_id <the aws account id to deploy snowwatch to> \
  --aws_config_profile_name <aws credentials profile name to use. This is optional.>
  --fivetran_external_id <your Fivetran external id. Find this in the new lambda connector page.>
```

*NOTE:* If you do not wish to provide external account roles, you must delete the following from the [`serverless.yml`](./serverless.yml):

```
    - Effect: 'Allow' # assume role permissions. DELETE THIS ELEMENT IF NO ARNS ARE PRESENT
      Action:
        - 'sts:AssumeRole'
      Resource: 
        Fn::Split: 
          - ","
          - ${self:custom.readerRoleArns}
```

A better developer could probably figure out how to handle this IAM permission in cases when no `readerRoleArns` are provided.
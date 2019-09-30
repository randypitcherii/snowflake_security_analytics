<img src="https://raw.githubusercontent.com/hashmapinc/SnowWatch/master/docs/source/sw-logo-large.png" alt="snowwatch"/>

# SNOWWATCH Reader Role| Serverless Stack
This serverless deployment is just some cloudformation to create a single external role in a target readable AWS account. It will grant read access to the following:
- IAM Roles, Policies, Users, and Groups
- EC2
- ELBs
- Security Groups

[See here for the detailed permissions granted to the external role.](./snowwatch_reader_role.yml)

## Installation
From the `snowwatch-reader-role` directory, run the following commands to deploy an external role into the AWS account associated with the profile name used for authentication:

- `npm i`
- `./node_modules/serverless/bin/serverless deploy --runner_account_id <aws account id that can use the role> --aws_config_profile_name <aws credentials profile name for the main AWS account>`

It is important to note that the account ID passed above is for the AWS account you intend to run [snowwatch](../snowwatch) in. It is not the ID of the account you wish to deploy this external role to. 
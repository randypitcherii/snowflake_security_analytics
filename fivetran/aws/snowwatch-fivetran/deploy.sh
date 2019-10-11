#!/bin/bash

npm i
./node_modules/serverless/bin/serverless deploy \
  --reader_role_arns YOUR_AWS_READ_ROLE_1_HERE,YOUR_AWS_READ_ROLE_2_HERE,ETC \
  --account_id YOUR_AWS_RUNNER_ACCOUNT_ID_HERE \
  --aws_config_profile_name YOUR_AWS_CONFIG_LOCAL_PROFILE_NAME_HERE \
  --fivetran_external_id YOUR_FIVETRAN_EXTERNAL_ID_HERE
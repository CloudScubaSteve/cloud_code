#!/bin/bash

function ensure_environment_variable_is_set {
    while [ "$*" != "" ]; do
    test -n "${!1}" || { echo >&2 "Required environment variable '$1' not found. Aborting."; exit 1; }
    shift
    done
  }

MANAGEMENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
SECURITY_ACCOUNT=""
REGIONS="us-east-1 us-west-2"
ensure_environment_variable_is_set MANAGEMENT_ACCOUNT SECURITY_ACCOUNT REGIONS

# Delegate SecurityHub Admin to Security Account
echo "Assigning Delegated Admin for SecurityHub to ${SECURITY_ACCOUNT}"
for region in ${REGIONS}; do
    echo "...Enabling for ${region}"
  DELEGATE=$(aws securityhub enable-organization-admin-account --admin-account-id ${SECURITY_ACCOUNT} --region ${region} 2>&1)
  if [ $? != 0 ]
  then
    ENABLED=$(echo ${DELEGATE} | grep -c 'ResourceConflictException')
    if [ ${ENABLED} != 1 ]; then
      echo "Error delegating admin"
      echo "${DELEGATE}"
      exit 1
    fi
  fi
  ENABLE_MANAGEMENT_ACCOUNT=$(aws securityhub enable-security-hub --region ${region} 2>&1)
  if [ $? != 0 ]
  then
    ENABLED=$(echo ${ENABLE_MANAGEMENT_ACCOUNT} | grep -c 'ResourceConflictException')
    if [ ${ENABLED} != 1 ]; then
      echo "Error turning on SecurityHub in Management account region ${region}"
      echo "${ENABLE_MANAGEMENT_ACCOUNT}"
      exit 1
    fi
  fi
done

# Enable SecurityHub for all accounts
echo "Listing all existing accounts"
ACTIVE_ACCOUNTS=$(aws organizations list-accounts --query 'Accounts[?Status==`ACTIVE`].[Id]' --output text)
for acct in ${ACTIVE_ACCOUNTS}; do
    if [ $acct != ${SECURITY_ACCOUNT} ]; then
        acct_details+="{\"AccountId\": \"${acct}\"}, "
    fi
done
trim_deets=$(echo ${acct_details}| sed 's/, *$//g')
echo "Assuming Role in Security Account"
role_credentials=$(aws sts assume-role --role-arn arn:aws:iam::${SECURITY_ACCOUNT}:role/AWSControlTowerExecution --role-session-name EnableSecurityHub)
export AWS_ACCESS_KEY_ID=$(echo "$role_credentials" | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo "$role_credentials" | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo "$role_credentials" | jq -r .Credentials.SessionToken)
for region in ${REGIONS}; do
    echo "...Enabling for existing accounts in ${region}"
    ENABLE_SEC_HUB=$(aws securityhub create-members --region ${region} --account-details "[${trim_deets}]")
    if [ "$(echo ${ENABLE_SEC_HUB}| jq -r '.UnprocessedAccounts')" != "[]" ]; then
        echo "ERROR enabling Security Hub: ${ENABLE_SEC_HUB}"
    fi
    echo "...Setting auto-enable for ${region}"
    aws securityhub update-organization-configuration --auto-enable --region $region
done

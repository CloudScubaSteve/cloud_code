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

# Delegate Macie Admin to Security Account
echo "Assigning Delegated Admin for Macie to ${SECURITY_ACCOUNT}"
for region in ${REGIONS}; do
    echo ".Enabling for ${region}"
  DELEGATE=$(aws macie2 enable-organization-admin-account --admin-account-id ${SECURITY_ACCOUNT} --region ${region} 2>&1)
  if [ $? != 0 ]
  then
    ENABLED=$(echo ${DELEGATE} | grep -c 'ConflictException')
    if [ ${ENABLED} != 1 ]; then
      echo "Error delegating admin"
      echo "${DELEGATE}"
      exit 1
    fi
  fi
  ENABLE_MANAGEMENT_ACCOUNT=$(aws macie2 enable-macie --region ${region} 2>&1)
  if [ $? != 0 ]
  then
    ENABLED=$(echo ${ENABLE_MANAGEMENT_ACCOUNT} | grep -c 'ConflictException')
    if [ ${ENABLED} != 1 ]; then
      echo "Error turning on Macie in Management account region ${region}"
      echo "${ENABLE_MANAGEMENT_ACCOUNT}"
      exit 1
    fi
  fi
done

# Enable Macie for all accounts
echo "**Assuming Role in Security Account**"
role_credentials=$(aws sts assume-role --role-arn arn:aws:iam::${SECURITY_ACCOUNT}:role/AWSControlTowerExecution --role-session-name EnableMacie)
export AWS_ACCESS_KEY_ID=$(echo "$role_credentials" | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo "$role_credentials" | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo "$role_credentials" | jq -r .Credentials.SessionToken)

echo "Listing all existing accounts"
ACTIVE_ACCOUNTS=$(aws organizations list-accounts --output json)
IDS=$(echo $ACTIVE_ACCOUNTS| jq -r '.Accounts[] | select( .Status == "ACTIVE" )| .Id')
for region in ${REGIONS}; do
  echo ".Setting auto-enable for ${region}"
  aws macie2 update-organization-configuration --auto-enable --region $region
  for acct in $IDS; do
    if [ $acct != ${SECURITY_ACCOUNT} ]; then
      id=$acct
      email=$(echo $ACTIVE_ACCOUNTS | jq --arg s "$acct" -r '.Accounts[] | select( .Id == $s ) | .Email')
      echo "...Enabling Account: $id in Region: $region"
      ENABLE_ACCOUNT=$(aws macie2 create-member --account accountId=$id,email=$email --region $region 2>&1)
      if [ $? != 0 ]
      then
        echo "ERROR Enabling Macie for Account: $id in Region: $region"
        echo $ENABLE_ACCOUNT
      fi
    fi
  done
done

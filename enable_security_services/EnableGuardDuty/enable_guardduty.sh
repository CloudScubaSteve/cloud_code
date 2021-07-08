#!/bin/bash

function ensure_environment_variable_is_set {
    while [ "$*" != "" ]; do
    test -n "${!1}" || { echo >&2 "Required environment variable '$1' not found. Aborting."; exit 1; }
    shift
    done
  }

MANAGEMENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region ) || AWS_REGION="us-east-1"
SECURITY_ACCOUNT=""
REGIONS="us-east-1 us-west-2"
FINDINGS_BUCKET_NAME="guardduty-findings-export-${SECURITY_ACCOUNT}-${AWS_REGION}"
ensure_environment_variable_is_set MANAGEMENT_ACCOUNT SECURITY_ACCOUNT REGIONS AWS_REGION FINDINGS_BUCKET_NAME

for region in ${REGIONS}; do
  # Enable GuardDuty in Management Account
  echo "Enable GuardDuty for Management Account in Region: ${region}"
  ENABLE_MANAGEMENT_ACCOUNT=$(aws guardduty create-detector --enable --region ${region} 2>&1)
  if [ $? != 0 ]; then
    ENABLED=$(echo ${ENABLE_MANAGEMENT_ACCOUNT} | grep -c 'because a detector already exists for the current account')
    if [ ${ENABLED} != 1 ]; then
      echo "ERROR: ${ENABLE_MANAGEMENT_ACCOUNT}"
    fi
  fi
  # Delegate GuardDuty Admin to Security Account
  echo ".Assigning Delegated Admin to ${SECURITY_ACCOUNT}"
  DELEGATE=$(aws guardduty enable-organization-admin-account --admin-account-id ${SECURITY_ACCOUNT} --region ${region} 2>&1)
  if [ $? != 0 ]; then
    ENABLED=$(echo ${DELEGATE} | grep -c 'the account is already enabled as the GuardDuty delegated administrator')
    if [ ${ENABLED} != 1 ]; then
      echo "ERROR delegating admin"
      echo "${DELEGATE}"
      exit 1
    fi
  fi
done

echo "**Assuming Role in Security Account**"
role_credentials=$(aws sts assume-role --role-arn arn:aws:iam::${SECURITY_ACCOUNT}:role/AWSControlTowerExecution --role-session-name EnableGuardDuty)
export AWS_ACCESS_KEY_ID=$(echo "$role_credentials" | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo "$role_credentials" | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo "$role_credentials" | jq -r .Credentials.SessionToken)

echo "Listing all existing accounts"
ACTIVE_ACCOUNTS=$(aws organizations list-accounts --output json)
IDS=$(echo ${ACTIVE_ACCOUNTS}| jq -r '.Accounts[] | select( .Status == "ACTIVE" )| .Id')
for region in ${REGIONS}; do
  detector_id=$(aws guardduty list-detectors --region ${region}| jq -r '.DetectorIds[0]')
  echo ".Setting auto-enable for ${region}"
  AUTO_ENABLE=$(aws guardduty update-organization-configuration --detector-id ${detector_id} --auto-enable --data-sources S3Logs={AutoEnable=True} --region ${region} 2>&1)
  if [ $? != 0 ]; then
    echo "ERROR: ${AUTO_ENABLE}"
  fi
  ENABLE_S3=$(aws guardduty update-detector --detector-id ${detector_id} --enable --data-sources S3Logs={Enable=True} --region $region 2>&1)
  if [ $? != 0 ]; then
    echo "ERROR: ${ENABLE_S3}"
  fi
  for acct in ${IDS}; do
    if [ ${acct} != ${SECURITY_ACCOUNT} ]; then
      id=${acct}
      email=$(echo ${ACTIVE_ACCOUNTS} | jq --arg s "${acct}" -r '.Accounts[] | select( .Id == $s ) | .Email')
      echo "..Enabling Account: ${id} in Region: ${region}"
      ENABLE_ACCOUNT=$(aws guardduty create-members --detector-id ${detector_id} --account AccountId=${id},Email=${email} --region ${region} 2>&1)
      if [ "$(echo ${ENABLE_ACCOUNT}| jq -r '.UnprocessedAccounts')" != "[]" ]; then
        echo "ERROR enabling Security Hub: ${ENABLE_ACCOUNT}"
      fi
    fi
  done
  if [ $? != 0 ]; then
    echo "ERROR Enabling GuardDuty for Account: ${id} in Region: ${region}"
    echo ${START_MONITORING}
  fi
done
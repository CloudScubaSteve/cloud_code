#!/usr/bin/env bash
set -e

BASE=$(basename $PWD)
echo "#--------------------------------------------------------#"
echo "#          Building SAM Packages for ${BASE}              "
echo "#--------------------------------------------------------#"

region=$(aws configure get region) || region="us-east-1"
BUCKET=$(aws s3 ls |awk '{print $3}' |grep -E "^sam-[0-9]{12}-${region}" )

KMS=$(aws s3api get-bucket-encryption \
  --bucket "${BUCKET}" \
  --region "${region}" \
  --query 'ServerSideEncryptionConfiguration.Rules[*].ApplyServerSideEncryptionByDefault.KMSMasterKeyID' \
  --output text
  )

SNS_TOPIC_ARN=""

# Get Maintenance OU Id
for child in $(aws organizations list-children --parent-id $(aws organizations list-roots | jq -r '.Roots[].Id') --child-type ORGANIZATIONAL_UNIT | jq -r '.Children[].Id'); do
    OU_NAME=$(aws organizations describe-organizational-unit --organizational-unit-id $child |jq -r .OrganizationalUnit.Name)
    if [[ $OU_NAME == "Maintenance" ]] ; then
        MAINTENANCE_OU_ID=$(aws organizations describe-organizational-unit --organizational-unit-id $child |jq -r .OrganizationalUnit.Id)
        break
    fi
done

if [[ "${BUCKET}" == "" ]] || [[ "${KMS}" == "" ]] || [[ "${MAINTENANCE_OU_ID}" == "" ]] || [[ "${SNS_TOPIC_ARN}" == "" ]]; then
  printf "[ERROR] One or more variables not defined: \n  BUCKET:${BUCKET}\n  KMS:${KMS}\n  SNS_TOPIC_ARN:${SNS_TOPIC_ARN}\n  MAINTENANCE_OU_ID:${MAINTENANCE_OU_ID}"
  exit 1
fi
echo "Deploying Control Tower Extensions - Custom Resources"

sam build -t lambdas/stepfunctions/cfn.yaml --use-container --region "${region}"

sam package \
  --template-file .aws-sam/build/template.yaml \
  --s3-bucket "${BUCKET}" \
  --s3-prefix "SAM" \
  --kms-key-id "${KMS}" \
  --region "${region}" \
  --output-template-file lambdas/stepfunctions/generated-sam-template.yaml

sam deploy \
  --stack-name MonitorMaintenanceOuFn \
  --template-file lambdas/stepfunctions/generated-sam-template.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides pChatopsSnsTopicArn="${SNS_TOPIC_ARN}" pMaintenanceOu="${MAINTENANCE_OU_ID}" \
  --no-fail-on-empty-changeset

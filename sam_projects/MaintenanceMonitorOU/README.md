# Monitor Maintenance OU

## Description
This solution will provide an automated alerting system when an account is moved into the Maintenance OU. Maintenace OU typically has no or very permissive Service Control Policy, allowing for actions to be performed that are typically not allowed. Leaving an account in the Maintenance OU after compeleting required task introduces added risk while account is not under Control Tower guardrails. The solution uses a number of AWS services: Eventbridge Rule, Step Functions, Cloudwatch Alarm, SNS, Lambda

### Folder Structure

| Folder/File | Description |  
| :-------------------------| :-------------------------------------------------------------------------------------------------------------------|
| cloudformation/sam-bootstrap.yaml            | AWS Cloudformation template that will create the required AWS Resources for the solution to work properly. It will create an IAM Role, KMS Key/Alias and S3 Bucket. All of these AWS Resources are required for an AWS Serverless Application Model (SAM) deployment to successful.|
| lambdas/stepfunctions/MaintenanceOuMonitorFn    | AWS Lambda Function that will check and alert if accounts are in Maintenance OU |
| scripts   | Directory that has the scripts that will be run to deploy the AWS Lambda Functions. |
| scripts/sam.sh   | Executes a number of SAM commands to package / build / deploy the SAM Function to a specified account. | 

## Pre-requisite Steps:
- Control Tower must be turned on in Management Account [Link to AWS Doc](https://docs.aws.amazon.com/controltower/latest/userguide/getting-started-with-control-tower.html)
- Install the Serverless Application Model CLI (SAM) [Link to AWS Doc](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
- Ensure you have AWS CLI and Console access to the AWS Management Account.
- OU Named Maintenance created
- Existing SNS topic to send alerts (optional)

## Deployment Steps:
- Change directory into the repository directory `cd MaintenanceMonitorOU`.
- Execute the cloudformation/sam-bootstrap.yaml into the AWS Management Account where the AWS Control Tower will live.
  ```bash
  aws cloudformation create-stack --stack-name MaintenanceMonitoOu \
    --template-body file://cloudformation/sam-bootstrap.yaml \
    --capabilities CAPABILITY_NAMED_IAM

- Since this solution builds the SAM function inside Lambda-like container, Docker must be installed and running on your workstation.

### Deploying Serverless Templates
These templates include the AWS StepFunction as well as all the Lambda Functions themselves.  The Lambda Function along 
with the CloudFormation to deploy them **cfn.yaml** are located in the "lambdas" directory.
- Deploy Serverless Application Model function.
  ```bash 
  ./scripts/sam.sh 
  ```

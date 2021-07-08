# Monitor Set Account Password Policy

## Description
This solution can be used to set the IAM Password Policy for all accounts in your Control Tower Organization.

### Folder Structure

| Folder/File | Description |  
| :-------------------------| :-------------------------------------------------------------------------------------------------------------------|
| lambdas/SetAccountPasswordPolicy    | AWS Lambda Function that will set IAM password policy for all accounts |
| scripts   | Directory that has the scripts that will be run to deploy the AWS Lambda Functions. |
| scripts/sam.sh   | Executes a number of SAM commands to package / build / deploy the SAM Function to a specified account. | 

## Pre-requisite Steps:
- Control Tower must be turned on in Management Account [Link to AWS Doc](https://docs.aws.amazon.com/controltower/latest/userguide/getting-started-with-control-tower.html)
- Install the Serverless Application Model CLI (SAM) [Link to AWS Doc](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
- Ensure you have AWS CLI and Console access to the AWS Management Account.
- SAM Bootstrap stack has been executed

### Deploying Serverless Templates
These templates include the AWS StepFunction as well as all the Lambda Functions themselves.  The Lambda Function along 
with the CloudFormation to deploy them **cfn.yaml** are located in the "lambdas" directory.
- Deploy Serverless Application Model function.
  ```bash 
  ./scripts/sam.sh 
  ```

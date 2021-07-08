# SAM Bootstrap

## Description
Creates AWS Resources that are required for AWS Serverless Application Model deployments

### Folder Structure
| Folder/File | Description |  
| :-------------------------| :-------------------------------------------------------------------------------------------------------------------|
| cloudformation/sam-bootstrap.yaml            | AWS Cloudformation template that will create the required AWS Resources for the solution to work properly. It will create an IAM Role, KMS Key/Alias and S3 Bucket. All of these AWS Resources are required for an AWS Serverless Application Model (SAM) deployment to successful.|

## Deployment Steps:
- Change directory into the repository directory `cd SamBootstrap`.
- Execute the cloudformation/sam-bootstrap.yaml into the AWS Management Account where the AWS Control Tower will live.
```bash
bash ./scripts/deploy.sh
```

- Since this solution builds the SAM function inside Lambda-like container, Docker must be installed and running on your workstation.

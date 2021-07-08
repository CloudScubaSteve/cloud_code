#!/bin/bash

if [ "$(basename $PWD)" == "scripts" ]; then
  echo "[NOTICE] Script should be executed from base folder as bash ./scripts/deploy.sh"
  echo "Executing cd .."
  cd ..
fi

###################
## Configuration ##
###################
STACK_NAME="SAM-Bootstrap"
TEMPLATE="cloudformation/sam-bootstrap.yaml"
AWS_REGION=$(aws configure get region ) || AWS_REGION="us-east-1"

echo "Creating/Updating SAM Bootstrap Cloudformation Stack"
# Check if stack exists
STACK_EXISTS=true
STACK_CHECK=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} 2>&1)
if [[ $? != 0 ]]; then
    NO_STACK_CHECK=$(echo ${STACK_CHECK} | grep -c 'does not exist')
    if [ ${NO_STACK_CHECK} = 1 ]; then
        echo "...Stack does not exist"
        STACK_EXISTS=false
    else
        echo "Error checking stack"
        echo "${STACK_CHECK}"
        exit 1
    fi
else
    echo "...Stack exists"
fi

# Create stack if one does not exist
if [[ ${STACK_EXISTS} == false ]]; then
    echo "...Creating stack: ${STACK_NAME}"
    CREATE_STACK=$(aws cloudformation create-stack --stack-name ${STACK_NAME} \
                                                   --region ${AWS_REGION} \
                                                   --template-body file://$TEMPLATE \
                                                   --capabilities CAPABILITY_NAMED_IAM 2>&1)
    STATUS=$?
    if [ ${STATUS} -ne 0 ] ; then
      echo "Stack Creation Failed: ${CREATE_STACK}"
      exit ${STATUS}
    fi
    echo "...Waiting for stack to be created"
    aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME} --region ${AWS_REGION}
# Update existing stack
else
    echo "...Updating stack: ${STACK_NAME}"
    UPDATE_STACK=$(aws cloudformation update-stack --stack-name ${STACK_NAME} \
                                                   --region ${AWS_REGION} \
                                                   --template-body file://$TEMPLATE \
                                                   --capabilities CAPABILITY_NAMED_IAM 2>&1)
    STATUS=$?
    if [ ${STATUS} -ne 0 ]; then
        if [ $(echo ${UPDATE_STACK}|grep -c 'No updates are to be performed.') = 1 ]; then
            echo "- No updates required"
        else 
            echo "Stack update failed: ${UPDATE_STACK}"
            exit ${STATUS}
        fi
    else
        echo "...Waiting for stack to be updated"
        aws cloudformation wait stack-update-complete --stack-name ${STACK_NAME} --region ${AWS_REGION}
    fi
fi

import json
import logging
from sts_helper import assume_role_arn, caller_identity
from client_session_helper import boto3_client, boto3_session

logging.basicConfig()
logger = logging.getLogger()
logging.getLogger("botocore").setLevel(logging.ERROR)
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    print(json.dumps(event))
    error = dict()
    account_list = list()
    management_account = caller_identity()
    try:
        account_id = event['detail']['serviceEventDetails']['createManagedAccountStatus']['account']['accountId']
    except Exception:
        account_id = None
    # If account isn't passed in get list of accounts from Organizations
    if not account_id:
        org=boto3_client(service='organizations')
        accounts=org.list_accounts()
        for account in accounts['Accounts']:
            id = account.get('Id', {})
            status = account.get('Status', {})
            if status == 'ACTIVE' and id != management_account:
                logger.debug(f"Account Active: {id}")
                account_list.append(id)
            else:
                logger.info(f"Skipping inactive account:{id} Status: {status}")
    else:
        account_list.append(account_id)

    try:
        for account in account_list:
            role_arn="arn:aws:iam::{}:role/AWSControlTowerExecution".format(account)
            credentials = assume_role_arn(role_arn=role_arn)
            session = boto3_session(region='us-east-1', credentials=credentials)
            iamc = boto3_client(service='iam', session=session)
            
            logger.info(f"Updating Password Policy:{account}")
            try:
                iamc.update_account_password_policy(
                    MinimumPasswordLength=14,
                    RequireSymbols=True,
                    RequireNumbers=True,
                    RequireUppercaseCharacters=True,
                    RequireLowercaseCharacters=True,
                    AllowUsersToChangePassword=True,
                    MaxPasswordAge=60,
                    PasswordReusePrevention=24,
                    HardExpiry=False
                )
            except Exception as e:
                logger.error(str(e))
                error[account] = e
        if error:
            logger.error("Error during execution: consult logs")
            raise Exception(e)

    except Exception as e:
        logger.error(e, exc_info=True)
        raise Exception(str(e))

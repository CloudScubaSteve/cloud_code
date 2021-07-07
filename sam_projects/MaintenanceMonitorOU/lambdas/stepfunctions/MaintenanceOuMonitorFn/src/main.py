import os
import json
import logging
import boto3

logging.basicConfig()
logger = logging.getLogger()
logging.getLogger("botocore").setLevel(logging.ERROR)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """This function will get the number of accounts in the Maintenance OU.

    Args:
        event (dict): Event information passed in by the AWS Step Functions
        context (object): Lambda Function context information

    Returns:
        dict: Payload with number of accounts in Maintenance OU.
    """
    print(json.dumps(event))
    payload = dict()

    org = boto3.client('organizations')
    cloudwatch = boto3.client('cloudwatch')
    maintenance_ou = os.environ.get('MAINTENANCE_OU', {})

    logger.info(f"Listing accounts in OU: {maintenance_ou}")
    account_list = org.list_accounts_for_parent(ParentId=maintenance_ou)
    account_total = len(account_list['Accounts'])
    logger.debug(account_total)
    if account_total > 0:
        logger.info(f"Account(s) found in maintenance ou: {account_total}")
    else:
        logger.info(f"No accounts found in maintenance ou")

    cloudwatch.put_metric_data(
        MetricData = [
            {
                'MetricName': 'Count',
                'Dimensions': [
                    {
                        'Name': 'MaintenanceAccounts',
                        'Value': 'Total'
                    }
                ],
                'Unit': 'None',
                'Value': account_total
            },
        ],
        Namespace='MaintenanceOU'
    )
    
    payload['TotalAccounts'] = {"Count": account_total}

    return payload
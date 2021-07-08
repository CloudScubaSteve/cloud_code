# Enable GuardDuty

## Summary
This solution will turn on GuardDuty in specified regions, and delegate admin to Security account.

## Execution
Variables that need to be set in enable_sechub.sh
- SECURITY_ACCOUNT: AccountId for Security account (123456789012)
- REGIONS: Regions to enable SecurityHub in, best practice is to enable all regions you have enabled by SCP (ie. "us-east-1 us-west-2")
Execute script from ControlTower Management account
```bash
bash ./enable_guardduty.sh
```

## Steps taken by script
***NOTE: Steps are PER REGION***
1. Delegate organization admin to Security account for GuardDuty
1. Get list of all current, active accounts and enable them via GuardDuty in Security account
1. Turns on auto-enable for new accounts added to Organizations

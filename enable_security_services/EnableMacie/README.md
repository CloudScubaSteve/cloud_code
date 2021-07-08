# Enable Macie

## Summary
This solution will turn on Macie in specified regions, and delegate admin to Security account.

## Execution
Variables that need to be set in enable_macie.sh
- SECURITY_ACCOUNT: AccountId for Security account (123456789012)
- REGIONS: Regions to enable Macie in, best practice is to enable all regions you have enabled by SCP (ie. "us-east-1 us-west-2")

Execute script from ControlTower Management account
```bash
bash ./enable_macie.sh
```

## Steps taken by script
***NOTE: Steps are PER REGION***
1. Delegate organization admin to Security account for Macie
1. Get list of all current, active accounts and enable them via Macie in Security account
1. Turns on auto-enable for new accounts added to Organizations

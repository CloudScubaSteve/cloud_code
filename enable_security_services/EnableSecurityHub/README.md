# Enable SecurityHub

## Summary
This solution will turn on SecurityHub in specified regions, and delegate admin to Security account. Optionally it can enable integration for Prowler to SecurityHub.

## Execution
Variables that need to be set in enable_sechub.sh
- SECURITY_ACCOUNT: AccountId for Security account (123456789012)
- REGIONS: Regions to enable SecurityHub in, best practice is to enable all regions you have enabled by SCP (ie. "us-east-1 us-west-2")
- ENABLE_PROWLER_INTEGRATION: Enable Prowler intergration to SecurityHub (default: true)
Execute script from ControlTower Management account
```bash
bash ./enable_sechub.sh
```

## Steps taken by script
***NOTE: Steps are PER REGION***
1. Delegate organization admin to Security account for SecurityHub
1. Get list of all current, active accounts and enable them via SecurityHub in Security account
1. Turns on auto-enable for new accounts added to Organizations
1. If selected, enable prowler integration

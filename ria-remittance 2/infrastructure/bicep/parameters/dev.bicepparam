using '../main.bicep'

param project = 'ria'
param envName = 'dev'
param owner = 'devops-team'

// Region = region of the resource group that Disney provides (no location parameter needed).

// Must be globally unique. Check availability first: az storage account check-name --name <name>
param storageAccountName = 'riastdev001'
param keyVaultName = 'kv-riadev-unique' // replace "unique", e.g. kv-riadev-a1b2

// Must be globally unique, 5-50 alphanumeric only (no hyphens)
param containerRegistryName = 'riacrdev001'

// Confirm the address ranges with Disney's network team before deploying.
param vnetCidr = '10.20.0.0/16'
param appSubnetCidr = '10.20.0.0/23'
param peSubnetCidr = '10.20.2.0/24'

// DEV foundation: public endpoint stays on until private endpoints are added.
param publicNetworkAccess = 'Enabled'
param purgeProtection = false

// Log retention: 30 days for DEV (set 90+ for PROD)
param logRetentionDays = 30


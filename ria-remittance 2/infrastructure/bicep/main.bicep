// =============================================================================
// RIA - Infrastructure Foundation
// Resources: VNet, Managed Identity, Storage, Key Vault, Service Bus,
//            Container Registry, Monitoring (Log Analytics + App Insights),
//            Container Apps Environment (API + Worker)
//
// Resource-group scope: the resource group is PROVIDED (by Disney),
// this file deploys INTO it.
//
//   az deployment group what-if -g <provided-rg> -f main.bicep -p parameters/dev.bicepparam
//   az deployment group create  -g <provided-rg> -f main.bicep -p parameters/dev.bicepparam
// =============================================================================
targetScope = 'resourceGroup'

@description('Short project code.')
param project string = 'ria'

@allowed(['dev', 'ait', 'uat', 'prod'])
param envName string = 'dev'

@description('Defaults to the region of the provided resource group.')
param location string = resourceGroup().location

param owner string = 'devops-team'

@description('Globally unique, 3-24 lowercase letters/digits. Example: riastdev001')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Globally unique, 3-24 chars, letters/digits/hyphens. e.g. kv-riadev-a1b2')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Globally unique, 5-50 alphanumeric chars. e.g. riacrdev001')
@minLength(5)
@maxLength(50)
param containerRegistryName string

param vnetCidr string = '10.20.0.0/16'
param appSubnetCidr string = '10.20.0.0/23'
param peSubnetCidr string = '10.20.2.0/24'

@description('Enabled for the first DEV setup. Set to Disabled after private endpoints are added.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Enabled'

@description('Keep false in DEV so the vault can be recreated; must be true for prod.')
param purgeProtection bool = false

@description('Log Analytics retention in days. DEV: 30, PROD: 90+')
param logRetentionDays int = 30

var prefix = '${project}-${envName}' // ria-dev

var tags = {
  project: project
  environment: envName
  owner: owner
  managedBy: 'bicep'
}

// ─── Module 1: Networking ─────────────────────────────────────────────────────
module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    name: 'vnet-${prefix}'
    location: location
    tags: tags
    vnetCidr: vnetCidr
    appSubnetCidr: appSubnetCidr
    peSubnetCidr: peSubnetCidr
  }
}

// ─── Module 2: Managed Identity ───────────────────────────────────────────────
module identity 'modules/identity.bicep' = {
  name: 'identity'
  params: {
    name: 'id-${prefix}-app'
    location: location
    tags: tags
  }
}

// ─── Module 3: Storage Account (7 blob containers) ────────────────────────────
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    publicNetworkAccess: publicNetworkAccess
  }
}

// ─── Module 4: Key Vault ──────────────────────────────────────────────────────
module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    name: keyVaultName
    location: location
    tags: tags
    publicNetworkAccess: publicNetworkAccess
    purgeProtection: purgeProtection
  }
}

// ─── Module 5: Service Bus (Queues + DLQ) ────────────────────────────────────
module servicebus 'modules/servicebus.bicep' = {
  name: 'servicebus'
  params: {
    name: 'sb-${prefix}'
    location: location
    tags: tags
  }
}

// ─── Module 6: Container Registry (ACR) ──────────────────────────────────────
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'container-registry'
  params: {
    name: containerRegistryName
    location: location
    tags: tags
  }
}

// ─── Module 7: Monitoring (Log Analytics + Application Insights) ──────────────
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    name: prefix
    location: location
    tags: tags
    retentionInDays: logRetentionDays
  }
}

// ─── Module 8: Container Apps (Environment + API + Worker) ───────────────────
// Depends on: network, identity, container-registry, monitoring
module containerApps 'modules/container-apps.bicep' = {
  name: 'container-apps'
  params: {
    name: prefix
    location: location
    tags: tags
    appSubnetId: network.outputs.appSubnetId                                // from network module
    logAnalyticsCustomerId: monitoring.outputs.logAnalyticsCustomerId       // from monitoring module
    logAnalyticsSharedKey: monitoring.outputs.logAnalyticsSharedKey         // from monitoring module
    acrLoginServer: containerRegistry.outputs.loginServer                   // from ACR module
    identityId: identity.outputs.id                                          // from identity module
    identityClientId: identity.outputs.clientId                             // from identity module
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString  // from monitoring module
  }
}

// ─── Outputs ──────────────────────────────────────────────────────────────────
output vnetName string                   = network.outputs.name
output appSubnetId string                = network.outputs.appSubnetId
output peSubnetId string                 = network.outputs.peSubnetId
output identityClientId string           = identity.outputs.clientId
output identityPrincipalId string        = identity.outputs.principalId
output storageAccountName string         = storage.outputs.name
output keyVaultName string               = keyvault.outputs.name
output keyVaultUri string                = keyvault.outputs.uri
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output logAnalyticsName string           = monitoring.outputs.logAnalyticsName
output appInsightsName string            = monitoring.outputs.appInsightsName
output containerAppsEnvironmentName string = containerApps.outputs.environmentName
output apiAppFqdn string                 = containerApps.outputs.apiAppFqdn

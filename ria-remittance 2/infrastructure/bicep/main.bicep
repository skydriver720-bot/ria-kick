// =============================================================================
// RIA - DEV foundation: VNet, managed identity, Storage, Key Vault.
// Resource-group scope: the resource group is PROVIDED (by Disney), this file deploys INTO it.
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

@description('Globally unique, 3-24 chars, letters/digits/hyphens. Replace the "unique" part, e.g. kv-riadev-a1b2')
@minLength(3)
@maxLength(24)
param keyVaultName string

param vnetCidr string = '10.20.0.0/16'
param appSubnetCidr string = '10.20.0.0/23'
param peSubnetCidr string = '10.20.2.0/24'

@description('Enabled for the first DEV setup. Private endpoints come in a later step; then set to Disabled.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Enabled'

@description('Keep false in DEV so the vault can be recreated; must be true for prod.')
param purgeProtection bool = false

var prefix = '${project}-${envName}' // ria-dev

var tags = {
  project: project
  environment: envName
  owner: owner
  managedBy: 'bicep'
}

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    name: 'vnet-${prefix}' // vnet-ria-dev
    location: location
    tags: tags
    vnetCidr: vnetCidr
    appSubnetCidr: appSubnetCidr
    peSubnetCidr: peSubnetCidr
  }
}

module identity 'modules/identity.bicep' = {
  name: 'identity'
  params: {
    name: 'id-${prefix}-app' // id-ria-dev-app
    location: location
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    publicNetworkAccess: publicNetworkAccess
  }
}

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

output vnetName string = network.outputs.name
output appSubnetId string = network.outputs.appSubnetId
output peSubnetId string = network.outputs.peSubnetId
output identityClientId string = identity.outputs.clientId
output identityPrincipalId string = identity.outputs.principalId
output storageAccountName string = storage.outputs.name
output keyVaultName string = keyvault.outputs.name
output keyVaultUri string = keyvault.outputs.uri

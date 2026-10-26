param name string
param location string
param tags object

@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string

param purgeProtection bool

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true // Azure RBAC, not access policies
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: purgeProtection ? true : null // cannot be turned off once enabled
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: publicNetworkAccess == 'Enabled' ? 'Allow' : 'Deny'
      bypass: 'AzureServices'
    }
  }
}

output id string = kv.id
output name string = kv.name
output uri string = kv.properties.vaultUri

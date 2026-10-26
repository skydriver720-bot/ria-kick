param name string
param location string
param tags object
param vnetCidr string
param appSubnetCidr string
param peSubnetCidr string

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetCidr
      ]
    }
    subnets: [
      {
        // For the application workloads (later: Container Apps environment).
        // Delegation is added when the compute step is built, not now.
        name: 'snet-app'
        properties: {
          addressPrefix: appSubnetCidr
        }
      }
      {
        // Reserved for private endpoints (Blob, Key Vault, ...) in a later step.
        name: 'snet-pe'
        properties: {
          addressPrefix: peSubnetCidr
        }
      }
    ]
  }
}

resource appSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  parent: vnet
  name: 'snet-app'
}

resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  parent: vnet
  name: 'snet-pe'
}

output id string = vnet.id
output name string = vnet.name
output appSubnetId string = appSubnet.id
output peSubnetId string = peSubnet.id

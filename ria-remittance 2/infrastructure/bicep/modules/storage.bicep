param name string
param location string
param tags object

@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string

// Remittance PDFs and processing artifacts, one container per processing layer.
var containerNames = [
  'raw'
  'ocr'
  'preprocessed'
  'pages'
  'rag'
  'output'
  'audit'
]

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS' // DEV. Use ZRS/GRS in prod based on the DR requirement.
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false // access only through Entra ID / managed identity (RBAC)
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: publicNetworkAccess == 'Enabled' ? 'Allow' : 'Deny'
      bypass: 'AzureServices'
    }
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: sa
  name: 'default'
  properties: {
    isVersioningEnabled: true
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [for c in containerNames: {
  parent: blob
  name: c
  properties: {
    publicAccess: 'None'
  }
}]

output id string = sa.id
output name string = sa.name

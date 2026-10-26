param name string
param location string
param tags object

// User-assigned managed identity for the application workloads.
// Role assignments (Blob, Key Vault, ...) are added in a later step, once the target resources exist.
resource appIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

output id string = appIdentity.id
output name string = appIdentity.name
output principalId string = appIdentity.properties.principalId
output clientId string = appIdentity.properties.clientId

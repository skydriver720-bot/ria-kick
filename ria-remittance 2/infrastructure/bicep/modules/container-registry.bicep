// =============================================================================
// Azure Container Registry (ACR)
// Stores Docker images for all RIA Remittance application containers.
// Managed Identity is granted AcrPull role so Container Apps can pull images
// without any credentials.
// =============================================================================

param name string
param location string
param tags object

@description('Admin user is disabled; Container Apps pulls via Managed Identity (RBAC).')
param adminUserEnabled bool = false

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Basic'   // DEV: Basic tier. Use Standard/Premium for geo-replication in prod.
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Enabled'   // DEV: keep open until private link is added.
    zoneRedundancy: 'Disabled'
  }
}

output id string   = acr.id
output name string = acr.name
output loginServer string = acr.properties.loginServer

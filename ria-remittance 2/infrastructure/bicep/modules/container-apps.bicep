// =============================================================================
// Azure Container Apps Environment + Individual Container Apps
// Provisions:
//   1. Container Apps Environment  — Shared runtime (VNet integrated)
//   2. Container App: ria-api      — REST API (ingress enabled, public)
//   3. Container App: ria-worker   — Background processing worker (no ingress)
// Both apps use User-Assigned Managed Identity — no passwords needed.
// =============================================================================

param name string
param location string
param tags object

@description('App Subnet ID for VNet integration (from network module output).')
param appSubnetId string

@description('Log Analytics Workspace Customer ID (from monitoring module output).')
param logAnalyticsCustomerId string

@description('Log Analytics Workspace Shared Key (from monitoring module output).')
@secure()
param logAnalyticsSharedKey string

@description('ACR Login Server (from container-registry module output). e.g. riacrdev.azurecr.io')
param acrLoginServer string

@description('User-Assigned Managed Identity Resource ID (from identity module output).')
param identityId string

@description('User-Assigned Managed Identity Client ID (from identity module output).')
param identityClientId string

@description('Application Insights connection string (from monitoring module output).')
param appInsightsConnectionString string

// 1. Container Apps Environment (VNet integrated, internal)
resource containerAppsEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'cae-${name}'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: appSubnetId   // VNet integrated into snet-app
      internal: false                        // DEV: external. Set true when using private endpoints.
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

// 2. Container App: API Service (with external ingress)
resource apiApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-${name}-api'
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}   // Attach Managed Identity (no passwords!)
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnv.id
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true      // Public HTTPS endpoint
        targetPort: 8000
        transport: 'auto'
      }
      registries: [
        {
          server: acrLoginServer
          identity: identityId   // Pull images from ACR via Managed Identity (no secret)
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'ria-api'
          image: '${acrLoginServer}/ria-api:latest'
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsightsConnectionString
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: identityClientId   // SDK uses this to pick the right managed identity
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
      }
    }
  }
}

// 3. Container App: Background Worker (no ingress, event-driven via Service Bus)
resource workerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-${name}-worker'
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}   // Same identity, different role assignments
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnv.id
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Single'
      // No ingress — worker only listens to Service Bus queues
      registries: [
        {
          server: acrLoginServer
          identity: identityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'ria-worker'
          image: '${acrLoginServer}/ria-worker:latest'
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsightsConnectionString
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: identityClientId
            }
          ]
          resources: {
            cpu: json('1.0')
            memory: '2Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

output environmentId string  = containerAppsEnv.id
output environmentName string = containerAppsEnv.name
output apiAppFqdn string     = apiApp.properties.configuration.ingress.fqdn
output workerAppName string  = workerApp.name

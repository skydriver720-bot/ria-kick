// =============================================================================
// Azure Monitoring Stack
// Provisions:
//   1. Log Analytics Workspace  — Central log sink for all resources
//   2. Application Insights     — Application-level telemetry (requests, traces, exceptions)
// All Container Apps, Service Bus, Storage diagnostic logs are forwarded here.
// =============================================================================

param name string
param location string
param tags object

@description('Data retention in days. DEV: 30 days. PROD: 90+ days.')
param retentionInDays int = 30

// 1. Log Analytics Workspace (central log sink)
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-${name}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'   // Pay-per-GB, most common for non-prod
    }
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// 2. Application Insights (connected to Log Analytics Workspace)
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-${name}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id   // Workspace-based (recommended, classic is retiring)
    RetentionInDays: retentionInDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output logAnalyticsId string            = logAnalytics.id
output logAnalyticsName string          = logAnalytics.name
output logAnalyticsCustomerId string    = logAnalytics.properties.customerId
output logAnalyticsSharedKey string     = logAnalytics.listKeys().primarySharedKey
output appInsightsId string             = appInsights.id
output appInsightsName string           = appInsights.name
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey

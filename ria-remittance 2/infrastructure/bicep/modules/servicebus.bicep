param name string
param location string
param tags object

resource sb 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    minimumTlsVersion: '1.2'
  }
}

// Queues decoupling asynchronous processing with Dead-Letter Queues (DLQ)
var queueNames = [
  'q-ingestion'
  'q-preprocessing'
  'q-rag-indexing'
  'q-intelligence'
  'q-validation'
  'q-hitl-notification'
]

resource queues 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = [for q in queueNames: {
  parent: sb
  name: q
  properties: {
    maxDeliveryCount: 3
    deadLetteringOnMessageExpiration: true
    defaultMessageTimeToLive: 'P14D'
    lockDuration: 'PT5M'
  }
}]

output id string = sb.id
output name string = sb.name

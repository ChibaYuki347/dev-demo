// modules/servicebus.bicep — Service Bus namespace + topic + subscription + role assignment.

@description('Resource name prefix.')
param namePrefix string

@description('Environment (dev/stg/prod).')
@allowed(['dev', 'stg', 'prod'])
param environment string

@description('Azure region.')
param location string

@description('Object ID of the GitHub OIDC SP that needs to receive messages. Empty = skip role assignment.')
param githubSpObjectId string = ''

var skuMap = {
  dev: 'Basic'
  stg: 'Standard'
  prod: 'Premium'
}

resource ns 'Microsoft.ServiceBus/namespaces@2024-01-01' = {
  name: '${namePrefix}-sb-${environment}'
  location: location
  sku: {
    name: skuMap[environment]
    tier: skuMap[environment]
    capacity: environment == 'prod' ? 1 : null
  }
  properties: {
    disableLocalAuth: true  // force Managed Identity / Entra-only auth
  }
}

resource etlTopic 'Microsoft.ServiceBus/namespaces/topics@2024-01-01' = {
  parent: ns
  name: 'etl-events'
  properties: {
    defaultMessageTimeToLive: 'P1D'
    enablePartitioning: environment == 'prod'
  }
}

resource sfToHubspot 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01' = {
  parent: etlTopic
  name: 'sf-to-hubspot'
  properties: {
    lockDuration: 'PT5M'
    deadLetteringOnMessageExpiration: true
    maxDeliveryCount: 10
  }
}

// Azure Service Bus Data Receiver = 4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0
var sbDataReceiverRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
)

resource roleAssign 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(githubSpObjectId)) {
  name: guid(ns.id, githubSpObjectId, sbDataReceiverRoleId)
  scope: ns
  properties: {
    roleDefinitionId: sbDataReceiverRoleId
    principalId: githubSpObjectId
    principalType: 'ServicePrincipal'
  }
}

output namespaceName string = ns.name
output namespaceFqdn string = '${ns.name}.servicebus.windows.net'

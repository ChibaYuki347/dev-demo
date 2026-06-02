// modules/sb-role-runtime.bicep — grants Service Bus Data Receiver to the
// Function App's runtime managed identity. Lives in main.bicep's scope so it
// can see both modules' outputs.

@description('Service Bus namespace name.')
param serviceBusNamespaceName string

@description('Object ID of the Function App system-assigned managed identity.')
param functionAppPrincipalId string

resource ns 'Microsoft.ServiceBus/namespaces@2024-01-01' existing = {
  name: serviceBusNamespaceName
}

// Azure Service Bus Data Receiver = 4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0
var sbDataReceiverRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
)

resource role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(ns.id, functionAppPrincipalId, sbDataReceiverRoleId)
  scope: ns
  properties: {
    roleDefinitionId: sbDataReceiverRoleId
    principalId: functionAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

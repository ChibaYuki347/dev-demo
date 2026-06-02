// main.bicep — subscription-scope deployment of the demo ETL stack.
// Validated locally with `./scripts/validate-bicep.sh` (=> az bicep build).
// Actual deployment is intentionally out of scope for the 30-min demo.

targetScope = 'subscription'

@description('Environment name; used as resource name suffix and Federated Credential subject.')
@allowed(['dev', 'stg', 'prod'])
param environment string = 'dev'

@description('Azure region for all resources.')
param location string = 'japaneast'

@description('Prefix for all resource names.')
@minLength(3)
@maxLength(8)
param namePrefix string = 'devdemo'

@description('Object ID of the GitHub OIDC service principal that needs Service Bus Data Receiver.')
param githubSpObjectId string = ''

var rgName = '${namePrefix}-rg-${environment}'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: {
    environment: environment
    project: 'dev-demo'
    managedBy: 'bicep'
  }
}

module serviceBus 'modules/servicebus.bicep' = {
  scope: rg
  name: 'sb-deploy'
  params: {
    namePrefix: namePrefix
    environment: environment
    location: location
    githubSpObjectId: githubSpObjectId
  }
}

module functionApp 'modules/functionapp.bicep' = {
  scope: rg
  name: 'func-deploy'
  params: {
    namePrefix: namePrefix
    environment: environment
    location: location
    serviceBusNamespaceName: serviceBus.outputs.namespaceName
  }
}

// Grant the Function App's runtime managed identity 'Azure Service Bus Data Receiver'
// on the Service Bus namespace. This is separate from the GitHub deployment SP role
// assignment inside servicebus.bicep — the runtime identity needs its own grant.
module functionSbRole 'modules/sb-role-runtime.bicep' = {
  scope: rg
  name: 'func-sb-role'
  params: {
    serviceBusNamespaceName: serviceBus.outputs.namespaceName
    functionAppPrincipalId: functionApp.outputs.functionAppPrincipalId
  }
}

output resourceGroupName string = rg.name
output serviceBusNamespace string = serviceBus.outputs.namespaceName
output functionAppName string = functionApp.outputs.functionAppName

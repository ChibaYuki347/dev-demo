// modules/functionapp.bicep — Linux Consumption Python Function App with
// system-assigned Managed Identity and Service Bus connection via __fullyQualifiedNamespace.

@description('Resource name prefix.')
param namePrefix string

@description('Environment (dev/stg/prod).')
@allowed(['dev', 'stg', 'prod'])
param environment string

@description('Azure region.')
param location string

@description('Service Bus namespace name (input from servicebus module).')
param serviceBusNamespaceName string

var storageName = toLower('${namePrefix}st${environment}${uniqueString(resourceGroup().id)}')
var planName = '${namePrefix}-plan-${environment}'
var funcName = '${namePrefix}-func-${environment}'

resource storage 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageName
  location: location
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: planName
  location: location
  kind: 'linux'
  sku: { name: 'Y1', tier: 'Dynamic' }
  properties: { reserved: true }
}

resource func 'Microsoft.Web/sites@2024-04-01' = {
  name: funcName
  location: location
  kind: 'functionapp,linux'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      appSettings: [
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'python' }
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storage.name
        }
        // ── Managed Identity-based Service Bus connection ──
        // The trigger's `connection="ServiceBusConnection"` resolves these settings:
        {
          name: 'ServiceBusConnection__fullyQualifiedNamespace'
          value: '${serviceBusNamespaceName}.servicebus.windows.net'
        }
        {
          name: 'ServiceBusConnection__credential'
          value: 'managedidentity'
        }
      ]
    }
  }
}

// Storage Blob Data Owner so the Function host can use Managed Identity against the storage account.
// d83a3a16-bf83-4fa9-9c41-3b5d3fa6e1f4 = Storage Blob Data Owner
var blobOwnerRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'd83a3a16-bf83-4fa9-9c41-3b5d3fa6e1f4'
)

resource storageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, func.id, blobOwnerRoleId)
  scope: storage
  properties: {
    roleDefinitionId: blobOwnerRoleId
    principalId: func.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output functionAppName string = func.name
output functionAppPrincipalId string = func.identity.principalId

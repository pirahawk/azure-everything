// I am trying to deploy container app using Dapr for pub sub
// This was inspired by
// https://learn.microsoft.com/en-us/azure/container-apps/microservices-dapr-pubsub?pivots=nodejs
// https://github.com/Azure-Samples/pubsub-dapr-nodejs-servicebus/blob/main/infra/app/app-env.bicep
// https://learn.microsoft.com/en-us/azure/container-apps/microservices-dapr-azure-resource-manager?tabs=bash&pivots=container-apps-arm
// https://github.com/Azure-Samples/Tutorial-Deploy-Dapr-Microservices-ACA/blob/main/azuredeploy.bicep


param randomSuffix string
param userPrincipalId string
var targetLocation = resourceGroup().location


resource containerManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'containerAppIdentity${randomSuffix}'
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: 'containerreg${randomSuffix}'
}

resource servicebusNameSpace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: 'servicebusns${randomSuffix}'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'logs${randomSuffix}'
  location: targetLocation
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}


resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai${randomSuffix}'
  location: targetLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}


resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' = {
  name: 'containerappenv${randomSuffix}'
  location: targetLocation
  properties: {
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

resource daprComponentPubsub 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  parent: containerAppEnvironment
  name: 'orderpubsub'
  properties: {
    componentType: 'pubsub.azure.servicebus'
    version: 'v1'
    metadata: [
      {
        name: 'azureClientId'
        value: containerManagedIdentity.id  // See https://docs.dapr.io/developing-applications/integrations/azure/authenticating-azure/#credentials-metadata-fields for MSI
      }
      {
        name: 'namespaceName' // See https://docs.dapr.io/reference/components-reference/supported-pubsub/setup-azure-servicebus-topics/#spec-metadata-fields
        value: '${servicebusNameSpace.name}.servicebus.windows.net' // the .servicebus.windows.net suffix is required as per dapr docs
      }
      {
        name: 'consumerID'
        value: 'orders' // Set to the same value of the subscription seen in ./servicebus.bicep
      }
    ]
    scopes: []
  }
  dependsOn: [
    // containerApps
  ]
}

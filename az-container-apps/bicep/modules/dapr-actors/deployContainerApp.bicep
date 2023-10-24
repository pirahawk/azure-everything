// I am trying to deploy container app using Dapr for pub sub
// This was inspired by
// https://learn.microsoft.com/en-us/azure/container-apps/microservices-dapr-pubsub?pivots=csharp
// https://github.com/Azure-Samples/pubsub-dapr-csharp-servicebus/blob/main/infra/app/app-env.bicep
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

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' existing = {
  name: 'cosmosdbaccount${randomSuffix}'
}

resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' existing = {
  name: 'cosmosdb${randomSuffix}'
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

resource daprComponentActorState 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  parent: containerAppEnvironment
  name: 'actor-state-cosmos'
  properties: {
    componentType: 'state.azure.cosmosdb'
    version: 'v1'
    metadata: [
      // {
      //   name: 'azureClientId'
      //   // see https://github.com/Azure-Samples/pubsub-dapr-csharp-servicebus/blob/main/infra/app/access.bicep
      //   // See https://docs.dapr.io/developing-applications/integrations/azure/azure-authentication/authenticating-azure/#authenticating-with-managed-identities-mi
      //   value: containerManagedIdentity.properties.clientId
      // }

      // So it turns out for using state.azure.cosmosdb component, it does not look like we can use the azureClientId managed identity setting
      // Worked this out by looking at how Pulumi does this https://www.pulumi.com/registry/packages/azure-native/api-docs/app/daprcomponent/
      // It looks like you have to supply a masterkey for actor state stores to work :'(
      // Maybe thats why this definition on the dapr site is still correct: https://docs.dapr.io/reference/components-reference/supported-state-stores/setup-azure-cosmosdb/
      {
        name: 'masterKey'
        value: cosmosDbAccount.listKeys().secondaryMasterKey
      }

      {
        name: 'url'
        value: cosmosDbAccount.properties.locations[0].documentEndpoint
      }

      {
        name: 'database'
        value: cosmosDbDatabase.name
      }

      {
        name: 'collection'
        value: 'actorstate'
      }

      {
        name: 'actorStateStore'
        value: 'true'
      }
    ]
    scopes: [
      'myactorserver'
      'myactorclient'
    ]
  }
  dependsOn: [
    // containerAppEnvironment
  ]
}


// Inspired by
// https://github.com/Azure-Samples/pubsub-dapr-csharp-servicebus/blob/main/infra/core/host/container-app.bicep
// https://github.com/Azure-Samples/pubsub-dapr-csharp-servicebus/blob/main/infra/core/host/container-app-upsert.bicep
// https://github.com/Azure-Samples/pubsub-dapr-csharp-servicebus/blob/main/infra/app/publisher.bicep

var daprActorServerContainerImageToUse = '${containerRegistry.properties.loginServer}/azdapractorserver:latest'

resource daprActorServerApp 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: 'dapractorserver${randomSuffix}'
  location: targetLocation
  dependsOn: [
    daprComponentActorState
  ]
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerManagedIdentity.id}': {}
    }
  }
  properties: {
    
    environmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        targetPort: 8080
        external: true
        transport:'auto'
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: containerManagedIdentity.id
        }
      ]
      dapr:{
        enabled: true
        appId: 'myactorserver'
        appProtocol: 'http'
        appPort: 8080
        enableApiLogging: true
        logLevel: 'debug'
      }
    }
    template: {
      containers: [
        {
          image: daprActorServerContainerImageToUse
          name: 'dapractorserver'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Development'
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:8080'
            }
            {
              name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
              value: appInsights.properties.InstrumentationKey
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsights.properties.ConnectionString
            }
            {
              name: 'ApiOptions__ItemName'
              value: 'AppServiceItem'
            }
          ]
          probes:[
            {
              httpGet: {
                path: '/health'
                port: 8080
              }
              initialDelaySeconds:5
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 2
      }
    }
  }
}


var daprActorClientContainerImageToUse = '${containerRegistry.properties.loginServer}/azdapractorclient:latest'

resource daprActorClientApp 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: 'dapractorclient${randomSuffix}'
  location: targetLocation
  dependsOn: [
    daprComponentActorState
  ]
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerManagedIdentity.id}': {}
    }
  }
  properties: {
    
    environmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        targetPort: 8080
        external: true
        transport:'auto'
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: containerManagedIdentity.id
        }
      ]
      dapr:{
        enabled: true
        appId: 'myactorclient'
        appProtocol: 'http'
        appPort: 8080
        enableApiLogging: true
        logLevel: 'debug'
      }
    }
    template: {
      containers: [
        {
          image: daprActorClientContainerImageToUse
          name: 'dapractorclient'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Development'
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:8080'
            }
            {
              name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
              value: appInsights.properties.InstrumentationKey
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsights.properties.ConnectionString
            }
            {
              name: 'ApiOptions__ItemName'
              value: 'AppServiceItem'
            }

            // for info on what Dapr Sidecar port to use https://learn.microsoft.com/en-us/azure/container-apps/dapr-overview?tabs=bicep1%2Cyaml
            // also https://github.com/Azure-Samples/svc-invoke-dapr-csharp/blob/main/checkout/Program.cs
            // and https://learn.microsoft.com/en-us/azure/container-apps/microservices-dapr-service-invoke?pivots=csharp#run-the-net-applications-locally
            {
              name: 'Dapr__ApiSidecarPort'
              value: '3500'
            }
            {
              name: 'Dapr__ApiSidecarHostName'
              value: 'localhost'
            }
            {
              name: 'Dapr__ApiSidecarScheme'
              value: 'http'
            }
          ]
          probes:[
            {
              httpGet: {
                path: '/health'
                port: 8080
              }
              initialDelaySeconds:5
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 2
      }
    }
  }
}

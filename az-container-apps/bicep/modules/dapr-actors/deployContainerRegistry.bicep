// I am trying to deploy container app using Dapr for pub sub
// This was inspired by
// https://learn.microsoft.com/en-us/azure/container-apps/microservices-dapr-pubsub?pivots=csharp
// https://github.com/Azure-Samples/pubsub-dapr-csharp-servicebus/blob/main/infra/app/app-env.bicep
// https://learn.microsoft.com/en-us/azure/container-apps/microservices-dapr-azure-resource-manager?tabs=bash&pivots=container-apps-arm
// https://github.com/Azure-Samples/Tutorial-Deploy-Dapr-Microservices-ACA/blob/main/azuredeploy.bicep

// I am using a User defined managed identity

param randomSuffix string
param userPrincipalId string
var targetLocation = resourceGroup().location



resource containerManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'containerAppIdentity${randomSuffix}'
  location: targetLocation
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'containerreg${randomSuffix}'
  location: targetLocation
  sku: {
    name: 'Standard'
  }
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    adminUserEnabled:false
    anonymousPullEnabled:false
  }
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: 'cosmosdbaccount${randomSuffix}'
  kind: 'GlobalDocumentDB'
  location: targetLocation
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: targetLocation
      }
    ]
  }

  resource cosmosDbDatabase 'sqlDatabases@2023-04-15' = {
    name: 'cosmosdb${randomSuffix}'
    properties: {
      resource: {
        id: 'cosmosdb${randomSuffix}'
      }
    }

    resource daprCosmosActorStateDbContainer 'containers@2022-08-15' = {
      name: 'actorstate'
      properties: {
        options:{
          autoscaleSettings:{
            maxThroughput: 1000
          }
        }
        resource: {
          id: 'actorstate'
          partitionKey:{
            kind: 'Hash'
            paths: [ '/partitionKey' ]
          }
          indexingPolicy:{
            automatic: true
          }
        }
      }
    }

    resource daprCosmosGlobalStateDbContainer 'containers@2022-08-15' = {
      name: 'globalstate'
      properties: {
        options:{
          autoscaleSettings:{
            maxThroughput: 1000
          }
        }
        resource: {
          id: 'globalstate'
          partitionKey:{
            kind: 'Hash'
            paths: [ '/partitionKey' ]
          }
          indexingPolicy:{
            automatic: true
          }
        }
      }
    }

  }
}


resource AcrPullRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

resource CosmosDBContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource CosmosDBOwnerRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
}

resource acrPullContainerAppService 'Microsoft.Authorization/roleAssignments@2022-04-01' ={
  name: guid(containerRegistry.id, containerManagedIdentity.name, AcrPullRole.name)
  scope: containerRegistry
  properties:{
    principalId: containerManagedIdentity.properties.principalId
    roleDefinitionId: AcrPullRole.id
    principalType: 'ServicePrincipal'
    description: 'Assigning AcrPull role to containerAppPrincipalId'
  }
}

// resource cosmosContributorContainerAppService 'Microsoft.Authorization/roleAssignments@2022-04-01' ={
//   name: guid(cosmosDbAccount.id, containerManagedIdentity.name, CosmosDBContributorRole.name)
//   scope: cosmosDbAccount
//   properties:{
//     principalId: containerManagedIdentity.properties.principalId
//     roleDefinitionId: CosmosDBContributorRole.id
//     principalType: 'ServicePrincipal'
//     description: 'CosmosDBContributorRole'
//   }
// }

resource cosmosOwnerContainerAppService 'Microsoft.Authorization/roleAssignments@2022-04-01' ={
  name: guid(cosmosDbAccount.id, containerManagedIdentity.name, CosmosDBOwnerRole.name)
  scope: cosmosDbAccount
  properties:{
    principalId: containerManagedIdentity.properties.principalId
    roleDefinitionId: CosmosDBOwnerRole.id
    principalType: 'ServicePrincipal'
    description: 'CosmosDBOwnerRole'
  }
}

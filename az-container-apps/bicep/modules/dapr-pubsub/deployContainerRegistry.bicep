// I am trying to deploy container app using Dapr for pub sub
// This was inspired by
// https://learn.microsoft.com/en-us/azure/container-apps/microservices-dapr-pubsub?pivots=nodejs
// https://github.com/Azure-Samples/pubsub-dapr-nodejs-servicebus/blob/main/infra/app/app-env.bicep
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

resource servicebusNameSpace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: 'servicebusns${randomSuffix}'
  location: targetLocation
  sku:{
    name:'Standard'
    tier: 'Standard'
  }
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    zoneRedundant: false
  }

  resource ordersTopic 'topics@2022-10-01-preview' = {
    name: 'orders'
    properties:{
      requiresDuplicateDetection:false
      defaultMessageTimeToLive: 'PT10M'
    }

    resource subscription 'subscriptions' = {
      name: 'orders'
      properties: {
        deadLetteringOnFilterEvaluationExceptions: true
        deadLetteringOnMessageExpiration: true
        maxDeliveryCount: 10
      }
    }

  }
}


resource AcrPullRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

resource ServiceBusContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource ServiceBusDataOwnerRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '090c5cfd-751d-490a-894a-3ce6f1109419'
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

resource sbContributorContainerAppService 'Microsoft.Authorization/roleAssignments@2022-04-01' ={
  name: guid(servicebusNameSpace.id, containerManagedIdentity.name, ServiceBusContributorRole.name)
  scope: servicebusNameSpace
  properties:{
    principalId: containerManagedIdentity.properties.principalId
    roleDefinitionId: ServiceBusContributorRole.id
    principalType: 'ServicePrincipal'
    description: 'ServiceBusContributorRole'
  }
}

resource sbDataOwnerContainerAppService 'Microsoft.Authorization/roleAssignments@2022-04-01' ={
  name: guid(servicebusNameSpace.id, containerManagedIdentity.name, ServiceBusDataOwnerRole.name)
  scope: servicebusNameSpace
  properties:{
    principalId: containerManagedIdentity.properties.principalId
    roleDefinitionId: ServiceBusDataOwnerRole.id
    principalType: 'ServicePrincipal'
    description: 'ServiceBusDataOwnerRole'
  }
}

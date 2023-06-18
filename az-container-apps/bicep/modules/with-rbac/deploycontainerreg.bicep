// I am trying to deploy using containr-reg rbac here
// This was inspired by
// https://azureossd.github.io/2023/01/03/Using-Managed-Identity-and-Bicep-to-pull-images-with-Azure-Container-Apps/

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


resource AcrPullRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
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

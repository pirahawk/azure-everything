param userPrincipalId string
param containerRegistryName string
param containerAppId string
param containerAppPrincipalId string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

resource AcrPullRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}


resource acrPullContainerAppService 'Microsoft.Authorization/roleAssignments@2022-04-01' ={
  name: guid(containerAppId, containerAppPrincipalId, AcrPullRole.name)
  scope: containerRegistry
  properties:{
    principalId: containerAppPrincipalId
    roleDefinitionId: AcrPullRole.id
    principalType: 'ServicePrincipal'
    description: 'Assigning AcrPull role to ${containerAppId}'
  }
}

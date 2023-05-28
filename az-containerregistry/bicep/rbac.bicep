param containerRegistryName string
param webAppServiceId string
param webAppServicePrincipalId string


resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

resource AcrPullRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

resource acrPullWebAppService 'Microsoft.Authorization/roleAssignments@2022-04-01' ={
  name: guid(webAppServiceId, webAppServicePrincipalId, AcrPullRole.name)
  scope: containerRegistry
  properties:{
    principalId: webAppServicePrincipalId
    roleDefinitionId: AcrPullRole.id
    principalType: 'ServicePrincipal'
    description: 'Assigning AcrPull role to ${webAppServiceId}'
  }
}

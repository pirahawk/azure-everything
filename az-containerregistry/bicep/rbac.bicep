param userPrincipalId string
param containerRegistryName string
param webAppServiceId string
param webAppServicePrincipalId string
param keyvaultName string


resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyvaultName
}

resource AcrPullRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

resource KVReader 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '21090545-7ca7-4776-b22c-e363652d74d2'
}

resource KVSecretsOfficer 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
}

resource userKVReader 'Microsoft.Authorization/roleAssignments@2022-04-01' ={
  name: guid(keyvault.id, userPrincipalId, KVReader.name)
  scope: keyvault
  properties:{
    principalId: userPrincipalId
    roleDefinitionId: KVReader.id
    principalType: 'User'
    description: 'Assigning KV reader to ME'
  }
}

resource userKVSecretsOfficer 'Microsoft.Authorization/roleAssignments@2022-04-01' ={
  name: guid(keyvault.id, userPrincipalId, KVSecretsOfficer.name)
  scope: keyvault
  properties:{
    principalId: userPrincipalId
    roleDefinitionId: KVSecretsOfficer.id
    principalType: 'User'
    description: 'Assigning KV reader to ME'
  }
}

resource webappKVReader 'Microsoft.Authorization/roleAssignments@2022-04-01' ={
  name: guid(keyvault.id, webAppServicePrincipalId, KVReader.name)
  scope: keyvault
  properties:{
    principalId: webAppServicePrincipalId
    roleDefinitionId: KVReader.id
    principalType: 'ServicePrincipal'
    description: 'Assigning KV reader to ${webAppServiceId}'
  }
}

resource webappKVSecretsOfficer 'Microsoft.Authorization/roleAssignments@2022-04-01' ={
  name: guid(keyvault.id, webAppServicePrincipalId, KVSecretsOfficer.name)
  scope: keyvault
  properties:{
    principalId: webAppServicePrincipalId
    roleDefinitionId: KVSecretsOfficer.id
    principalType: 'ServicePrincipal'
    description: 'Assigning KV reader to ${webAppServiceId}'
  }
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

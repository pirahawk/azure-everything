param userPrincipalId string
param keyvaultName string
param appconfigurationName string


resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyvaultName
}

resource appconfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: appconfigurationName
}

resource KVReader 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '21090545-7ca7-4776-b22c-e363652d74d2'
}

resource KVSecretsOfficer 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
}

resource appConfigDataReaderRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '516239f1-63e1-4d78-a4de-a74fb236a071'
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

resource appConfigDataReader 'Microsoft.Authorization/roleAssignments@2022-04-01' ={
  name: guid(appconfig.id, userPrincipalId, appConfigDataReaderRole.name)
  scope: appconfig
  properties:{
    principalId: userPrincipalId
    roleDefinitionId: appConfigDataReaderRole.id
    principalType: 'User'
    description: 'Assigning App Configuration Data Reader to ME'
  }
}

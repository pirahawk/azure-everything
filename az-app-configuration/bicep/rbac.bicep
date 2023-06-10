param userPrincipalId string
param keyvaultName string


resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyvaultName
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

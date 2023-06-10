param randomSuffix string
param userPrincipalId string

param appConfigKV array = [
  {
    Key: 'TestOptions:Name'
    Value: 'Foo'
  }
  {
    Key: 'TestOptions:Secret'
    Value: 'Bar'
  }
]

var tenantId = subscription().tenantId

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: 'keyvault${randomSuffix}'
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    accessPolicies: []
    enableRbacAuthorization: true
  }
}

resource appconfiguration 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: 'appconfig${randomSuffix}'
  location: resourceGroup().location
  sku: {
    name: 'standard'
  }
  identity:{
    type:'SystemAssigned'
  }

  resource appConfigValues 'keyValues@2023-03-01' = [for configValue in appConfigKV: {
    name: configValue.Key
    properties:{
      value: configValue.Value
      contentType: 'application/vnd.microsoft.appconfig.ff+json;charset=utf-8' // see https://learn.microsoft.com/en-us/azure/azure-app-configuration/concept-config-file#file-content-profile-kvset
    }
  }]

}

module rbacAssign 'rbac.bicep' = {
  name: 'assignRbacRoles'
  dependsOn: []
  params: {
    userPrincipalId: userPrincipalId
    keyvaultName: keyvault.name
    appconfigurationName: appconfiguration.name
  }
}

output deployresourceGroupName string = resourceGroup().name

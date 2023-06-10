param randomSuffix string
param userPrincipalId string
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
    accessPolicies:[]
    enableRbacAuthorization: true
  }
}

resource appconfiguration 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: 'appconfig${randomSuffix}'
  location: resourceGroup().location 
  sku: {
    name: 'standard'
  }

  resource testVal 'keyValues@2023-03-01' = {
    name: 'test:something'
    properties:{
      value: 'Foo'
      contentType: 'application/vnd.microsoft.appconfig.ff+json;charset=utf-8' // see https://learn.microsoft.com/en-us/azure/azure-app-configuration/concept-config-file#file-content-profile-kvset
    }
  }
}

module rbacAssign 'rbac.bicep' = {
  name: 'assignRbacRoles'
  dependsOn: [ ]
  params:{
    userPrincipalId: userPrincipalId
    keyvaultName: keyvault.name
  }
}


output deployresourceGroupName string = resourceGroup().name

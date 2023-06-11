param randomSuffix string
param userPrincipalId string

param appConfigKV array = [
  {
    key: 'TestOptions:Name'
    value: 'Foo'
    label: ''
  }
  {
    key: 'TestOptions:Secret'
    value: 'Bar'
    label: ''
  }
  {
    key: 'TestOptions:Message'
    value: 'Dev Message'
    label: 'Development'
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
      value: configValue.value
      label: configValue.label  // NOTE: Labels do not seem to work through Bicep, recommend doing this through AZ CLI
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

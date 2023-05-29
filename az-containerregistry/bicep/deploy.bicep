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

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'containerreg${randomSuffix}'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties:{
    adminUserEnabled:true
    anonymousPullEnabled:true
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'azAsp${randomSuffix}'
  location: resourceGroup().location
  kind:'linux'
  sku:{
    tier:'Basic'
    name:'B2'
  }
  properties:{
    reserved: true
    zoneRedundant:false
  }
}

var webAppDockerImage = '${containerRegistry.properties.loginServer}/myacrapi:latest'

resource webAppService 'Microsoft.Web/sites@2022-09-01' = {
  name: 'azAsp${randomSuffix}'
  location: resourceGroup().location
  identity:{
    type:'SystemAssigned'
  }

  // see: https://samcogan.com/creating-an-azure-web-app-or-function-running-a-container-with-bicep/
  // and https://learn.microsoft.com/en-us/azure/templates/microsoft.web/sites/config-web?pivots=deployment-language-bicep
  properties:{
    serverFarmId: appServicePlan.id
    siteConfig: {
      webSocketsEnabled:true
      acrUseManagedIdentityCreds: true
      linuxFxVersion: 'DOCKER|${webAppDockerImage}'
      appSettings: []
    }
    httpsOnly:true
  }

  resource apiAppServiceWebConfig 'config' ={
    name: 'web'
    properties: {
      healthCheckPath: '/test'
      // linuxFxVersion: 'DOTNETCORE|6.0'
      // netFrameworkVersion: 'v6.0'
      apiDefinition: {
        url: '/swagger'
      }
    }
  }


  resource appSettingsConfig 'config'={
    name: 'appsettings'
    properties:{
      AppOptions__StationName: 'WebAppWeatherStation'
      AppOptions__KeyVaultUri: keyvault.properties.vaultUri
    }
  }
}

module rbacAssign 'rbac.bicep' = {
  name: 'assignRbacRoles'
  dependsOn: [ containerRegistry, webAppService]
  params:{
    userPrincipalId: userPrincipalId
    containerRegistryName: containerRegistry.name
    webAppServiceId: webAppService.id
    webAppServicePrincipalId: webAppService.identity.principalId
    keyvaultName: keyvault.name
  }
}


output containerRegistryId string = containerRegistry.id
output containerRegistryHostName string = containerRegistry.properties.loginServer
output appServicePlanId string = appServicePlan.id
output webAppDockerImage string = webAppDockerImage

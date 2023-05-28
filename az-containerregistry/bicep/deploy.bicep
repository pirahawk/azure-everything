param resourceGroupName string
param targetLocation string

param containerRegistryName string
param appServicePlanName string
param webAppServiceName string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: containerRegistryName
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
  name: appServicePlanName
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
  name: webAppServiceName
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
}

module rbacAssign 'rbac.bicep' = {
  name: 'assignRbacRoles'
  dependsOn: [ containerRegistry, webAppService]
  params:{
    containerRegistryName: containerRegistry.name
    webAppServiceId: webAppService.id
    webAppServicePrincipalId: webAppService.identity.principalId

  }
}


output containerRegistryId string = containerRegistry.id
output containerRegistryHostName string = containerRegistry.properties.loginServer
output appServicePlanId string = appServicePlan.id
output webAppDockerImage string = webAppDockerImage

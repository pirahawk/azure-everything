param resourceGroupName string
param targetLocation string

param blobStorageName string
param appServicePlanName string
param webAppServiceName string



resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: blobStorageName
  location: targetLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'

  resource blobServices 'blobServices@2022-09-01' = {
    name: 'default'
    resource inputContainer 'containers@2022-09-01' = {
      name: 'input'
    }
  }
}


resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: targetLocation
  kind:'linux'
  sku:{
    tier:'Basic'
    name:'B2'
  }
  properties:{
    zoneRedundant:false
  }
}

resource webAppService 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppServiceName
  location: targetLocation
  dependsOn:[appServicePlan]
  properties:{
    serverFarmId: appServicePlan.id
    siteConfig: {
      webSocketsEnabled:true
    }
    httpsOnly:true
  }

  // https://learn.microsoft.com/en-us/azure/templates/microsoft.web/sites/sourcecontrols?pivots=deployment-language-bicep#sitesourcecontrolproperties
  resource sourceControl 'sourcecontrols@2022-09-01' = {
    name: 'web'
    properties:{
      repoUrl:'https://github.com/Azure-Samples/azure-event-grid-viewer.git'
      branch:'master'
      isManualIntegration:true
    }
  }
}


output deployresourceGroupName string = resourceGroupName
output storageAccountId string = storageAccount.id
output appServicePlanId string = appServicePlan.id
output webAppServiceEndPoints string = webAppService.properties.hostNames[0]


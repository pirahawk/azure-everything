param resourceGroupName string
param targetLocation string

param blobStorageName string
param appServicePlanName string
param webAppServiceName string
param eventGridSystemTopicName string


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
  //dependsOn:[appServicePlan]
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

// Note: to get the topic type see https://learn.microsoft.com/en-us/rest/api/eventgrid/controlplane-version2022-06-15/system-topics/create-or-update?tabs=HTTP#systemtopics_createorupdate
// This was also helpful > az eventgrid topic-type list --query "[].{name:name, provider:provider}"
// For the types of event types you can filter on >  az eventgrid topic-type list-event-types -n Microsoft.Storage.StorageAccounts
resource eventGridSystemTopic 'Microsoft.EventGrid/systemTopics@2022-06-15' = {
  name: eventGridSystemTopicName
  location: targetLocation
  properties:{
    topicType:'microsoft.storage.storageaccounts'
    source:storageAccount.id
  }

  resource eventGridSystemTopicSubscription 'eventSubscriptions@2022-06-15' = {
    name: 'webAppTopicSubScription'
    properties:{
      eventDeliverySchema:'EventGridSchema'
      destination:{
        endpointType:'WebHook'
        properties:{
          endpointUrl:'https://${webAppService.properties.hostNames[0]}/api/updates'
        }
      }
    }
  }

}

output deployresourceGroupName string = resourceGroupName
output storageAccountId string = storageAccount.id
output appServicePlanId string = appServicePlan.id
output webAppServiceEndPoints string = webAppService.properties.hostNames[0]

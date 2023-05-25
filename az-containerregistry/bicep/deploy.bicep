param resourceGroupName string
param targetLocation string

param containerRegistryName string

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

output containerRegistryId string = containerRegistry.id
output containerRegistryHostName string = containerRegistry.properties.loginServer

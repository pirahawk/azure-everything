param randomSuffix string
param userPrincipalId string

var targetLocation = resourceGroup().location

resource containerManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'containerAppIdentity${randomSuffix}'
  location: targetLocation
}

resource appsubnetnsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' existing = {
  name: 'appsubnetnsg${randomSuffix}'
}

resource vnetLab 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: 'vnet${randomSuffix}'
}

resource appsubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: 'appsubnet'
  parent: vnetLab
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'storage${toLower(randomSuffix)}'
  location: targetLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'

  properties: {
    accessTier: 'Hot'
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
    }
  }

  resource containerBlobService 'blobServices@2022-09-01' = {
    name: 'default'

    resource csvFilesContainer 'containers@2022-09-01' = {
      name: 'csvfiles'
    }
  }
}

resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: 'storagepvt${toLower(randomSuffix)}'
  location: targetLocation
  properties: {
    subnet: {
      name: appsubnet.name
      id: appsubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'storagepvt${toLower(randomSuffix)}'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource StorageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource managedIdentityBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, containerManagedIdentity.name, StorageBlobDataContributor.name)
  scope: storageAccount
  properties: {
    principalId: containerManagedIdentity.properties.principalId
    roleDefinitionId: StorageBlobDataContributor.id
    principalType: 'ServicePrincipal'
    description: 'Assigning StorageBlobDataContributor to containerManagedIdentity'
  }
}

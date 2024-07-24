param randomSuffix string
param userPrincipalId string
var targetLocation = resourceGroup().location


resource containerManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'containerAppIdentity${randomSuffix}'
  location: targetLocation
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'storage${toLower(randomSuffix)}'
  location: targetLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'

  resource containerBlobService 'blobServices@2022-09-01' = {
    name: 'default'

    resource csvFilesContainer 'containers@2022-09-01' = {
      name: 'csvfiles'
    }
  }
}

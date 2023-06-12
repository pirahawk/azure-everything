param randomSuffix string
param userPrincipalId string
var tenantId = subscription().tenantId


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

module rbacAssign 'rbac.bicep' = {
  name: 'assignRbacRoles'
  dependsOn: [ ]
  params:{
    userPrincipalId: userPrincipalId
  }
}

output deployresourceGroupName string = resourceGroup().name

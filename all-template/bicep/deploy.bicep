param randomSuffix string
param userPrincipalId string
var tenantId = subscription().tenantId

module rbacAssign 'rbac.bicep' = {
  name: 'assignRbacRoles'
  dependsOn: [ ]
  params:{
    userPrincipalId: userPrincipalId
  }
}

output deployresourceGroupName string = resourceGroup().name

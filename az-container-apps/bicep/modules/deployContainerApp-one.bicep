// This is a the naive approach to deploying the container app, where I am just using no RBAC
// instead just using the containerRegistry keys directly
// This example was modified from the code on:
// https://github.com/Azure-Samples/dotNET-FrontEnd-to-BackEnd-with-DAPR-on-Azure-Container-Apps/blob/main/Azure/container_app.bicep

param randomSuffix string
param userPrincipalId string
var tenantId = subscription().tenantId
var targetLocation = resourceGroup().location


resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'containerreg${randomSuffix}'
  location: targetLocation
  sku: {
    name: 'Standard'
  }
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    adminUserEnabled:true // note that this is true so that you can use admin creds to auth against the registry 
    anonymousPullEnabled:true
  }
}

resource logs 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'logs${randomSuffix}'
  location: targetLocation
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai${randomSuffix}'
  location: targetLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logs.id
  }
}

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' = {
  name: 'containerappenv${randomSuffix}'
  location: targetLocation
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logs.properties.customerId
        sharedKey: logs.listKeys().primarySharedKey
      }
    }
  }
}

var shared_config = [
  {
    name: 'ASPNETCORE_ENVIRONMENT'
    value: 'Development'
  }
  {
    name: 'ASPNETCORE_URLS'
    value: 'http://+:80'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsights.properties.InstrumentationKey
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsights.properties.ConnectionString
  }
]

// Note: Make sure you deploy the container image first or the following will fail
var containerRegistryEndpoint = containerRegistry.properties.loginServer
var containerImageToUse = '${containerRegistryEndpoint}/mycontainerapi:latest'

resource containerApp 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: 'containerapp${randomSuffix}'
  location: targetLocation
  dependsOn:[containerRegistry]
  identity:{
    type: 'SystemAssigned'
  }
  properties:{
    managedEnvironmentId: containerAppEnvironment.id
    // activeRevisionsMode: 'single'

    configuration:{
      secrets: [
        {
          name: 'container-registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]      
      registries:[
        {
          server: containerRegistry.name
          username: containerRegistry.listCredentials().username
          passwordSecretRef: 'container-registry-password'
          // identity: 'system'
        }
      ]
      ingress:{
        external:true //this needs to be true if you want it to have outside access
        targetPort:80
        transport:'http'
        allowInsecure:true 
      }
    }

    template:{
      containers:[
        {
          name: 'mycontainerapp'
          image: containerImageToUse
          env: shared_config
          probes:[
            {
              httpGet:{
                path: '/swagger'
                port: 80
              }
            }
          ]
        }
      ]
      scale:{
        minReplicas: 1
        maxReplicas: 2
      }
    }
  }
}

// I don't need any RBAC (technically)

// module rbacAssign 'rbac.bicep' = {
//   name: 'assignRbacRoles'
//   dependsOn: [ ]
//   params:{
//     userPrincipalId: userPrincipalId
//     containerRegistryName: containerRegistry.name
//     containerAppId: containerApp.id
//     containerAppPrincipalId: containerApp.identity.principalId
//   }
// }

output deployresourceGroupName string = resourceGroup().name

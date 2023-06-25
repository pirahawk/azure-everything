// I am trying to deploy using containr-reg rbac here
// This was inspired by
// https://azureossd.github.io/2023/01/03/Using-Managed-Identity-and-Bicep-to-pull-images-with-Azure-Container-Apps/


param randomSuffix string
param userPrincipalId string
var targetLocation = resourceGroup().location


resource containerManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'containerAppIdentity${randomSuffix}'
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: 'containerreg${randomSuffix}'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
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
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}


resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' = {
  name: 'containerappenv${randomSuffix}'
  location: targetLocation
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

var serverApiContainerImageToUse = '${containerRegistry.properties.loginServer}/azserverapi:latest'

resource serverApiApp 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: 'serverapi${randomSuffix}'
  location: targetLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerManagedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        targetPort: 8080
        external: true
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: containerManagedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          image: serverApiContainerImageToUse
          name: 'myaserverapi'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Development'
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:8080'
            }
            {
              name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
              value: appInsights.properties.InstrumentationKey
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsights.properties.ConnectionString
            }
            {
              name: 'ApiOptions__ItemName'
              value: 'AppServiceItem'
            }
          ]
          probes:[
            {
              httpGet: {
                path: '/health'
                port: 8080
              }
              initialDelaySeconds:5
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}


var clientApiContainerImageToUse = '${containerRegistry.properties.loginServer}/azclientapi:latest'

resource clientApiApp 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: 'clientapi${randomSuffix}'
  location: targetLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerManagedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        targetPort: 8080
        external: true
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: containerManagedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          image: clientApiContainerImageToUse
          name: 'myclientapi'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Development'
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:8080'
            }
            {
              name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
              value: appInsights.properties.InstrumentationKey
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsights.properties.ConnectionString
            }
            {
              name: 'ServerApiOptions__Host'
              value: serverApiApp.properties.configuration.ingress.fqdn
            }
            {
              name: 'ServerApiOptions__Scheme'
              value: 'https'
            }
          ]
          probes:[
            {
              httpGet: {
                path: '/health'
                port: 8080
              }
              initialDelaySeconds:5
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}


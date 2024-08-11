param randomSuffix string
param userPrincipalId string

var targetLocation = resourceGroup().location
var containerImageReference = 'ghcr.io/pirahawk/azure-everything/beaconservice:latest'


resource containerManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'containerAppIdentity${randomSuffix}'
  location: targetLocation
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
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

resource beaconone 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: 'beaconone${randomSuffix}'
  location: targetLocation
  dependsOn: [
  ]
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
        transport:'auto'
      }
      // registries: [
      //   {
      //     server: containerRegistry.properties.loginServer
      //     identity: containerManagedIdentity.id
      //   }
      // ]
      // dapr:{
      //   enabled: true
      //   appId: 'azisddaprserver'
      //   appProtocol: 'http'
      //   appPort: 8080
      //   enableApiLogging: true
      //   logLevel: 'debug'
      // }
    }
    template: {
      containers: [
        {
          image: containerImageReference
          name: 'beaconserviceone'
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
            {
              name: 'ServiceName'
              value: 'Beacon Service One'
            }
            {
              name: 'ApiEndPoints__0'
              value: 'https://google.com'
            }
            {
              name: 'ApiEndPoints__1'
              value: 'https://google.com'
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
        maxReplicas: 2
      }
    }
  }
}


resource beacontwo 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: 'beacontwo${randomSuffix}'
  location: targetLocation
  dependsOn: [
  ]
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
        transport:'auto'
      }
    }
    template: {
      containers: [
        {
          image: containerImageReference
          name: 'beaconservicetwo'
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
              name: 'ServiceName'
              value: 'Beacon Service Two'
            }
            {
              name: 'ApiEndPoints__0'
              value: 'https://${beaconone.properties.configuration.ingress.fqdn}'
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
        maxReplicas: 2
      }
    }
  }
}

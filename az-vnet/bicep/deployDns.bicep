param randomSuffix string
param userPrincipalId string
param containerAppDefaultDomain string

var targetLocation = resourceGroup().location

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


resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2022-11-01-preview' existing = {
  name: 'containerappenv${randomSuffix}'
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: containerAppDefaultDomain
  location: 'global' // These need to be global because Azure DNS is a global resource. Will get errors if anything else

  resource privateDnsVnetLink 'virtualNetworkLinks@2020-06-01' = {
    name: 'vnetdnslink${randomSuffix}'
    location: 'global' // These need to be global because Azure DNS is a global resource
    properties:{
      registrationEnabled: true
      virtualNetwork: {
        id: vnetLab.id
      }
    }
  }

  resource containerappArecod 'A@2020-06-01' = {
    name: '*'  // The "*" here implies "*.${containerAppDefaultDomain}"
    properties:{
      ttl: 3600
      aRecords:[
        {
          ipv4Address:containerAppEnvironment.properties.staticIp   // Am pointing the record to the static IP of the Contaier App Env. It will set up its own forwarding to load balancers which then in turn ping the container apps im targeting.
        }
      ]
    }
  }
}

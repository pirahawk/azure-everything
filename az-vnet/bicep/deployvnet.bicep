param randomSuffix string
param userPrincipalId string
param shouldDeploySubnet bool

var targetLocation = resourceGroup().location

resource vmsubnetnsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'vmsubnetnsg${randomSuffix}'
  location: resourceGroup().location

  resource nsgallowsshrule 'securityRules@2023-05-01' = {
    name: 'nsgallowsshrule'
    properties:{
      access: 'Allow'
      protocol:'Tcp'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '22'
      priority: 1000
    }
  }

  resource nsgallowhttprule 'securityRules@2023-05-01' = {
    name: 'nsgallowhttprule'
    properties:{
      access: 'Allow'
      protocol:'Tcp'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '80'
      priority: 1001
    }
  }
}

resource appsubnetnsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'appsubnetnsg${randomSuffix}'
  location: resourceGroup().location
}


resource vnetLab 'Microsoft.Network/virtualNetworks@2023-05-01' = if(shouldDeploySubnet) {
  name: 'vnet${randomSuffix}'
  location: resourceGroup().location
  properties:{
    addressSpace:{
      addressPrefixes:[
        '192.168.0.0/16'
      ]
    }
  }

  // Note: Use https://www.davidc.net/sites/default/subnets/subnets.html to calculate the subnet address prefixes to make sure the subnets IP's don't overlap otherwise Azure deployment will Fail.

  resource vmsubnet 'subnets@2023-05-01' = if(shouldDeploySubnet) {
    name: 'vmsubnet'
    properties:{
      addressPrefix:'192.168.0.0/27'
      networkSecurityGroup: {
        id: vmsubnetnsg.id
        location: vmsubnetnsg.location
      }
    }
  }

  resource appsubnet 'subnets@2023-05-01' = if(shouldDeploySubnet) {
    name: 'appsubnet'
    properties:{
      addressPrefix:'192.168.0.32/27'
      networkSecurityGroup: {
        id: appsubnetnsg.id
        location: appsubnetnsg.location
      }
    }
  }
}

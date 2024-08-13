param randomSuffix string
param userPrincipalId string
param sshPublicKey string

var shouldDeploySubnet = true
var targetLocation = resourceGroup().location
var containerImageReference = 'ghcr.io/pirahawk/azure-everything/beaconservice:latest'


resource vmsshkey 'Microsoft.Compute/sshPublicKeys@2024-03-01' = {
  name: 'vmsshkey${randomSuffix}'
  location: targetLocation
  properties: {
    publicKey: sshPublicKey
  }
}

resource vmpublicip 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'vmpublicIp${randomSuffix}'
  location: resourceGroup().location
  sku:{
    name: 'Standard'
    tier: 'Regional'
  }
  properties:{
    publicIPAllocationMethod: 'Static'
  }
}

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

  resource vmsubnet 'subnets@2023-05-01' = if(shouldDeploySubnet) {
    name: 'vmsubnet'
    properties:{
      addressPrefix:'192.168.1.0/28'
      networkSecurityGroup: {
        id: vmsubnetnsg.id
        location: vmsubnetnsg.location
      }
    }
  }

  resource appsubnet 'subnets@2023-05-01' = if(shouldDeploySubnet) {
    name: 'appsubnet'
    properties:{
      addressPrefix:'192.168.1.0/28'
      networkSecurityGroup: {
        id: appsubnetnsg.id
        location: appsubnetnsg.location
      }
    }
  }
}

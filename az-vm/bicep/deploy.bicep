param randomSuffix string
param userPrincipalId string
param shouldDeploySubnet bool

var tenantId = subscription().tenantId

// module rbacAssign 'rbac.bicep' = {
//   name: 'assignRbacRoles'
//   dependsOn: [ ]
//   params:{
//     userPrincipalId: userPrincipalId
//   }
// }

// output deployresourceGroupName string = resourceGroup().name

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

  // There is a weird issue with Subnets - https://github.com/Azure/azure-quickstart-templates/issues/2786
  // If the subnet has already been deployed, don't redeploy the vnet, because for some reason it tries to recreate the subnet (known issue)
  // This is why I needed to do all the work to figure out the "If" condition variable "shouldDeploySubnet" (see the calling ps script as well).
resource vnetNew 'Microsoft.Network/virtualNetworks@2023-05-01' = if(shouldDeploySubnet) {
  name: 'vnet${randomSuffix}'
  location: resourceGroup().location
  properties:{
    addressSpace:{
      addressPrefixes:[
        '192.168.0.0/16'
      ]
    }
  }

  resource mainsubnet 'subnets@2023-05-01' = if(shouldDeploySubnet) {
    name: 'vmsubnetmain'
    properties:{
      addressPrefix:'192.168.1.0/24'

    }
  }
}

// Required to follow this pattern because of the weirdness above
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing =  {
  name: 'vnet${randomSuffix}'
}

resource mainsubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: 'vmsubnetmain'
  parent: vnet // This was a little weird, It can't identify the subnet by itself without the parent reference, otherwise I need to fiddle with the name to be in some specific format.
}

resource vnetnsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg${randomSuffix}'
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

resource vmnic 'Microsoft.Network/networkInterfaces@2023-05-01'= {
  name: 'vmnic${randomSuffix}'
  location: resourceGroup().location
  properties:{
    nicType: 'Standard'
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    disableTcpStateTracking: false
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
    
    networkSecurityGroup:{
      id: vnetnsg.id
    }
    
    ipConfigurations:[
      {
        name: 'vmpublicIp'
        properties: {
          primary: true
          privateIPAddressVersion: 'IPv4'

          publicIPAddress: {
            id: vmpublicip.id
            properties:{
              deleteOption: 'Detach'
            }
          }
          subnet:{
            id: mainsubnet.id //vnet.properties.subnets[0].id //mainsubnet.id
            properties:{

            }
          }
        }
      }
    ]
  }
}

resource vmavailabilityset 'Microsoft.Compute/availabilitySets@2023-07-01' = {
  name: 'vmavailibilityset${randomSuffix}'
  location: resourceGroup().location

  properties:{
    platformFaultDomainCount: 1
    platformUpdateDomainCount: 1
  }
}

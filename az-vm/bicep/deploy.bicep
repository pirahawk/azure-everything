param randomSuffix string
param userPrincipalId string
param shouldDeploySubnet bool
param vmName string
param vmUserName string
param sshKeyName string

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
      networkSecurityGroup: {
        id: vnetnsg.id
        location: vnetnsg.location
      }
    }
  }
}
//// NOTE: I have found that the following will fail because sometime it takes a while to provision the vnet and subnet. If so, just comment out the below and redeploy first to ensure it exists.

// Required to follow this pattern because of the weirdness above
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing =  {
  name: 'vnet${randomSuffix}'
}

resource mainsubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: 'vmsubnetmain'
  parent: vnet // This was a little weird, It can't identify the subnet by itself without the parent reference, otherwise I need to fiddle with the name to be in some specific format.
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


// So it looks like you need to pre-proviosion the SSH public key via AZ CLI (can't work out if this can be done via bicep atm)
resource vmsshkey 'Microsoft.Compute/sshPublicKeys@2023-09-01' existing = {
  name: sshKeyName
}

// literally took all of this from an example template.
// Also see https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-bicep?tabs=CLI#review-the-bicep-file
resource linuxvm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'nixvm${randomSuffix}'
  location: resourceGroup().location
  properties:{
    hardwareProfile:{
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile:{
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmnic.id
          properties: {
            deleteOption: 'Detach'
          }
        }
      ]
    }
    availabilitySet: {
      id: vmavailabilityset.id
    }

    additionalCapabilities: {
      hibernationEnabled: false
      ultraSSDEnabled: false
    }

    osProfile: {
      computerName: vmName
      adminUsername: vmUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${vmUserName}/.ssh/authorized_keys'
              keyData: vmsshkey.properties.publicKey
            }
          ]
        }
      }
    }

    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  zones: [
    '1'
  ]
}

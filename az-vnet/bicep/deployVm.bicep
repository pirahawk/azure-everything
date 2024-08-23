param randomSuffix string
param userPrincipalId string
param sshPublicKey string

var targetLocation = resourceGroup().location
var vmName = 'testlinuxvm'
var vmUserName = 'testuser'

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

resource vmsubnetnsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' existing = {
  name: 'vmsubnetnsg${randomSuffix}'
}

resource vnetLab 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: 'vnet${randomSuffix}'
}

resource vmsubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: 'vmsubnet'
  parent: vnetLab
}

resource vmnic 'Microsoft.Network/networkInterfaces@2023-05-01'= {
  name: 'vmnic${randomSuffix}'
  location: resourceGroup().location
  dependsOn:[
    vmsshkey
    vmpublicip
  ]
  properties:{
    nicType: 'Standard'
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    disableTcpStateTracking: false
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
    
    networkSecurityGroup:{
      id: vmsubnetnsg.id
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
            id: vmsubnet.id //vnet.properties.subnets[0].id //mainsubnet.id
            properties:{

            }
          }
        }
      }
    ]
  }
}

// Note to self: something weird going on here where I need to understand a vm availibility set VS availability zone.
// Have disabled this in definitions below, not sure i need it now but got some weird errors.


// resource vmavailabilityset 'Microsoft.Compute/availabilitySets@2023-07-01' = {
//   name: 'vmavailibilityset${randomSuffix}'
//   location: resourceGroup().location
  
//   properties:{
//     platformFaultDomainCount: 1
//     platformUpdateDomainCount: 1
    
//   }
// }

resource linuxvm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'nixvm${randomSuffix}'
  dependsOn:[
    vmsshkey
    vmpublicip
    vmnic
  ]
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
    // availabilitySet: {
    //   id: vmavailabilityset.id
    // }

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
  // zones: [
  //   '1'
  // ]
}

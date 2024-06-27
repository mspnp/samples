param adminUserName string

@secure()
param adminPassword string
param mocOnpremNetwork object = {
  name: 'vnet-onprem'
  addressPrefix: '192.168.0.0/16'
  subnetName: 'mgmt'
  subnetPrefix: '192.168.1.128/25'
}
param mocOnpremGateway object = {
  name: 'vpn-mock-prem'
  subnetName: 'GatewaySubnet'
  subnetPrefix: '192.168.255.224/27'
  publicIPAddressName: 'pip-onprem-vpn-gateway'
}
param bastionHost object = {
  name: 'AzureBastionHost'
  subnetName: 'AzureBastionSubnet'
  subnetPrefix: '192.168.254.0/27'
  publicIPAddressName: 'pip-bastion'
  nsgName: 'nsg-hub-bastion'
}
param vmSize string = 'Standard_A1_v2'
param configureSitetosite bool = true
param location string  = resourceGroup().location

var nicNameWindowsName = 'nic-windows'
var vmNameWindowsName = 'vm-windows'
var windowsOSVersion = '2016-Datacenter'

resource mocOnpremNetworkResource 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: mocOnpremNetwork.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        mocOnpremNetwork.addressPrefix
      ]
    }
    subnets: [
      {
        name: mocOnpremNetwork.subnetName
        properties: {
          addressPrefix: mocOnpremNetwork.subnetPrefix
        }
      }
      {
        name: mocOnpremGateway.subnetName
        properties: {
          addressPrefix: mocOnpremGateway.subnetPrefix
        }
      }
      {
        name: bastionHost.subnetName
        properties: {
          addressPrefix: bastionHost.subnetPrefix
        }
      }
    ]
  }
}

resource mocOnpremGateway_publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-11-01' = if (configureSitetosite) {
  name: mocOnpremGateway.publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource mocOnpremGatewayResource 'Microsoft.Network/virtualNetworkGateways@2023-11-01' = if (configureSitetosite) {
  name: mocOnpremGateway.name
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', mocOnpremNetworkResource.name, mocOnpremGateway.subnetName)
          }
          publicIPAddress: {
            id: mocOnpremGateway_publicIPAddress.id
          }
        }
        name: 'vnetGatewayConfig'
      }
    ]
    sku: {
      name: 'VpnGw2'
      tier: 'VpnGw2'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    bgpSettings: {
      asn: 65001
    }
  }
}

resource bastionHost_publicIPAddress 'Microsoft.Network/publicIpAddresses@2023-04-01' = {
  name: bastionHost.publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost_nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: bastionHost.nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'bastion-in-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'bastion-control-in-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'bastion-in-host'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'bastion-vnet-out-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'bastion-azure-out-allow'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'bastion-out-host'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'bastion-out-deny'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource bastionHostResource 'Microsoft.Network/bastionHosts@2023-04-01' = {
  name: bastionHost.name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', mocOnpremNetworkResource.name, bastionHost.subnetName)
          }
          publicIPAddress: {
            id: bastionHost_publicIPAddress.id
          }
        }
      }
    ]
  }
}

resource nicNameWindows 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: nicNameWindowsName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', mocOnpremNetworkResource.name, mocOnpremNetwork.subnetName)
          }
        }
      }
    ]
  }
}

resource vmNameWindows 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmNameWindowsName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmNameWindowsName
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicNameWindows.id
        }
      ]
    }
  }
}

output vpnIp string = mocOnpremGatewayResource.properties.bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]
output mocOnpremNetworkPrefix string = mocOnpremNetwork.addressPrefix
output mocOnpremGatewayName string = mocOnpremGateway.name

param windowsVMCount int = 1
param linuxVMCount int = 1
param adminUserName string = 'azureadmin'
param adminPassword string
param vmSize string = 'Standard_A1_v2'

param hubNetwork object = {
  name: 'vnet-hub'
  addressPrefix: '10.0.0.0/20'
}

param spokeNetwork object = {
  name: 'vnet-spoke-one'
  addressPrefix: '10.100.0.0/16'
  subnetName: 'snet-spoke-resources'
  subnetPrefix: '10.100.0.0/16'
  subnetNsgName: 'nsg-spoke-one-resources'
}

param spokeNetworkTwo object = {
  name: 'vnet-spoke-two'
  addressPrefix: '10.200.0.0/16'
  subnetName: 'snet-spoke-resources'
  subnetPrefix: '10.200.0.0/16'
  subnetNsgName: 'nsg-spoke-two-resources'
}

param azureFirewall object = {
  name: 'AzureFirewall'
  publicIPAddressName: 'pip-firewall'
  subnetName: 'AzureFirewallSubnet'
  subnetPrefix: '10.0.3.0/26'
  routeName: 'r-nexthop-to-fw'
}

param bastionHost object = {
  name: 'AzureBastionHost'
  publicIPAddressName: 'pip-bastion'
  subnetName: 'AzureBastionSubnet'
  nsgName: 'nsg-hub-bastion'
  subnetPrefix: '10.0.1.0/29'
}

param vpnGateway object = {
  name: 'vgw-gateway'
  subnetName: 'GatewaySubnet'
  subnetPrefix: '10.0.2.0/27'
  pipName: 'pip-vgw-gateway'
}

var nicNameWindows_var = 'nic-windows-'
var vmNameWindows_var = 'vm-windows-'
var windowsOSVersion = '2016-Datacenter'
var nicNameLinux_var = 'nic-linux-'
var osVersion = '16.04.0-LTS'
var vmNameLinux_var = 'vm-linux-'
var logAnalyticsWorkspaceName = uniqueString(subscription().subscriptionId, resourceGroup().id)

resource logAnalyticsWrokspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWorkspaceName
  location: 'eastus'
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

resource vnetHub 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: hubNetwork.name
  location: 'eastus'
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubNetwork.addressPrefix
      ]
    }
    subnets: [
      {
        name: azureFirewall.subnetName
        properties: {
          addressPrefix: azureFirewall.subnetPrefix
        }
      }
      {
        name: bastionHost.subnetName
        properties: {
          addressPrefix: bastionHost.subnetPrefix
        }
      }
      {
        name: vpnGateway.subnetName
        properties: {
          addressPrefix: vpnGateway.subnetPrefix
        }
      }
    ]
  }
}

resource diagLogAnalyticsWrokspace 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diag'
  scope: vnetHub
  properties: {
    workspaceId: logAnalyticsWrokspace.id
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
  }
}

resource pipFirewall 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: azureFirewall.publicIPAddressName
  location: 'eastus'
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2020-05-01' = {
  name: azureFirewall.name
  location: 'eastus'
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: azureFirewall.name
        properties: {
          publicIPAddress: {
            id: pipFirewall.id
          }
          subnet: {
            id: '${vnetHub.id}/subnets/${azureFirewall.subnetName}'
          }
        }
      }
    ]
  }
}

resource diagFirewall 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diagFirewall'
  scope: firewall
  properties: {
    workspaceId: logAnalyticsWrokspace.id
    logs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
      }
      {
        category: 'AzureFirewallDnsProxy'
        enabled: true
      }
    ]
  }
}

resource azureFirewallRoutes 'Microsoft.Network/routeTables@2020-05-01' = {
  name: azureFirewall.routeName
  location: 'eastus'
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: azureFirewall.routeName
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: reference(firewall.id, '2020-05-01').ipConfigurations[0].properties.privateIpAddress
        }
      }
    ]
  }
}

resource nsgSpoke 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: spokeNetwork.name
  location: 'eastus'
  properties: {
    securityRules: [
      {
        name: 'bastion-in-vnet'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix:  bastionHost.subnetPrefix
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource diagNsgSpoke 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diagNsgSpoke'
  scope: nsgSpoke
  properties: {
    workspaceId: logAnalyticsWrokspace.id
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
  }
}

resource vnetSpoke 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: spokeNetwork.name
  location: 'eastus'
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeNetwork.addressPrefix
      ]
    }
    subnets: [
      {
        name: spokeNetwork.subnetName
        properties: {
          addressPrefix: spokeNetwork.subnetPrefix
          networkSecurityGroup: {
            id: nsgSpoke.id
          }
        }
      }
    ]
  }
}

resource diagSpoke 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diagNetworkSpoke'
  scope: vnetSpoke
  properties: {
    workspaceId: logAnalyticsWrokspace.id
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
  }
}

resource nsgSpokeTwo 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: spokeNetworkTwo.name
  location: 'eastus'
  properties: {
    securityRules: [
      {
        name: 'bastion-in-vnet'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix:  bastionHost.subnetPrefix
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource diagNsgSpokeTwo 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diagNsgSpokeTwo'
  scope: nsgSpokeTwo
  properties: {
    workspaceId: logAnalyticsWrokspace.id
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
  }
}

resource vnetSpokeTwo 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: spokeNetworkTwo.name
  location: 'eastus'
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeNetworkTwo.addressPrefix
      ]
    }
    subnets: [
      {
        name: spokeNetworkTwo.subnetName
        properties: {
          addressPrefix: spokeNetworkTwo.subnetPrefix
          networkSecurityGroup: {
            id: nsgSpoke.id
          }
        }
      }
    ]
  }
}

resource diagSpokeTwo 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'diagNetworkSpokeTwo'
  scope: vnetSpokeTwo
  properties: {
    workspaceId: logAnalyticsWrokspace.id
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
  }
}

resource peerHubSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-06-01' = {
  name: '${hubNetwork.name}/hub-to-spoke'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetSpoke.id
    }
  }
}

resource peerSpokeHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-06-01' = {
  name: '${vnetSpoke.name}/spoke-to-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
  }
}

resource peerHubSpokeTwo 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-06-01' = {
  name: '${hubNetwork.name}/hub-to-spoke-two'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetSpokeTwo.id
    }
  }
}

resource peerSpokeTwoHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-06-01' = {
  name: '${vnetSpokeTwo.name}/spoke-two-to-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
  }
}

resource bastionpip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: 'bastionpip'
  location: 'eastus'
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nsgbastion 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'nsgbastion'
  location: 'eastus'
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

resource bastionhost 'Microsoft.Network/bastionHosts@2020-06-01' = {
  name: 'bastionhost'
  location: 'eastus'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconf'
        properties: {
          subnet: {
            id: '${vnetHub.id}/subnets/${bastionHost.subnetName}'
          }
          publicIPAddress: {
            id: bastionpip.id
          }
        }
      }
    ]
  }
}

resource nicNameWindows 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, windowsVMCount): {
  name: '${nicNameWindows_var}${i + 1}'
  location: 'eastus'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${vnetSpoke.id}/subnets/${spokeNetwork.subnetName}'
          }
        }
      }
    ]
  }
}]

resource vmNameWindows 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, windowsVMCount): {
  name: '${vmNameWindows_var}${i + 1}'
  location: 'eastus'
  dependsOn:[
    nicNameWindows
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmNameWindows_var
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
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicNameWindows_var}${i + 1}')
        }
      ]
    }
  }
}]

resource nicNameLinux 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, linuxVMCount): {
  name: '${nicNameLinux_var}${i + 1}'
  location: 'eastus'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${vnetSpoke.id}/subnets/${spokeNetwork.subnetName}'
          }
        }
      }
    ]
  }
}]

resource vmNameLinux 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, linuxVMCount): {
  name: '${vmNameLinux_var}${i + 1}'
  location: 'eastus'
  dependsOn:[
    nicNameLinux
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmNameLinux_var
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: osVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicNameLinux_var}${i + 1}')
        }
      ]
    }
  }
}]
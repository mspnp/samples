param adminUserName string = 'azureadmin'

@secure()
param adminPassword string

@description('The count of Windows virtual machines to create.')
param windowsVMCount int = 2
param vmSize string = 'Standard_DS1_v2'
param configureSitetosite bool = true
param hubNetwork object = {
  name: 'vnet-hub'
  addressPrefix: '10.0.0.0/20'
}
param spokeNetwork object = {
  name: 'vnet-spoke'
  addressPrefix: '10.100.0.0/16'
  subnetName: 'snet-spoke-resources'
  subnetPrefix: '10.100.0.0/16'
  subnetNsgName: 'nsg-spoke-resources'
}
param vpnGateway object = {
  name: 'vpn-azure-network'
  subnetName: 'GatewaySubnet'
  subnetPrefix: '10.0.2.0/27'
  publicIPAddressName: 'pip-vgn-gateway'
}
param bastionHost object = {
  name: 'AzureBastionHost'
  subnetName: 'AzureBastionSubnet'
  subnetPrefix: '10.0.1.0/29'
  publicIPAddressName: 'pip-bastion'
  nsgName: 'nsg-hub-bastion'
}
param azureFirewall object = {
  name: 'AzureFirewall'
  subnetName: 'AzureFirewallSubnet'
  subnetPrefix: '10.0.3.0/26'
  publicIPAddressName: 'pip-firewall'
}
param spokeRoutes object = {
  tableName: 'spoke-routes'
  routeNameFirewall: 'spoke-to-firewall'
}
param gatewayRoutes object = {
  tableName: 'gateway-routes'
  routeNameFirewall: 'gateway-to-firewall'
}
param internalLoadBalancer object = {
  name: 'lb-internal'
  backendName: 'lb-backend'
  fontendName: 'lb-frontend'
  probeName: 'lb-probe'
}
param location string = resourceGroup().location

var logAnalyticsWorkspaceName = 'la-${uniqueString(subscription().subscriptionId, resourceGroup().id)}'
var nicNameWebName = 'nic-web-server'
var vmNameWebName = 'vm-web-server'
var windowsOSVersion = '2022-datacenter-g2'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    features: {
      searchVersion: 1
    }
  }
}

resource gatewayRoutes_table 'Microsoft.Network/routeTables@2023-04-01' = {
  name: gatewayRoutes.tableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}

resource spokeRoutes_table 'Microsoft.Network/routeTables@2023-04-01' = {
  name: spokeRoutes.tableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
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

resource hubNetworkResource 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: hubNetwork.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubNetwork.addressPrefix
      ]
    }
    subnets: [
      {
        name: vpnGateway.subnetName
        properties: {
          addressPrefix: vpnGateway.subnetPrefix
          routeTable: {
            id: gatewayRoutes_table.id
          }
        }
      }
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
          networkSecurityGroup: {
            id: bastionHost_nsg.id
          }
        }
      }
    ]
  }
}

resource hubNetwork_name_Microsoft_Insights_default_logAnalyticsWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: hubNetworkResource
  name: logAnalyticsWorkspaceName
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource spokeNetwork_subnetNsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: spokeNetwork.subnetNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-http-traffic-from-external'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-http-traffic-from-vnet'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '10.0.0.0/16'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource spokeNetworkResource 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: spokeNetwork.name
  location: location
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
          addressPrefix: spokeNetwork.addressPrefix
          networkSecurityGroup: {
            id: spokeNetwork_subnetNsg.id
          }
          routeTable: {
            id: spokeRoutes_table.id
          }
        }
      }
    ]
  }
}

resource bastionHost_nsgName_Microsoft_Insights_default_logAnalyticsWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: bastionHost_nsg
  name: logAnalyticsWorkspaceName
  properties: {
    workspaceId: logAnalyticsWorkspace.id
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

resource bastionHost_publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: bastionHost.publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubNetworkResource.name, bastionHost.subnetName)
          }
          publicIPAddress: {
            id: bastionHost_publicIPAddress.id
          }
        }
      }
    ]
  }
}

resource spokeNetwork_name_Microsoft_Insights_default_logAnalyticsWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: spokeNetworkResource
  name: logAnalyticsWorkspaceName
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource vpnGateway_publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-11-01' = if (configureSitetosite) {
  name: vpnGateway.publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vpnGatewayResource 'Microsoft.Network/virtualNetworkGateways@2023-11-01' = if (configureSitetosite) {
  name: vpnGateway.name
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubNetworkResource.name, vpnGateway.subnetName)
          }
          publicIPAddress: {
            id: vpnGateway_publicIPAddress.id
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

resource vpnGatewayResource_Microsoft_Insights_default_logAnalyticsWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (configureSitetosite) {
  scope: vpnGatewayResource
  name: logAnalyticsWorkspaceName
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'GatewayDiagnosticLog'
        enabled: true
      }
      {
        category: 'TunnelDiagnosticLog'
        enabled: true
      }
      {
        category: 'RouteDiagnosticLog'
        enabled: true
      }
      {
        category: 'IKEDiagnosticLog'
        enabled: true
      }
      {
        category: 'P2SDiagnosticLog'
        enabled: true
      }
    ]
  }
}

resource azureFirewall_publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: azureFirewall.publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource azureFirewallResource 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: azureFirewall.name
  location: location
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
            id: azureFirewall_publicIPAddress.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubNetworkResource.name, azureFirewall.subnetName)
          }
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'spoke-outbound'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'all-internet'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                '*'
              ]
              sourceAddresses: [
                '*'
              ]
            }
          ]
        }
      }
    ]
  }
}

resource azureFirewallResource_Microsoft_Insights_default_logAnalyticsWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: azureFirewallResource
  name: logAnalyticsWorkspaceName
  properties: {
    workspaceId: logAnalyticsWorkspace.id
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

resource spokeNetwork_subnetNsgName_Microsoft_Insights_default_logAnalyticsWorkspace 'Microsoft.Network/networkSecurityGroups/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${spokeNetwork.subnetNsgName}/Microsoft.Insights/default${logAnalyticsWorkspaceName}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
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
  dependsOn: [
    spokeNetwork_subnetNsg

  ]
}

resource internalLoadBalancerResource 'Microsoft.Network/loadBalancers@2023-04-01' = {
  name: internalLoadBalancer.name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: internalLoadBalancer.fontendName
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', spokeNetworkResource.name, spokeNetwork.subnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    backendAddressPools: [
      {
        name: internalLoadBalancer.backendName
      }
    ]
    loadBalancingRules: [
      {
        name: internalLoadBalancer.probeName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', internalLoadBalancer.name, internalLoadBalancer.fontendName)
          }
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'Tcp'
          enableTcpReset: false
          loadDistribution: 'Default'
          disableOutboundSnat: false
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', internalLoadBalancer.name, internalLoadBalancer.backendName)
          }
          probe: {
            id: '${resourceId('Microsoft.Network/loadBalancers', internalLoadBalancer.name)}/probes/${internalLoadBalancer.probeName}'
          }
        }
      }
    ]
    probes: [
      {
        name: internalLoadBalancer.probeName
        properties: {
          protocol: 'Http'
          port: 80
          requestPath: '/'
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource internalLoadBalancer_name_Microsoft_Insights_default_logAnalyticsWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: internalLoadBalancerResource
  name: logAnalyticsWorkspaceName
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource gatewayRoutes_tableName_gatewayRoutes_routeNameFirewall 'Microsoft.Network/routeTables/routes@2023-04-01' = {
  parent: gatewayRoutes_table
  name: gatewayRoutes.routeNameFirewall
  properties: {
    addressPrefix: spokeNetwork.addressPrefix
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: reference(azureFirewallResource.id, '2020-05-01').ipConfigurations[0].properties.privateIpAddress
  }
}

resource spokeRoutes_tableName_spokeRoutes_routeNameFirewall 'Microsoft.Network/routeTables/routes@2020-07-01' = {
  parent: spokeRoutes_table
  name: spokeRoutes.routeNameFirewall
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: reference(azureFirewallResource.id, '2020-05-01').ipConfigurations[0].properties.privateIpAddress
  }
}

resource nicNameWeb 'Microsoft.Network/networkInterfaces@2023-04-01' = [for i in range(0, windowsVMCount): {
  name: '${nicNameWebName}${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', spokeNetworkResource.name, spokeNetwork.subnetName)
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', internalLoadBalancer.name, internalLoadBalancer.backendName)
            }
          ]
        }
      }
    ]
  }
  dependsOn:[
    internalLoadBalancerResource]
}]

resource vmNameWeb 'Microsoft.Compute/virtualMachines@2023-03-01' = [for i in range(0, windowsVMCount): {
  name: '${vmNameWebName}${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${vmNameWebName}${i}'
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
          id: nicNameWeb[i].id
        }
      ]
    }
  }}]

resource vmNameWeb_installIIS 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = [for i in range(0, windowsVMCount): {
  name: '${vmNameWebName}${i}/installIIS'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.7'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools'
    }
  }
  dependsOn: [
    vmNameWeb[i]
  ]
}]


output vpnIp string = vpnGatewayResource.properties.bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]
output mocOnpremNetwork string = hubNetwork.addressPrefix
output spokeNetworkAddressPrefix string = spokeNetwork.addressPrefix
output azureGatewayName string = vpnGateway.name


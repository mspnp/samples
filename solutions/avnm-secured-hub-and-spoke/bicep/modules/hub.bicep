/*** PARAMETERS ***/
@description('the location where hub resources will deployed. It includes a Log Analytics Workspace, a VNet, and a VPN Gateway.')
param location string = resourceGroup().location

/*** RESOURCES ***/

@description('This Log Analyics Workspace stores logs from the regional hub network, its spokes, and other related resources. Workspaces are regional resource, as such there would be one workspace per hub (region)')
resource laHub 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'la-hub-${location}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    forceCmkForQuery: false
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      disableLocalAuth: false
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
  }
}

resource laHub_diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-hub-la'
  scope: laHub
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
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

@description('The regional hub network.')
resource vnetHub 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-learn-hub-${location}-001'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.3.0/26'
        }
      }
      {
        name: 'AzureFirewallManagementSubnet'
        properties: {
          addressPrefix: '10.0.3.64/26'
        }
      }
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.3.128/25'
        }
      }
    ]
  }
  resource azureFirewallSubnet 'subnets' existing = {
    name: 'AzureFirewallSubnet'
  }
}

resource vnetHub_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-hub-la'
  scope: vnetHub
  properties: {
    workspaceId: laHub.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource snetGateway 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: 'GatewaySubnet'
  parent: vnetHub
  properties: {
    addressPrefix: '10.0.2.0/27'
  }
}

@description('The public IPs for the regional VPN gateway.')
resource pipVpnGateway 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-learn-hub-${location}-vngw001'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

resource pipVpnGateway_diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-hub-la'
  scope: pipVpnGateway
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
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

@description('The is the regional VPN gateway, configured with basic settings.')
resource vgwHub 'Microsoft.Network/virtualNetworkGateways@2024-05-01' =  {
  name: 'vgw-learn-hub-${location}-001'
  location: location
  properties: {
    sku: {
      name: 'VpnGw2AZ'
      tier: 'VpnGw2AZ'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation2'
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipVpnGateway.id
          }
          subnet: {
            id: snetGateway.id
          }
        }
      }
    ]
  }
}

resource vgwHub_diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' =  {
  name: 'to-hub-la'
  scope: vgwHub
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
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

// Allocate three IP addresses to the firewall
var numFirewallIpAddressesToAssign = 1
resource pipsAzureFirewall 'Microsoft.Network/publicIPAddresses@2024-05-01' = [for i in range(0, numFirewallIpAddressesToAssign): {
  name: 'pip-fw-${location}-${padLeft(i, 2, '0')}'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}]

resource pipsAzureFirewall_diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for i in range(0, numFirewallIpAddressesToAssign): {
  name: 'to-hub-la'
  scope: pipsAzureFirewall[i]
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
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
}]

@description('Azure Firewall Policy')
resource fwPolicy 'Microsoft.Network/firewallPolicies@2024-05-01' = {
  name: 'fw-policies-${location}'
  location: location
  properties: {
    sku: {
      tier: 'Basic'
    }
    insights: {
      isEnabled: true
      retentionDays: 30
      logAnalyticsResources: {
        defaultWorkspaceId: {
          id: laHub.id
        }
      }
    }
    intrusionDetection: null // Only valid on Premium tier sku
  }

  // This network hub starts out with only supporting external DNS queries. This is only being done for
  // simplicity in this deployment and is not guidance, please ensure all firewall rules are aligned with
  // your security standards.
  resource defaultNetworkRuleCollectionGroup 'ruleCollectionGroups@2024-05-01' = {
    name: 'DefaultNetworkRuleCollectionGroup'
    properties: {
      priority: 200
      ruleCollections: [
        {
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          name: 'org-wide-allowed'
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              ruleType: 'NetworkRule'
              name: 'DNS'
              description: 'Allow DNS outbound (for simplicity, adjust as needed)'
              ipProtocols: [
                'UDP'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
              destinationAddresses: [
                '*'
              ]
              destinationIpGroups: []
              destinationFqdns: []
              destinationPorts: [
                '53'
              ]
            }
          ]
        }
      ]
    }
  }

  // Network hub starts out with no allowances for appliction rules
  resource defaultApplicationRuleCollectionGroup 'ruleCollectionGroups@2024-05-01' = {
    name: 'DefaultApplicationRuleCollectionGroup'
    dependsOn: [
      defaultNetworkRuleCollectionGroup
    ]
    properties: {
      priority: 300
      ruleCollections: [
        {
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          name: 'org-wide-allowed'
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: []
        }
      ]
    }
  }
}

@description('This is the regional Azure Firewall that all regional spoke networks can egress through.')
resource fwHub 'Microsoft.Network/azureFirewalls@2024-05-01' = {
  name: 'fw-${location}'
  location: location
  zones: [
    '1'
    '2'
    '3'
  ]
  dependsOn: [
    // This helps prevent multiple PUT updates happening to the firewall causing a CONFLICT race condition
    // Ref: https://learn.microsoft.com/azure/firewall-manager/quick-firewall-policy
    fwPolicy::defaultApplicationRuleCollectionGroup
    fwPolicy::defaultNetworkRuleCollectionGroup
  ]
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    firewallPolicy: {
      id: fwPolicy.id
    }
    ipConfigurations: [for i in range(0, numFirewallIpAddressesToAssign): {
      name: pipsAzureFirewall[i].name
      properties: {
        subnet: (0 == i) ? {
          id: vnetHub::azureFirewallSubnet.id
        } : null
        publicIPAddress: {
          id: pipsAzureFirewall[i].id
        }
      }
    }]
  }
}

resource fwHub_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-hub-la'
  scope: fwHub
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
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

@description('Next hop to the regional hub\'s Azure Firewall')
resource rt_nextHopToFirewall 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'rt-to-hub-fw-${location}'
  location: location
  properties: {
    routes: [
      {
        name: 'r-nexthop-to-fw'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: fwHub.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

output hubVnetId string = vnetHub.id
output logAnalyticsWorkspaceId string = laHub.id
output firewall object = fwHub
output routeNextHopToFirewall string =  rt_nextHopToFirewall.id

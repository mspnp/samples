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
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

@description('The is the regional VPN gateway, configured with basic settings.')
resource vgwHub 'Microsoft.Network/virtualNetworkGateways@2024-05-01' =  {
  name: 'vgw-learn-hub-${location}-001'
  location: location
  properties: {
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation1'
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

output hubVnetId string = vnetHub.id
output logAnalyticsWorkspaceId string = laHub.id

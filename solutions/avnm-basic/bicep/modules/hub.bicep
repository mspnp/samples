param location string
param connectivityTopology string

@description('The regional hub network.')
resource vnetHub 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: 'vnet-learn-hub-${location}-001'
  location: location
  // add tag to include hub vnet in the connected group mesh only when connectivity topology is 'mesh'
  tags: (connectivityTopology == 'mesh') ? {
    _avnm_quickstart_deployment: 'hub'
  } : {}
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

resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' = {
  name: 'GatewaySubnet'
  parent: vnetHub
  properties: {
    addressPrefix: '10.0.2.0/27'
  }
}

@description('The public IPs for the regional VPN gateway.')
resource pipVpnGateway 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
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

@description('The is the regional VPN gateway, configured with basic settings.')
resource vgwHub 'Microsoft.Network/virtualNetworkGateways@2022-01-01' =  {
  name: 'gw-learn-hub-${location}-001'
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
            id: gatewaySubnet.id
          }
        }
      }
    ]
  }
}

output hubVnetId string = vnetHub.id

// Once an on-premises site joins the network, this template updates the hub
// firewall with a DNAT rule so inbound traffic can reach the spoke workloads.

param location string = resourceGroup().location

@description('Name of the Azure Firewall')
param firewallName string

@description('Private IP address of the firewall')
param firewallPrivateIp string

@description('Private IP address of the internal load balancer')
param internalLoadBalancerPrivateIp string

@description('Name of the hub virtual network')
param hubVnetName string = 'vnet-hub'

@description('Name of the firewall public IP')
param firewallPublicIpName string = 'pip-firewall'

@description('Spoke network address prefix for source filtering')
param spokeAddressPrefix string = '10.100.0.0/16'

resource hubVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: hubVnetName
}

resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' existing = {
  name: firewallPublicIpName
}

resource firewallDnat 'Microsoft.Network/azureFirewalls@2024-05-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: firewallName
        properties: {
          publicIPAddress: {
            id: firewallPublicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnet.name, 'AzureFirewallSubnet')
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
              name: 'windows-update'
              protocols: [
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                '*.update.microsoft.com'
                '*.windowsupdate.com'
                '*.download.windowsupdate.com'
              ]
              sourceAddresses: [
                spokeAddressPrefix
              ]
            }
          ]
        }
      }
    ]
    natRuleCollections: [
      {
        name: 'dnat-onprem-to-spoke'
        properties: {
          priority: 100
          action: {
            type: 'Dnat'
          }
          rules: [
            {
              name: 'onprem-to-web'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '192.168.0.0/16'
              ]
              destinationAddresses: [
                firewallPrivateIp
              ]
              destinationPorts: [
                '80'
              ]
              translatedAddress: internalLoadBalancerPrivateIp
              translatedPort: '80'
            }
          ]
        }
      }
    ]
  }
}

param location string
param routeTableId string
param logAnalyticsWorkspaceId string
param deployVirtualMachines bool
param adminUsername string
param spokeName string 
param spokeVnetPrefix string
param nsgResourcesSubnetId string
param nsgPrivateLinkEndpointsSubnetId string
@secure()
param adminPassword string

// Azure DDoS Protection Standard should be enabled
resource ddosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@2021-05-01'  existing = {
  name: 'vnet-${location}-ddos'
}

resource hubNet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: 'vnet-${location}-hub'

  resource azureBastionSubnet 'subnets' existing = {
    name: 'AzureBastionSubnet'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'vnet-${location}-spoke-${spokeName}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnetPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-resources'
        properties: {
          addressPrefix: replace(spokeVnetPrefix, '.0.0/22','.0.0/24')
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: nsgResourcesSubnetId
          }
          routeTable: {
            id: routeTableId
          }
        }
      }
      {
        name: 'snet-privatelinkendpoints'
        properties: {
          addressPrefix: replace(spokeVnetPrefix, '.0.0/22','.1.0/26')
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: nsgPrivateLinkEndpointsSubnetId
          }
          routeTable: {
            id: routeTableId
          }
        }
      }
    ]
    enableDdosProtection: true
    ddosProtectionPlan: {
      id: ddosProtectionPlan.id
    }
  }

  resource snetResources 'subnets' existing = {
    name: 'snet-resources'
  }
}

resource vnet_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: vnet
  name: 'to-hub-la'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('The private Network Interface Card for the Windows VM in spoke.')
resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = if (deployVirtualMachines) {
  name: 'nic-vm-${location}-${spokeName}-ubuntu'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: vnet::snetResources.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}

resource nic_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployVirtualMachines) {
  scope: nic
  name: 'to-hub-la'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('A basic Ubuntu Linux virtual machine that will be attached to spoke.')
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = if (deployVirtualMachines) {
  name: 'vm-${location}-spoke-${spokeName}-ubuntu'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      dataDisks: []
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: null
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Delete'
            primary: true
          }
        }
      ]
    }
    osProfile: {
      computerName: 'examplevm'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
    }
    priority: 'Regular'
  }
}

output vnetId string = vnet.id

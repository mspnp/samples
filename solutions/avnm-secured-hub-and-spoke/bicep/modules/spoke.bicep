/*** PARAMETERS ***/

@description('All resources will be deployed to this region.')
param location string = resourceGroup().location

@description('Short name to identify the spoke.')
param spokeName string

@description('VNet address prefix for the spoke.')
param spokeVnetPrefix string

@description('The Log Analytics Workspace ID to which the spoke will send its logs.')
param logAnalyticsWorkspaceId string

@description('The public SSH key to be used for the VM in the spoke.')
param sshKey string

@description('Username for the test VMs deployed in the spokes; default: admin-avnm')
param adminUsername string = 'admin-avnm'

@description('The route table ID to define the next hop for the spoke.')
param routeTableId string

/*** RESOURCES ***/

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-learn-prod-${location}-${toLower(spokeName)}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnetPrefix
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: replace(spokeVnetPrefix, '.0.0/22', '.1.0/24')
          routeTable: {
            id: routeTableId
          }
        }
      }
    ]
  }
}

resource vnet_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: vnet
  name: 'vnet-to-hub-la'
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
resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-learn-prod-${location}-${spokeName}-ubuntu'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}

resource nic_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: nic
  name: 'mic-to-hub-la'
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
resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: 'vm-learn-prod-${location}-${spokeName}-ubuntu'
  location: location
  identity: {
    // It is required by the Guest Configuration extension.
    type: 'SystemAssigned'
  }
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
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshKey
            }
          ]
        }
        patchSettings: {
          //Machines should be configured to periodically check for missing system updates
          assessmentMode: 'AutomaticByPlatform'
          patchMode: 'AutomaticByPlatform'
        }
        provisionVMAgent: true
      }
    }
    securityProfile: {
      // We recommend enabling encryption at host for virtual machines and virtual machine scale sets to harden security.
      encryptionAtHost: false
    }
    priority: 'Regular'
  }
}

// The Guest Configuration extension supports Azure governance at cloud scale, and can be installed after ensuring that a system-assigned identity is added at the VM level. This enable Azure policies to audit and report on configuration settings inside machines.
@description('Install the Guest Configuration extension for Azure auto-manage machine configuration on top regulatory, security, and operational compliance.')
resource vmGuestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: vm
  name: 'Microsoft.GuestConfiguration'
  location: location
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforLinux' // Use 'ConfigurationforWindows' if it's a Windows VM
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {}
    protectedSettings: {}
  }
}

output vnetId string = vnet.id

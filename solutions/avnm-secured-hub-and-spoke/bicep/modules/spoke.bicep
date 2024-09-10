param location string = resourceGroup().location
param spokeName string
param spokeVnetPrefix string
@secure()
param adminPassword string
param adminUsername string = 'admin-avnm'

var protectionContainer = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${vm.name}'
var protectedItem = 'vm;iaasvmcontainerv2;${resourceGroup().name};${vm.name}'

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
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
        }
      }
    ]
  }
}

@description('The private Network Interface Card for the Windows VM in spoke.')
resource nic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
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
    networkSecurityGroup: {
      id: nsg.id
    }
    enableAcceleratedNetworking: true
  }
}

@description('A basic Ubuntu Linux virtual machine that will be attached to spoke.')
resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'vm-learn-prod-${location}-${spokeName}-ubuntu'
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
    securityProfile: {
      //Virtual machines and virtual machine scale sets should have encryption at host enabled
      encryptionAtHost: true
    }
    priority: 'Regular'
  }
}

// Azure Backup should be enabled for virtual machines
resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2021-08-01' = {
  name: '${vm.name}-bkp'
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
  }
}

resource vaultName_backupFabric_protectionContainer_protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2020-02-02' = {
  name: '${recoveryServicesVault.name}/Azure/${protectionContainer}/${protectedItem}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: '${recoveryServicesVault.id}/backupPolicies/DefaultPolicy'
    sourceResourceId: vm.id
  }
} 

// Guest Configuration extension should be installed on machines
@description('Install the Guest Configuration extension for auditing purposes on the VM.')
resource guestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: vm
  name: 'Microsoft.GuestConfiguration'
  location: location
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforLinux'  // Use 'ConfigurationforWindows' if it's a Windows VM
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {}
  }
}

// Non-internet-facing virtual machines should be protected with network security groups
@description('The Network Security Group to protect the VM.')
resource nsg 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'nsg-learn-prod-${location}-${spokeName}-ubuntu'
  location: location
  properties: {
    securityRules: [
      {
        name: 'DenyInternetAccess'
        properties: {
          priority: 2000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          sourcePortRange: '*'
        }
      }
    ]
  }
}


output vnetId string = vnet.id

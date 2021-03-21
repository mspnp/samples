param adminUserName string = 'azureadmin'
param adminPassword string

param vmSize string = 'Standard_A1_v2'
param subnetId string

var nicNameWindows_var = 'nic-windows'
var vmNameWindows_var = 'vm-windows'
var windowsOSVersion = '2016-Datacenter'
var nicNameLinux_var = 'nic-linux'
var osVersion = '16.04.0-LTS'
var vmNameLinux_var = 'vm-linux'

resource nicNameWindows 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicNameWindows_var
  location: 'eastus'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vmNameWindows 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmNameWindows_var
  location: 'eastus'
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
          id: nicNameWindows.id
        }
      ]
    }
  }
}

resource nicNameLinux 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicNameLinux_var
  location: 'eastus'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vmNameLinux 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmNameLinux_var
  location: 'eastus'
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
          id: nicNameLinux.id
        }
      ]
    }
  }
}
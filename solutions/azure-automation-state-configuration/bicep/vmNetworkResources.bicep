targetScope = 'resourceGroup'

/*** PARAMETERS ***/

@description('Azure Virtual Machines, and supporting services (Automation State Configuration) region. This defaults to the resource group\'s location for higher reliability.')
param location string = resourceGroup().location

@description('The number of Azure Windows VMs to be deployed as web servers, configured via Desired State Configuration to install IIS.')
@minValue(0)
param vMCount int = 1

@description('Subnet id where the network interfaces are connected')
param subnetId string

@description('The name to identify the created resources')
param identifier string

/*** RESOURCES ***/

@description('Public IPs for VMs')
resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = [
  for i in range(0, vMCount): {
    name: 'pip-${identifier}-${location}${i}'
    location: location
    properties: {
      publicIPAllocationMethod: 'Dynamic'
    }
  }
]

@description('Network Interfaces for VMs')
resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = [
  for i in range(0, vMCount): {
    name: 'nic-${identifier}-${i}'
    location: location
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            publicIPAddress: {
              id: pip[i].id
            }
            subnet: {
              id: subnetId
            }
          }
        }
      ]
    }
  }
]

/*** OUTPUT ***/

output nics array = [for i in range(0, vMCount): {
  resourceId: nic[i].id
}]

output pips array = [for i in range(0, vMCount): {
  resourceId: pip[i].id
}]

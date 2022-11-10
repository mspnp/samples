targetScope = 'resourceGroup'

/*** PARAMETERS ***/

@description('The location of this regional hub. All resources, including spoke resources, will be deployed to this region. This region must support availability zones.')
@minLength(6)
/* Ideally we'd include this limitation, but since we want to default to the resource group's location, we cannot.
@allowed([
  'brazilsouth'
  'canadacentral'
  'centralus'
  'eastus'
  'eastus2'
  'southcentralus'
  'westus2'
  'westus3'
  'francecentral'
  'germanywestcentral'
  'northeurope'
  'norwayeast'
  'uksouth'
  'westeurope'
  'sweedencentral'
  'switzerlandnorth'
  'uaenorth'
  'southafricanorth'
  'australiaeast'
  'centralindia'
  'japaneast'
  'koreacentral'
  'southeastasia'
  'eastasia'
])*/
param location string = resourceGroup().location

@description('Set to true to include a basic VPN Gateway deployment into the hub. Set to false to leave network space for a VPN Gateway, but do not deploy one. Default is false. Note deploying VPN gateways can take significant time.')
param deployVpnGateway bool = false

@description('Set to true to include one Windows and one Linux virtual machine for you to experience peering, gateway transit, and bastion access. Default is false.')
param deployVirtualMachines bool = false

@description('Set to true to deploy Azure Bastion. Default is true')
param deployAzureBastion bool = true

@description('Set to false to disable the deployment of some provided default deny AVNM security admin rules. Default is true.')
param deployDefaultDenySecurityAdminRules bool = true

@minLength(4)
@maxLength(20)
@description('Username for both the Linux and Windows VM. Must only contain letters, numbers, hyphens, and underscores and may not start with a hyphen or number. Only needed when providing deployVirtualMachines=true.')
param adminUsername string = 'azureadmin'

@secure()
// @minLength(12) -- Ideally we'd have this here, but to support the multiple varients we will remove it.
@maxLength(70)
@description('Password for both the Linux and Windows VM. Password must have 3 of the following: 1 lower case character, 1 upper case character, 1 number, and 1 special character. Must be at least 12 characters. Only needed when providing deployVirtualMachines=true.')
param adminPassword string


/*** RESOURCES (HUB) ***/

module hub 'modules/hub.bicep' = {
  name: 'hub'
  params: {
    location: location
    deployVpnGateway: deployVpnGateway
    deployAzureBastion: deployAzureBastion
    deployVirtualMachines: deployVirtualMachines
  }
}

/*** RESOURCES (ALL SPOKES) ***/

@description('Next hop to the regional hub\'s Azure Firewall')
resource routeNextHopToFirewall 'Microsoft.Network/routeTables@2022-01-01' = {
  name: 'route-to-${location}-hub-fw'
  location: location
  properties: {
    routes: [
      {
        name: 'r-nexthop-to-fw'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: hub.outputs.firewall.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

/*** RESOURCES (SPOKE ONE) ***/
module spokenonprod1 'modules/spoke.bicep' = {
  name: 'spokenonprod1'
  scope: resourceGroup()
  params: {
    location: location
    deployVirtualMachines: deployVirtualMachines
    adminUsername: adminUsername
    adminPassword: adminPassword
    routeTableId: routeNextHopToFirewall.id
    spokeName: 'nonprod1'
    spokeVnetPrefix: '10.100.0.0/22'
    logAnalyticsWorkspaceId: hub.outputs.logAnalyticsWorkspaceId
  }
}


/*** RESOURCES (SPOKE TWO) ***/
module spokenonprod2 'modules/spoke.bicep' = {
  name: 'spokenonprod2'
  scope: resourceGroup()
  params: {
    location: location
    deployVirtualMachines: deployVirtualMachines
    adminUsername: adminUsername
    adminPassword: adminPassword
    routeTableId: routeNextHopToFirewall.id
    spokeName: 'nonprod2'
    spokeVnetPrefix: '10.101.0.0/22'
    logAnalyticsWorkspaceId: hub.outputs.logAnalyticsWorkspaceId
  }
}

/*** RESOURCES (SPOKE THREE) ***/
module spokeprod1 'modules/spoke.bicep' = {
  name: 'spokeprod1'
  scope: resourceGroup()
  params: {
    location: location
    deployVirtualMachines: deployVirtualMachines
    adminUsername: adminUsername
    adminPassword: adminPassword
    routeTableId: routeNextHopToFirewall.id
    spokeName: 'prod1'
    spokeVnetPrefix: '10.200.0.0/22'
    logAnalyticsWorkspaceId: hub.outputs.logAnalyticsWorkspaceId
  }
}

/*** RESOURCES (SPOKE FOUR) ***/
module spokeprod2 'modules/spoke.bicep' = {
  name: 'spokeprod2'
  scope: resourceGroup()
  params: {
    location: location
    deployVirtualMachines: deployVirtualMachines
    adminUsername: adminUsername
    adminPassword: adminPassword
    routeTableId: routeNextHopToFirewall.id
    spokeName: 'prod2'
    spokeVnetPrefix: '10.201.0.0/22'
    logAnalyticsWorkspaceId: hub.outputs.logAnalyticsWorkspaceId
  }
}

/*** AZURE VIRTUAL NETWORK MANAGER RESOURCES ***/
module avnm 'modules/avnm.bicep' = {
  name: 'avnm'
  scope: resourceGroup()
  params: {
    location: location
    hubVnetId: hub.outputs.hubVnetId
    nonProdNetworkGroupMembers: [
      spokenonprod1.outputs.vnetId
      spokenonprod2.outputs.vnetId
    ]
    prodNetworkGroupMembers: [
      spokeprod1.outputs.vnetId
      spokeprod2.outputs.vnetId
    ]
    deployVpnGateway: deployVpnGateway
    deployDefaultDenySecurityAdminRules: deployDefaultDenySecurityAdminRules
  }
}

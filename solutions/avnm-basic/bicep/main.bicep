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

@description('Set to false to disable the deployment of some provided default deny AVNM security admin rules. Default is true.')
param deployDefaultDenySecurityAdminRules bool = true

/*** RESOURCES (HUB) ***/

module hub 'modules/hub.bicep' = {
  name: 'hub'
  params: {
    location: location
  }
}

/*** RESOURCES (SPOKE ONE) ***/
module spokenonprod1 'modules/spoke.bicep' = {
  name: 'spokenonprod1'
  scope: resourceGroup()
  params: {
    location: location
    spokeName: 'nonprod1'
    spokeVnetPrefix: '10.100.0.0/22'
  }
}

/*** RESOURCES (SPOKE TWO) ***/
module spokenonprod2 'modules/spoke.bicep' = {
  name: 'spokenonprod2'
  scope: resourceGroup()
  params: {
    location: location
    spokeName: 'nonprod2'
    spokeVnetPrefix: '10.101.0.0/22'
  }
}

/*** RESOURCES (SPOKE THREE) ***/
module spokeprod1 'modules/spoke.bicep' = {
  name: 'spokeprod1'
  scope: resourceGroup()
  params: {
    location: location
    spokeName: 'prod1'
    spokeVnetPrefix: '10.200.0.0/22'
  }
}

/*** RESOURCES (SPOKE FOUR) ***/
module spokeprod2 'modules/spoke.bicep' = {
  name: 'spokeprod2'
  scope: resourceGroup()
  params: {
    location: location
    spokeName: 'prod2'
    spokeVnetPrefix: '10.201.0.0/22'
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
    deployDefaultDenySecurityAdminRules: deployDefaultDenySecurityAdminRules
  }
}

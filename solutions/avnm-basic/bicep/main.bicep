targetScope = 'subscription'

/*** PARAMETERS ***/

@description('The resource group name where the AVNM and VNET resources will be created')
param resourceGroupName string

@description('The location of this regional hub. All resources, including spoke resources, will be deployed to this region. This region must support availability zones.')
@minLength(6)
param location string

@description('Defines how spokes will communicate with eachother. Valid values: "mesh","hubAndSpoke"; default value: "mesh"')
@allowed(['mesh','hubAndSpoke'])
param connectivityTopology string = 'mesh'

@description('Connectivity group membership type. Valid values: "static", "dynamic"; default: "static"')
@allowed(['static','dynamic'])
param networkGroupMembershipType string = 'static'

/*** RESOURCE GROUP ***/
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}

/*** RESOURCES (HUB) ***/

module hub 'modules/hub.bicep' = {
  name: 'vnet-hub'
  scope: resourceGroup
  params: {
    location: location
  }
}

/*** RESOURCES (SPOKE A) ***/
module spokeA 'modules/spoke.bicep' = {
  name: 'vnet-spokeA'
  scope: resourceGroup
  params: {
    location: location
    spokeName: 'spokeA'
    spokeVnetPrefix: '10.100.0.0/22'
  }
}

/*** RESOURCES (SPOKE B) ***/
module spokeB 'modules/spoke.bicep' = {
  name: 'vnet-spokeB'
  scope: resourceGroup
  params: {
    location: location
    spokeName: 'spokeB'
    spokeVnetPrefix: '10.101.0.0/22'
  }
}

/*** RESOURCES (SPOKE C) ***/
module spokeC 'modules/spoke.bicep' = {
  name: 'vnet-spokeC'
  scope: resourceGroup
  params: {
    location: location
    spokeName: 'spokeC'
    spokeVnetPrefix: '10.102.0.0/22'
  }
}

/*** RESOURCES (SPOKE D) ***/
module spokeD 'modules/spoke.bicep' = {
  name: 'vnet-spokeD'
  scope: resourceGroup
  params: {
    location: location
    spokeName: 'spokeD'
    spokeVnetPrefix: '10.103.0.0/22'
  }
}

/*** Dynamic Membership Policy ***/
module policyDef 'modules/dynMemberPolicy.bicep' = if (networkGroupMembershipType == 'dynamic') {
  name: 'policyDefinition'
  scope: subscription()
  params: {
    networkGroupId: avnm.outputs.networkGroupId
  }
}

/*** AZURE VIRTUAL NETWORK MANAGER RESOURCES ***/
module avnm 'modules/avnm.bicep' = {
  name: 'avnm'
  scope: resourceGroup
  params: {
    location: location
    hubVnetId: hub.outputs.hubVnetId
    spokeNetworkGroupMembers: [
      spokeA.outputs.vnetId
      spokeB.outputs.vnetId
      spokeC.outputs.vnetId
      spokeD.outputs.vnetId
    ]
    connectivityTopology: connectivityTopology
    networkGroupMembershipType: networkGroupMembershipType
  }
}

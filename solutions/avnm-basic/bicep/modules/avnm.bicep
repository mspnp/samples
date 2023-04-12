param location string
param spokeNetworkGroupMembers array
param hubVnetId string
param connectivityTopology string
param networkGroupMembershipType string

// only these VNETs are grouped and will be added to the static Network Group
var groupedVNETs = [
  'vnet-${location}-spokea'
  'vnet-${location}-spokeb'
  'vnet-${location}-spokec'
]

@description('This is the Azure Virtual Network Manager which will be used to implement the connected group for spoke-to-spoke connectivity.')
resource networkManager 'Microsoft.Network/networkManagers@2022-09-01' = {
  name: 'avnm-${location}'
  location: location
  properties: {
    networkManagerScopeAccesses: [
      'Connectivity'
    ]
    networkManagerScopes: {
      subscriptions: [
        '/subscriptions/${subscription().subscriptionId}'
      ]
      managementGroups: []
    }
  }
}

@description('This is the static network group for the spoke VNETs.')
resource networkGroupSpokesStatic 'Microsoft.Network/networkManagers/networkGroups@2022-09-01' = if (networkGroupMembershipType == 'static') {
  name: 'ng-${location}-spokes-static'
  parent: networkManager
  properties: {
    description: 'Spoke VNETs Network Group - Static'
  }

  // add spoke vnets A, B, and C to the static network group
  resource staticMemberSpoke 'staticMembers@2022-09-01' = [for spokeMember in spokeNetworkGroupMembers: if (contains(groupedVNETs,last(split(spokeMember,'/')))) {
    name: 'sm-${(last(split(spokeMember, '/')))}'
    properties: {
      resourceId: spokeMember
    }
  }]
}

@description('This is the dynamic group for spoke VNETs.')
resource networkGroupSpokesDynamic 'Microsoft.Network/networkManagers/networkGroups@2022-09-01' = if (networkGroupMembershipType == 'dynamic') {
  name: 'ng-${location}-spokes-dynamic'
  parent: networkManager
  properties: {
    description: 'Spoke VNETs Network Group - Dynamic'
  }
}

@description('This connectivity configuration defines the connectivity between the spokes using Direct Connection. The Hub VNET will not be connected.')
resource connectivityConfigurationMesh 'Microsoft.Network/networkManagers/connectivityConfigurations@2022-09-01' = if (connectivityTopology == 'mesh') {
  name: 'cc-${location}-spokes-mesh'
  parent: networkManager
  properties: {
    description: 'Spoke-to-spoke connectivity configuration'
    appliesToGroups: [
      {
        networkGroupId: (networkGroupMembershipType == 'static') ? networkGroupSpokesStatic.id : networkGroupSpokesDynamic.id
        isGlobal: 'False'
        useHubGateway: 'False'
        groupConnectivity: 'DirectlyConnected'
      }
    ]
    connectivityTopology: 'Mesh'
    deleteExistingPeering: 'True'
    hubs: []
    isGlobal: 'False'
  }
}

@description('This connectivity configuration defines the connectivity between the spokes using Hub and Spoke - traffic flow through hub requires an NVA to route it.')
resource connectivityConfigurationHubAndSpoke 'Microsoft.Network/networkManagers/connectivityConfigurations@2022-09-01' = if (connectivityTopology == 'hubAndSpoke') {
  name: 'cc-${location}-spokes-hubandspoke'
  parent: networkManager
  properties: {
    description: 'Spoke-to-spoke connectivity configuration'
    appliesToGroups: [
      {
        networkGroupId: (networkGroupMembershipType == 'static') ? networkGroupSpokesStatic.id : networkGroupSpokesDynamic.id
        isGlobal: 'False'
        useHubGateway: 'False'
        groupConnectivity: 'None'
      }
    ]
    connectivityTopology: 'HubAndSpoke'
    deleteExistingPeering: 'True'
    hubs: [
      {
        resourceId: hubVnetId
        resourceType: 'Microsoft.Network/virtualNetworks'
      }
    ]
    isGlobal: 'False'
  }
}

@description('This user assigned identity is used by the Deployment Script resource to interact with Azure resources.')
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'uai-${location}'
  location: location
}

@description('This role assignment grants the user assigned identity the Contributor role on the resource group.')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, userAssignedIdentity.name)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor: b24988ac-6180-42a0-ab88-20f7382dd24c
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output networkManagerName string = networkManager.name
output userAssignedIdentityId string = userAssignedIdentity.id
output connectivityConfigurationId string = connectivityTopology == 'mesh' ? connectivityConfigurationMesh.id : connectivityConfigurationHubAndSpoke.id
output networkGroupId string = networkGroupSpokesDynamic.id ?? networkGroupSpokesStatic.id

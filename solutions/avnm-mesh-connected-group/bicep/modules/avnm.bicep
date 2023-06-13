param location string
param spokeNetworkGroupMembers array
param hubVnetId string
param networkGroupMembershipType string

// only these spoke VNETs will be added to the static Network Group
var groupedVNETs = [
  'vnet-${location}-spokea'
  'vnet-${location}-spokeb'
  'vnet-${location}-spokec'
]

@description('This is the Azure Virtual Network Manager which will be used to implement the connected group for inter-vnet connectivity.')
resource networkManager 'Microsoft.Network/networkManagers@2022-09-01' = {
  name: 'vnm-learn-prod-${location}-001'
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

@description('This is the static network group for all VNETs')
resource networkGroupStatic 'Microsoft.Network/networkManagers/networkGroups@2022-09-01' = if (networkGroupMembershipType == 'static') {
  name: 'ng-learn-prod-${location}-static001'
  parent: networkManager
  properties: {
    description: 'Network Group - Static'
  }

  // add spoke vnets A, B, and C to the static network group
  resource staticMemberSpoke 'staticMembers@2022-09-01' = [for spokeMember in spokeNetworkGroupMembers: if (contains(groupedVNETs,last(split(spokeMember,'/')))) {
    name: 'sm-${(last(split(spokeMember, '/')))}'
    properties: {
      resourceId: spokeMember
    }
  }]

  // add hub if connectivity topology is 'mesh' (otherwise, hub is connected via hub and spoke peering)
  resource staticMemberHub 'staticMembers@2022-09-01' = {
    name: 'sm-${(toLower(last(split(hubVnetId, '/'))))}'
    properties: {
      resourceId: hubVnetId
    }
  }
}

@description('This is the dynamic group for spoke VNETs.')
resource networkGroupDynamic 'Microsoft.Network/networkManagers/networkGroups@2022-09-01' = if (networkGroupMembershipType == 'dynamic') {
  name: 'ng-learn-prod-${location}-dynamic001'
  parent: networkManager
  properties: {
    description: 'Network Group - Dynamic'
  }
}

// Connectivity Topology: mesh
//
// Spoke 'A' VM Effective routes
// Source    State    Address Prefix               Next Hop Type    Next Hop IP
// --------  -------  ---------------------------  ---------------  -------------
// Default   Active   10.100.0.0/22                VnetLocal
// Default   Active   10.0.0.0/22 10.102.0.0/22 10.101.0.0/22  ConnectedGroup
// Default   Active   0.0.0.0/0                    Internet
// ...
@description('This connectivity configuration defines the connectivity between VNETs using Direct Connection. The hub will be part of the mesh, but gateway routes from the hub will not propagate to spokes.')
resource connectivityConfigurationMesh 'Microsoft.Network/networkManagers/connectivityConfigurations@2022-09-01' = {
  name: 'cc-learn-prod-${location}-mesh001'
  parent: networkManager
  properties: {
    description: 'Mesh connectivity configuration'
    appliesToGroups: [
      {
        networkGroupId: (networkGroupMembershipType == 'static') ? networkGroupStatic.id : networkGroupDynamic.id
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
output connectivityConfigurationId string = connectivityConfigurationMesh.id
output networkGroupId string = networkGroupDynamic.id ?? networkGroupStatic.id

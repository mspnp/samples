param location string
param hubVnetId string
param connectivityTopology string

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

@description('This is the dynamic group for spoke VNETs.')
resource networkGroupSpokesDynamic 'Microsoft.Network/networkManagers/networkGroups@2022-09-01' = {
  name: 'ng-learn-prod-${location}-dynamic-001'
  parent: networkManager
  properties: {
    description: 'Network Group - Dynamic'
  }
}

// Connectivity Topology: hub and spoke
//
// Spoke 'A' VM Effective routes
// Source    State    Address Prefix               Next Hop Type    Next Hop IP
// --------  -------  ---------------------------  ---------------  -------------
// Default   Active   10.100.0.0/22                VnetLocal
// Default   Active   10.0.0.0/22                  VNetPeering
// Default   Active   0.0.0.0/0                    Internet
// ...
@description('This connectivity configuration defines the connectivity between the spokes using Hub and Spoke - traffic flow through hub requires an NVA to route it.')
resource connectivityConfigurationHubAndSpoke 'Microsoft.Network/networkManagers/connectivityConfigurations@2022-09-01' = if (connectivityTopology == 'hubAndSpoke') {
  name: 'cc-learn-prod-${location}-001'
  parent: networkManager
  properties: {
    description: 'Spoke-to-spoke connectivity configuration'
    appliesToGroups: [
      {
        networkGroupId: networkGroupSpokesDynamic.id
        isGlobal: 'False'
        useHubGateway: 'True'
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

@description('This is the securityadmin configuration assigned to the AVNM')
resource securityConfig 'Microsoft.Network/networkManagers/securityAdminConfigurations@2022-05-01' = {
  name: 'sac-learn-prod-${location}-001'
  parent: networkManager
  properties: {
    applyOnNetworkIntentPolicyBasedServices: [ 'None' ]
    description: 'Security Group for AVNM'
  }
}

@description('This is the rules collection for the security admin config assigned to the AVNM')
resource rulesCollection 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections@2022-05-01' = {
  name: 'rc-learn-prod-${location}-001'
  parent: securityConfig
  properties: {
    appliesToGroups: [
      {
        networkGroupId: networkGroupSpokesDynamic.id
      }
    ]
  }
}

@description('This example rule denies outbound HTTP/S traffic to the internet')
resource DENY_INTERNET_HTTP_HTTPS 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2022-05-01' = {
  name: 'DENY_INTERNET_HTTP_HTTPS'
  kind: 'Custom'
  parent: rulesCollection
  properties: {
    access: 'Deny'
    description: 'This rule blocks traffic to the internet on HTTP and HTTPS'
    destinationPortRanges: [ '80','443' ]
    destinations: [
      {
        addressPrefix: '*'
        addressPrefixType: 'IPPrefix'
      }
    ]
    direction: 'Inbound'
    priority: 100
    protocol: 'TCP'
    sourcePortRanges: [ '0-65535' ]
    sources: [
      {
        addressPrefix: '*'
        addressPrefixType: 'IPPrefix'
      }
    ]
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
output connectivityConfigurationId string = connectivityConfigurationHubAndSpoke.id
output networkGroupId string = networkGroupSpokesDynamic.id

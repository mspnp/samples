/*** PARAMETERS ***/
@description('All resources will be deployed to this region.')
param location string = resourceGroup().location

@description('Hub VNet ID to which the spokes will connect.')
param hubVnetId string

@description('Connectivity topology to be used for networkManagers Configuration.')
param connectivityTopology string

/*** RESOURCES ***/

@description('This is the Azure Virtual Network Manager which will be used to implement the connected group for spoke-to-spoke connectivity.')
resource vnm 'Microsoft.Network/networkManagers@2024-05-01' = {
  name: 'vnm-${location}'
  location: location
  properties: {
    networkManagerScopeAccesses: [
      'Connectivity'
      'SecurityAdmin'
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
resource vnmNetworkGroupSpokesDynamic 'Microsoft.Network/networkManagers/networkGroups@2024-05-01' = {
  name: 'vnm-ng-learn-prod-${location}-dynamic-001'
  parent: vnm
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
resource vnmConnectivityConfigurationHubAndSpoke 'Microsoft.Network/networkManagers/connectivityConfigurations@2024-05-01' = if (connectivityTopology == 'hubAndSpoke') {
  name: 'vnm-cc-learn-prod-${location}-001'
  parent: vnm
  properties: {
    description: 'Spoke-to-spoke connectivity configuration'
    appliesToGroups: [
      {
        networkGroupId: vnmNetworkGroupSpokesDynamic.id
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
resource vnmSecurityConfig 'Microsoft.Network/networkManagers/securityAdminConfigurations@2024-05-01' = {
  name: 'vnm-sac-learn-prod-${location}-001'
  parent: vnm
  properties: {
    applyOnNetworkIntentPolicyBasedServices: [ 'None' ]
    description: 'Security Group for AVNM'
  }
}

@description('This is the rules collection for the security admin config assigned to the AVNM')
resource vnmRulesCollection 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections@2024-05-01' = {
  name: 'vnm-rc-learn-prod-${location}-001'
  parent: vnmSecurityConfig
  properties: {
    appliesToGroups: [
      {
        networkGroupId: vnmNetworkGroupSpokesDynamic.id
      }
    ]
  }
}

@description('This example rule denies outbound HTTP/S traffic to the internet')
resource DENY_INTERNET_HTTP_HTTPS 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2024-05-01' = {
  name: 'DENY_INTERNET_HTTP_HTTPS'
  kind: 'Custom'
  parent: vnmRulesCollection
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
resource id 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = {
  name: 'id-${location}'
  location: location
}

@description('This role assignment grants the user assigned identity the Contributor role on the resource group.')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, id.name)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor: b24988ac-6180-42a0-ab88-20f7382dd24c
    principalId: id.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output networkManagerName string = vnm.name
output userAssignedIdentityId string = id.id
output connectivityConfigurationId string = vnmConnectivityConfigurationHubAndSpoke.id
output securtyAdminConfigurationId string = vnmSecurityConfig.id
output networkGroupId string = vnmNetworkGroupSpokesDynamic.id

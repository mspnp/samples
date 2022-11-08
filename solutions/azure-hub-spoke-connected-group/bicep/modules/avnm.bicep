param location string
param prodNetworkGroupMembers array
param nonProdNetworkGroupMembers array
param hubVnetId string
param deployVpnGateway bool

@description('This is the Azure Virtual Network Manager which will be used to implement the connected group for spoke-to-spoke connectivity.')
resource networkManager 'Microsoft.Network/networkManagers@2022-05-01' = {
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
  resource networkGroupProd 'networkGroups@2022-05-01' = {
    name: 'ng-${location}-spokes-prod'
    properties: {
      description: 'Prod Spoke VNETs Network Group'
    }
    resource staticMembersSpokeOne 'staticMembers@2022-05-01' = {
      name: 'sm-${location}-1'
      properties: {
        resourceId: prodNetworkGroupMembers[0]
      }
    }
    resource staticMembersSpokeTwo 'staticMembers@2022-05-01' = {
      name: 'sm-${location}-2'
      properties: {
        resourceId: prodNetworkGroupMembers[1]
      }
    }
  }
  resource networkGroupNonProd 'networkGroups@2022-05-01' = {
    name: 'ng-${location}-spokes-nonprod'
    properties: {
      description: 'Non-prod Spoke VNETs Network Group'
    }
    resource staticMembersSpokeOne 'staticMembers@2022-05-01' = {
      name: 'sm-${location}-1'
      properties: {
        resourceId: nonProdNetworkGroupMembers[0]
      }
    }
    resource staticMembersSpokeTwo 'staticMembers@2022-05-01' = {
      name: 'sm-${location}-2'
      properties: {
        resourceId: nonProdNetworkGroupMembers[1]
      }
    }
  }
  resource networkGroupAll 'networkGroups@2022-05-01' = {
    name: 'ng-${location}-all'
    properties: {
      description: 'All VNETs Network Group (for Security Configurations)'
    }
    resource staticMembers1 'staticMembers@2022-05-01' = {
      name: 'sm-${location}-0'
      properties: {
        resourceId: prodNetworkGroupMembers[0]
      }
    }
    resource staticMembers2 'staticMembers@2022-05-01' = {
      name: 'sm-${location}-1'
      properties: {
        resourceId: prodNetworkGroupMembers[1]
      }
    }
    resource staticMembers3 'staticMembers@2022-05-01' = {
      name: 'sm-${location}-2'
      properties: {
        resourceId: nonProdNetworkGroupMembers[0]
      }
    }
    resource staticMembers4 'staticMembers@2022-05-01' = {
      name: 'sm-${location}-3'
      properties: {
        resourceId: nonProdNetworkGroupMembers[1]
      }
    }
    resource staticMembers5 'staticMembers@2022-05-01' = {
      name: 'sm-${location}-4'
      properties: {
        resourceId: hubVnetId
      }
    }
  }
}

@description('This connectivity configuration defines the connectivity between the spokes. Only deployed if requested.')
resource connectivityConfigurationNonProd 'Microsoft.Network/networkManagers/connectivityConfigurations@2022-05-01' = {
  name: 'cc-${location}-spokesnonprod'
  parent: networkManager
  dependsOn: [
    networkManager::networkGroupNonProd::staticMembersSpokeOne
    networkManager::networkGroupNonProd::staticMembersSpokeTwo
  ]
  properties: {
    description: 'Non-prod poke-to-spoke connectivity configuration'
    displayName: 'Non-prod Spoke-to-Spoke Connectivity'
    appliesToGroups: [
      {
        networkGroupId: networkManager::networkGroupNonProd.id
        isGlobal: 'False'
        useHubGateway: string(deployVpnGateway)
        groupConnectivity: 'DirectlyConnected'
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

@description('This connectivity configuration defines the connectivity between the spokes. Only deployed if requested.')
resource connectivityConfigurationProd 'Microsoft.Network/networkManagers/connectivityConfigurations@2022-05-01' = {
  name: 'cc-${location}-spokesprod'
  parent: networkManager
  dependsOn: [
    networkManager::networkGroupProd::staticMembersSpokeOne
    networkManager::networkGroupProd::staticMembersSpokeTwo
  ]
  properties: {
    description: 'Prod spoke-to-spoke connectivity configuration (through hub)'
    displayName: 'Prod Spoke-to-Spoke Connectivity'
    appliesToGroups: [
      {
        networkGroupId: networkManager::networkGroupProd.id
        isGlobal: 'False'
        useHubGateway: string(deployVpnGateway)
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

@description('This role assignment grants the user assignmed identity the Contributor role on the resource group.')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, userAssignedIdentity.name)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor: b24988ac-6180-42a0-ab88-20f7382dd24c
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('This is the securityadmin configuration assigned to the AVNM')
resource securityGroup 'Microsoft.Network/networkManagers/securityAdminConfigurations@2022-05-01' = {
  name: 'sg-${location}'
  parent: networkManager
   properties: {
    applyOnNetworkIntentPolicyBasedServices: ['All'] 
    description: 'Security Group for AVNM'
     }
  }

@description('This is the rules collection for the security admin config assigned to the AVNM')
resource rulesCollection 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections@2022-05-01' = {
name: 'rc-${location}'
parent: securityGroup
properties: {
  appliesToGroups: [
     {
      networkGroupId: networkManager::networkGroupAll.id
     }
   ]
 }
}

@description('This is the rule is to Deny all TCP Rules')
resource rule1 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2022-05-01' = {
name: 'r-tcp-${location}'
kind: 'Custom'
parent: rulesCollection
properties: {
  access: 'Deny'
  description: 'Denying TCP rules'
  destinationPortRanges: ['*']
  destinations: [
          {
            addressPrefix: '*'
            addressPrefixType: 'IPPrefix'
          }
      ]
  direction: 'Inbound'
  priority: 100
  protocol: 'TCP'
  sourcePortRanges: ['20,21,22,23,69,119,161,445,512,514,873,3389,5800,5900']
  sources: [
          {
            addressPrefix: '*'
            addressPrefixType: 'IPPrefix'
          }
      ]  
  }      
}

@description('This rule to deny inbound TCP/UDP rules')
resource rule2 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2022-05-01' = {
name: 'r-tcp-udp-${location}'
kind: 'Custom'
parent: rulesCollection
properties: {
  access: 'Deny'
  description: 'Deny all TCP/UDP rules'
  destinationPortRanges: ['*']
  destinations: [
          {
            addressPrefix: '*'
            addressPrefixType: 'IPPrefix'
          }
      ]
  direction: 'Inbound'
  priority: 100
  protocol: 'TCP,UDP'
  sourcePortRanges: ['11,135,162,593,2049']
  sources: [
          {
            addressPrefix: '*'
            addressPrefixType: 'IPPrefix'
          }
      ]  
  }      
}

@description('This is the rule for the rules collection for the security admin config assigned to the AVNM')
resource rule3 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2022-05-01' = {
name: 'r-udp-${location}'
kind: 'Custom'
parent: rulesCollection
properties: {
  access: 'Deny'
  description: 'Deny all UDP rules'
  destinationPortRanges: ['*']
  destinations: [
          {
            addressPrefix: '*'
            addressPrefixType: 'IPPrefix'
          }
      ]
  direction: 'Inbound'
  priority: 100
  protocol: 'UDP'
  sourcePortRanges: ['69,11211']
  sources: [
          {
            addressPrefix: '*'
            addressPrefixType: 'IPPrefix'
          }
      ]  
  }      
}





//
// In order to deploy a Connectivity or Security configruation, the /commit endpoint must be called or a Deployment created in the Portal. 
// This DeploymentScript resource executes a PowerShell script which calls the /commit endpoint and monitors the status of the deployment.
//
module deploymentScriptConnectivityConfigs './avnmDeploymentScript.bicep' = {
  name: 'ds-${location}-connectivityconfigs'
  dependsOn: [
    roleAssignment
  ]
  params: {
    location: location
    userAssignedIdentityId: userAssignedIdentity.id
    configurationIds: '${connectivityConfigurationProd.id},${connectivityConfigurationNonProd.id}' // each configuration separated by a semicolon
    configType: 'Connectivity'
    networkManagerName: networkManager.name
    deploymentScriptName: 'ds-${location}-connectivityconfigs'
  }
}



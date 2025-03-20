param location string
param prodNetworkGroupMembers array
param nonProdNetworkGroupMembers array
param hubVnetId string
param deployVpnGateway bool
param deployDefaultDenySecurityAdminRules bool

@description('This is the Azure Virtual Network Manager which will be used to implement the connected group for spoke-to-spoke connectivity.')
resource networkManager 'Microsoft.Network/networkManagers@2024-05-01' = {
  name: 'avnm-${location}'
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

  // static network group membership is used to avoid potential conflict in the test environment. 
  // for production deployments, consider using Azure Policy to dynamically bring VNETs under 
  // AVNM management. see https://learn.microsoft.com/azure/virtual-network-manager/concept-azure-policy-integration
  @description('This is the static network group for the production spoke VNETs.')
  resource networkGroupProd 'Microsoft.Network/networkManagers/networkGroups@2024-05-01' = {
    name: 'ng-${location}-spokes-prod'
    parent: networkManager
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
  @description('This is the static network group for the non-production spoke VNETs.')
  resource networkGroupNonProd 'Microsoft.Network/networkManagers/networkGroups@2024-05-01' = {
    name: 'ng-${location}-spokes-nonprod'
    parent: networkManager
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
  @description('This is the static network group for all VNETs.')
  resource networkGroupAll 'Microsoft.Network/networkManagers/networkGroups@2024-05-01' = {
    name: 'ng-${location}-all'
    parent: networkManager
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

@description('This connectivity configuration defines the connectivity between the spokes.')
resource connectivityConfigurationNonProd 'Microsoft.Network/networkManagers/connectivityConfigurations@2024-05-01' = {
  name: 'cc-${location}-spokesnonprod'
  parent: networkManager
  dependsOn: [
    networkGroupNonProd::staticMembersSpokeOne
    networkGroupNonProd::staticMembersSpokeTwo
  ]
  properties: {
    description: 'Non-prod poke-to-spoke connectivity configuration'
    appliesToGroups: [
      {
        networkGroupId: networkGroupNonProd.id
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

@description('This connectivity configuration defines the connectivity between the spokes.')
resource connectivityConfigurationProd 'Microsoft.Network/networkManagers/connectivityConfigurations@2024-05-01' = {
  name: 'cc-${location}-spokesprod'
  parent: networkManager
  dependsOn: [
    networkGroupProd::staticMembersSpokeOne
    networkGroupProd::staticMembersSpokeTwo
  ]
  properties: {
    description: 'Prod spoke-to-spoke connectivity configuration (through hub)'
    appliesToGroups: [
      {
        networkGroupId: networkGroupProd.id
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
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2015-08-31-PREVIEW' = {
  name: 'uai-${location}'
  location: location
}

@description('This role assignment grants the user assigned identity the Contributor role on the resource group.')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, userAssignedIdentity.name)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor: b24988ac-6180-42a0-ab88-20f7382dd24c
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('This is the securityadmin configuration assigned to the AVNM')
resource securityConfig 'Microsoft.Network/networkManagers/securityAdminConfigurations@2024-05-01' = {
  name: 'sg-${location}'
  parent: networkManager
  properties: {
    applyOnNetworkIntentPolicyBasedServices: [ 'None' ]
    description: 'Security Group for AVNM'
  }
}

@description('This is the rules collection for the security admin config assigned to the AVNM')
resource rulesCollection 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections@2024-05-01' = {
  name: 'rc-${location}'
  parent: securityConfig
  properties: {
    appliesToGroups: [
      {
        networkGroupId: networkGroupAll.id
      }
    ]
  }
}

@description('This example rule contains all denied inbound TCP ports')
resource rule1 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2024-05-01' = if (deployDefaultDenySecurityAdminRules) {
  name: 'r-tcp-${location}'
  kind: 'Custom'
  parent: rulesCollection
  properties: {
    access: 'Deny'
    description: 'Inbound TCP Deny Example Rule'
    destinationPortRanges: [ '20', '21', '22', '23', '69', '119', '161', '445', '512', '514', '873', '3389', '5800', '5900' ]
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

@description('This example rule contains all denied inbound TCP or UDP ports')
resource rule2 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2024-05-01' = {
  name: 'r-tcp-udp-${location}'
  kind: 'Custom'
  parent: rulesCollection
  properties: {
    access: 'Deny'
    description: 'Inbound TCP/UDP Deny Example Rule'
    destinationPortRanges: [ '11', '135', '162', '593', '2049' ]
    destinations: [
      {
        addressPrefix: '*'
        addressPrefixType: 'IPPrefix'
      }
    ]
    direction: 'Inbound'
    priority: 101
    protocol: 'TCP,UDP'
    sourcePortRanges: [ '0-65535' ]
    sources: [
      {
        addressPrefix: '*'
        addressPrefixType: 'IPPrefix'
      }
    ]
  }
}

@description('This example rule contains all denied inbound UDP ports')
resource rule3 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2024-05-01' = {
  name: 'r-udp-${location}'
  kind: 'Custom'
  parent: rulesCollection
  properties: {
    access: 'Deny'
    description: 'Inbound UDP Deny Example Rule'
    destinationPortRanges: [ '69', '11211' ]
    destinations: [
      {
        addressPrefix: '*'
        addressPrefixType: 'IPPrefix'
      }
    ]
    direction: 'Inbound'
    priority: 102
    protocol: 'UDP'
    sourcePortRanges: [ '0-65535' ]
    sources: [
      {
        addressPrefix: '*'
        addressPrefixType: 'IPPrefix'
      }
    ]
  }
}

@description('This example rule always allows outbound traffic to Microsoft Entra ID, overriding NSG outbound restrictions')
resource rule4 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2024-05-01' = {
  name: 'r-alwaysallow-${location}'
  kind: 'Custom'
  parent: rulesCollection
  properties: {
    access: 'AlwaysAllow'
    description: 'Always allow outbound traffic to Microsoft Entra ID'
    destinationPortRanges: [ '0-65535' ]
    destinations: [
      {
        addressPrefix: 'AzureActiveDirectory'
        addressPrefixType: 'ServiceTag'
      }
    ]
    direction: 'Outbound'
    priority: 103
    protocol: 'Any'
    sourcePortRanges: [ '0-65535' ]
    sources: [
      {
        addressPrefix: '*'
        addressPrefixType: 'IPPrefix'
      }
    ]
  }
}

@description('This example rule allows outbound traffic to Azure SQL, unless an NSG in the path denies it')
resource rule5 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2024-05-01' = {
  name: 'r-allowsql-${location}'
  kind: 'Custom'
  parent: rulesCollection
  properties: {
    access: 'Allow'
    description: 'Allow outbound traffic to Azure SQL'
    destinationPortRanges: [ '0-65535' ]
    destinations: [
      {
        addressPrefix: 'Sql'
        addressPrefixType: 'ServiceTag'
      }
    ]
    direction: 'Outbound'
    priority: 104
    protocol: 'Any'
    sourcePortRanges: [ '0-65535' ]
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
    configurationIds: '${connectivityConfigurationProd.id},${connectivityConfigurationNonProd.id}' // each configuration separated by a comma
    configType: 'Connectivity'
    networkManagerName: networkManager.name
    deploymentScriptName: 'ds-${location}-connectivityconfigs'
  }
}

module deploymentScriptSecurityConfigs './avnmDeploymentScript.bicep' = {
  name: 'ds-${location}-securityconfigs'
  dependsOn: [
    roleAssignment
  ]
  params: {
    location: location
    userAssignedIdentityId: userAssignedIdentity.id
    configurationIds: securityConfig.id // each configuration separated by a semicolon
    configType: 'SecurityAdmin'
    networkManagerName: networkManager.name
    deploymentScriptName: 'ds-${location}-securityconfigs'
  }
}

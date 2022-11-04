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

@description('Set to true to deploy an Azure Virtual Networking Manager (AVNM) instance and a Connected Group to implement direct spoke-to-spoke connectivity. Default is false.')
param deployAvnm bool = false

@description('Set to true to deploy Azure Bastion. Default is true')
param deployAzureBastion bool = true

@description('Set to true to deploy an Azure Firewall. Default is true.')
param deployAzureFirewall bool = true

@minLength(4)
@maxLength(20)
@description('Username for both the Linux and Windows VM. Must only contain letters, numbers, hyphens, and underscores and may not start with a hyphen or number. Only needed when providing deployVirtualMachines=true.')
param adminUsername string = 'azureadmin'

@secure()
// @minLength(12) -- Ideally we'd have this here, but to support the multiple varients we will remove it.
@maxLength(70)
@description('Password for both the Linux and Windows VM. Password must have 3 of the following: 1 lower case character, 1 upper case character, 1 number, and 1 special character. Must be at least 12 characters. Only needed when providing deployVirtualMachines=true.')
param adminPassword string

/*** VARIABLES ***/

var suffix = uniqueString(subscription().subscriptionId, resourceGroup().id)

/*** RESOURCES (HUB) ***/

@description('This Log Analyics Workspace stores logs from the regional hub network, its spokes, and other related resources. Workspaces are regional resource, as such there would be one workspace per hub (region)')
resource laHub 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'la-hub-${location}-${suffix}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    forceCmkForQuery: false
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      disableLocalAuth: false
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
  }
}

resource laHub_diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-hub-la'
  scope: laHub
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('The NSG around the Azure Bastion subnet. Source: https://learn.microsoft.com/azure/bastion/bastion-nsg')
resource nsgBastionSubnet 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'nsg-${location}-bastion'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowWebExperienceInbound'
        properties: {
          description: 'Allow our users in. Update this to be as restrictive as possible.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowControlPlaneInbound'
        properties: {
          description: 'Service Requirement. Allow control plane access. Regional Tag not yet supported.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHealthProbesInbound'
        properties: {
          description: 'Service Requirement. Allow Health Probes.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostToHostInbound'
        properties: {
          description: 'Service Requirement. Allow Required Host to Host Communication.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          description: 'No further inbound traffic allowed.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSshToVnetOutbound'
        properties: {
          description: 'Allow SSH out to the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '22'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowRdpToVnetOutbound'
        properties: {
          description: 'Allow RDP out to the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '3389'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowControlPlaneOutbound'
        properties: {
          description: 'Required for control plane outbound. Regional prefix not yet supported'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionHostToHostOutbound'
        properties: {
          description: 'Service Requirement. Allow Required Host to Host Communication.'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionCertificateValidationOutbound'
        properties: {
          description: 'Service Requirement. Allow Required Session and Certificate Validation.'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '80'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutbound'
        properties: {
          description: 'No further outbound traffic allowed.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource nsgBastionSubnet_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: nsgBastionSubnet
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

@description('The regional hub network.')
resource vnetHub 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: 'vnet-${location}-hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/22'
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/26'
          networkSecurityGroup: {
            id: nsgBastionSubnet.id
          }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.2.0/27'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.3.0/26'
        }
      }
    ]
  }

  resource azureBastionSubnet 'subnets' existing = {
    name: 'AzureBastionSubnet'
  }

  resource gatewaySubnet 'subnets' existing = {
    name: 'GatewaySubnet'
  }

  resource azureFirewallSubnet 'subnets' existing = {
    name: 'AzureFirewallSubnet'
  }

  // Connect regional hub back to spoke one (created later below). This could also
  // be handled via Azure Policy or Portal. How virtual networks are peered  might
  // vary from organization to organization. This example simply does it in the most
  // direct way to simplify ease of deployment.
  resource peerToSpokeOne 'virtualNetworkPeerings@2022-01-01' = if (!deployAvnm) {
    name: 'to_${vnetSpokeOne.name}'
    dependsOn: [
      vnetSpokeOne::peerToHub // This artificially waits until the spoke peers with the hub first to control order of operations.
    ]
    properties: {
      allowForwardedTraffic: false
      allowGatewayTransit: false
      allowVirtualNetworkAccess: true
      useRemoteGateways: false
      remoteVirtualNetwork: {
        id: vnetSpokeOne.id
      }
    }
  }

  // Connect regional hub back to spoke one (created later below).
  resource peerToSpokeTwo 'virtualNetworkPeerings@2022-01-01' = if(!deployAvnm) {
    name: 'to_${vnetSpokeTwo.name}'
    dependsOn: [
      vnetSpokeTwo::peerToHub // This artificially waits until the spoke peers with the hub first to control order of operations.
    ]
    properties: {
      allowForwardedTraffic: false
      allowGatewayTransit: false
      allowVirtualNetworkAccess: true
      useRemoteGateways: false
      remoteVirtualNetwork: {
        id: vnetSpokeTwo.id
      }
    }
  }
}

resource vnetHub_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-hub-la'
  scope: vnetHub
  properties: {
    workspaceId: laHub.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Allocate three IP addresses to the firewall
var numFirewallIpAddressesToAssign = 3
resource pipsAzureFirewall 'Microsoft.Network/publicIPAddresses@2022-01-01' = [for i in range(0, numFirewallIpAddressesToAssign): if (deployAzureFirewall) {
  name: 'pip-fw-${location}-${padLeft(i, 2, '0')}'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}]

resource pipsAzureFirewall_diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for i in range(0, numFirewallIpAddressesToAssign): if (deployAzureFirewall) {
  name: 'to-hub-la'
  scope: pipsAzureFirewall[i]
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}]

@description('Azure Firewall Policy')
resource fwPolicy 'Microsoft.Network/firewallPolicies@2022-01-01' = if (deployAzureFirewall) {
  name: 'fw-policies-${location}'
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Deny'
    insights: {
      isEnabled: true
      retentionDays: 30
      logAnalyticsResources: {
        defaultWorkspaceId: {
          id: laHub.id
        }
      }
    }
    threatIntelWhitelist: {
      fqdns: []
      ipAddresses: []
    }
    intrusionDetection: null // Only valid on Premium tier sku
    dnsSettings: {
      servers: []
      enableProxy: true
    }
  }

  // This network hub starts out with only supporting external DNS queries. This is only being done for
  // simplicity in this deployment and is not guidance, please ensure all firewall rules are aligned with
  // your security standards.
  resource defaultNetworkRuleCollectionGroup 'ruleCollectionGroups@2022-01-01' = if (deployAzureFirewall) {
    name: 'DefaultNetworkRuleCollectionGroup'
    properties: {
      priority: 200
      ruleCollections: [
        {
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          name: 'org-wide-allowed'
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              ruleType: 'NetworkRule'
              name: 'DNS'
              description: 'Allow DNS outbound (for simplicity, adjust as needed)'
              ipProtocols: [
                'UDP'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
              destinationAddresses: [
                '*'
              ]
              destinationIpGroups: []
              destinationFqdns: []
              destinationPorts: [
                '53'
              ]
            }
          ]
        }
      ]
    }
  }

  // Network hub starts out with no allowances for appliction rules
  resource defaultApplicationRuleCollectionGroup 'ruleCollectionGroups@2022-01-01' = if (deployAzureFirewall) {
    name: 'DefaultApplicationRuleCollectionGroup'
    dependsOn: [
      defaultNetworkRuleCollectionGroup
    ]
    properties: {
      priority: 300
      ruleCollections: [
        {
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          name: 'org-wide-allowed'
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: deployVirtualMachines ? [
            {
              ruleType: 'ApplicationRule'
              name: 'WindowsVirtualMachineHealth'
              description: 'Supports Windows Updates and Windows Diagnostics'
              fqdnTags: [
                'WindowsDiagnostics'
                'WindowsUpdate'
              ]
              protocols: [
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              sourceAddresses: [
                '10.200.0.0/24' // The subnet that contains the Windows VMs
              ]
            }
          ] : []
        }
      ]
    }
  }
}

@description('This is the regional Azure Firewall that all regional spoke networks can egress through.')
resource fwHub 'Microsoft.Network/azureFirewalls@2022-01-01' = if (deployAzureFirewall) {
  name: 'fw-${location}'
  location: location
  zones: [
    '1'
    '2'
    '3'
  ]
  dependsOn: [
    // This helps prevent multiple PUT updates happening to the firewall causing a CONFLICT race condition
    // Ref: https://learn.microsoft.com/azure/firewall-manager/quick-firewall-policy
    fwPolicy::defaultApplicationRuleCollectionGroup
    fwPolicy::defaultNetworkRuleCollectionGroup
  ]
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    firewallPolicy: {
      id: fwPolicy.id
    }
    ipConfigurations: [for i in range(0, numFirewallIpAddressesToAssign): {
      name: pipsAzureFirewall[i].name
      properties: {
        subnet: (0 == i) ? {
          id: vnetHub::azureFirewallSubnet.id
        } : null
        publicIPAddress: {
          id: pipsAzureFirewall[i].id
        }
      }
    }]
  }
}

resource fwHub_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployAzureFirewall) {
  name: 'to-hub-la'
  scope: fwHub
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}


@description('The public IP for the regional hub\'s Azure Bastion service.')
resource pipAzureBastion 'Microsoft.Network/publicIPAddresses@2022-01-01' = if (deployAzureBastion) {
  name: 'pip-ab-${location}'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

resource pipAzureBastion_diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployAzureBastion) {
  name: 'to-hub-la'
  scope: pipAzureBastion
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('This regional hub\'s Azure Bastion service. NSGs are configured to allow Bastion to reach any resource subnet in peered spokes.')
resource azureBastion 'Microsoft.Network/bastionHosts@2022-01-01' = if (deployAzureBastion) {
  name: 'ab-${location}-${suffix}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'hub-subnet'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnetHub::azureBastionSubnet.id
          }
          publicIPAddress: {
            id: pipAzureBastion.id
          }
        }
      }
    ]
  }
}

resource azureBastion_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployAzureBastion) {
  name: 'to-hub-la'
  scope: azureBastion
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

@description('The public IPs for the regional VPN gateway. Only deployed if requested.')
resource pipVpnGateway 'Microsoft.Network/publicIPAddresses@2022-01-01' = if (deployVpnGateway) {
  name: 'pip-vgw-${location}'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

resource pipVpnGateway_diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployVpnGateway) {
  name: 'to-hub-la'
  scope: pipVpnGateway
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('The is the regional VPN gateway, configured with basic settings. Only deployed if requested.')
resource vgwHub 'Microsoft.Network/virtualNetworkGateways@2022-01-01' = if (deployVpnGateway) {
  name: 'vgw-${location}-hub'
  location: location
  properties: {
    sku: {
      name: 'VpnGw2AZ'
      tier: 'VpnGw2AZ'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation2'
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipVpnGateway.id
          }
          subnet: {
            id: vnetHub::gatewaySubnet.id
          }
        }
      }
    ]
  }
}

resource vgwHub_diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployVpnGateway) {
  name: 'to-hub-la'
  scope: vgwHub
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('This is the Azure Virtual Network Manager which will be used to implement the connected group for spoke-to-spoke connectivity.')
resource networkManager 'Microsoft.Network/networkManagers@2022-05-01' = if (deployAvnm) {
  name: 'avnm-${location}-${suffix}'
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
  resource networkGroup 'networkGroups@2022-05-01' = {
    name: 'ng-${location}-spokes'
    properties: {
      description: 'Spoke VNETs Network Group'
    }
    resource staticMembersSpokeOne 'staticMembers@2022-05-01' = {
      name: 'sm-${location}-spokeone'
      properties: {
        resourceId: vnetSpokeOne.id
      }
    }
    resource staticMembersSpokeTwo 'staticMembers@2022-05-01' = {
      name: 'sm-${location}-spoketwo'
      properties: {
        resourceId: vnetSpokeTwo.id
      }
    }
  }
}

@description('This connectivity configuration defines the connectivity between the spokes. Only deployed if requested.')
resource connectivityConfiguration 'Microsoft.Network/networkManagers/connectivityConfigurations@2022-05-01' = if (deployAvnm) {
  name: 'cc-${location}-spokes'
  parent: networkManager
  dependsOn: [
    networkManager::networkGroup::staticMembersSpokeOne
    networkManager::networkGroup::staticMembersSpokeTwo
  ]
  properties: {
    description: 'Spoke-to-spoke connectivity configuration'
    appliesToGroups: [
      {
        networkGroupId: networkManager::networkGroup.id
        isGlobal: 'False'
        useHubGateway: 'False'
        groupConnectivity: 'DirectlyConnected'
      }
    ]
    connectivityTopology: 'HubAndSpoke'
    deleteExistingPeering: 'True'
    hubs: [ 
      {
        resourceId: vnetHub.id
        resourceType: 'Microsoft.Network/virtualNetworks'
      } 
    ]
    isGlobal: 'False'
  }
}

@description('This user assigned identity is used by the Deployment Script resource to interact with Azure resources.')
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = if (deployAvnm) {
  name: 'uai-${location}-${suffix}'
  location: location
}

@description('This role assignment grants the user assignmed identity the Contributor role on the resource group.')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (deployAvnm) {
  name: guid(resourceGroup().id, userAssignedIdentity.name)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor: b24988ac-6180-42a0-ab88-20f7382dd24c
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('Create a Deployment Script resource to perform the commit/deployment of the Network Manager connectivity configuration.')
resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = if (deployAvnm) {
  name: 'ds-${location}-${suffix}'
  location: location
  kind: 'AzurePowerShell'
  dependsOn: [
    roleAssignment
  ]
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '8.3'
    retentionInterval: 'PT1H'
    timeout: 'PT1H'
    arguments: '-uri "${environment().resourceManager}subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/networkManagers/${networkManager.name}/commit?api-version=2022-05-01" -location ${location} -connectivityConfigId ${connectivityConfiguration.id} -subscriptionId ${subscription().subscriptionId} -resourceManagerURL ${environment().resourceManager}'
    scriptContent: '''
    param (
      $resourceGroup,
      $subscriptionId,
      $networkManagerName,
      $resourceManagerURL,
      $connectivityConfigId,
      $location,
      [string]$uri
    )
    
    $DeploymentScriptOutputs = @{}
    $DeploymentScriptOutputs['text'] = ''

    $null = Login-AzAccount -Identity -Subscription $subscriptionId
    
    ### Deploy the connectivityConfiguration by calling the /commit endpoint via REST API ###
    $body = "{ `
      `"commitType`": `"Connectivity`", `
      `"configurationIds`": [`"$connectivityConfigId`"], `
      `"targetLocations`": [`"$location`"] `
    }"

    $result = Invoke-AzRestMethod -Method POST -URI "$uri" -Payload $body

    $DeploymentScriptOutputs['text'] += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]Commit status: $($result.statusCode)`n"
    $DeploymentScriptOutputs['text'] += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]Commit status: $($result)`n"
    
    If ($result.statusCode -ne 202) {
        throw "Failed to commit connectivity configuration. Status code: '$($result.statusCode)'"
        exit 1
    }
    Else {
      $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
      $timeout = New-TimeSpan -Seconds 300 # five minute timer
        do {
          $DeploymentScriptOutputs['text'] += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]Waiting 1 second for commit to complete...`n"
            Start-Sleep -Seconds 1
            $result = Invoke-AzRestMethod -Method GET -Uri $result.Headers.Location
        }
        until (($result.StatusCode -eq 204) -or ($timedOut = $stopwatch.elapsed -gt $timeout))

        If ($timedOut) {
          $DeploymentScriptOutputs['text'] += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]ERROR: waiting for commit has timed out...`n"
          throw "Waiting for commit to complete has timed out!"
          exit 1
        }
        Else {
          $DeploymentScriptOutputs['text'] += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]Commit completed successfully.`n"
        }
    }

    ### Now that commit has been successfully submitted, check for successful deployment of the commit ###
    # check deployment status
    $body = "{ `
    `"deploymentTypes`": `"Connectivity`", `
    `"regions`": [`"$location`"] `
    }"

    # update URL from /commit endpoint to /listDeploymentStatus endpoint
    $uri = $uri.Replace('/commit?', '/listDeploymentStatus?') 
    $result = Invoke-AzRestMethod -Method POST -URI $uri -Payload $body

    If ($result.statusCode -eq 200) {
      $content = $result.Content | ConvertFrom-Json -Depth 10

      If ($content.value[0].deploymentStatus -eq 'Deploying') {
        $DeploymentScriptOutputs['text'] += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]Deployment status: $($content.value[0].deploymentStatus); waiting for completion...`n"

        While ($content.value[0].deploymentStatus -eq 'Deploying') {
          $DeploymentScriptOutputs['text'] += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]Deployment status: $($content.value[0].deploymentStatus); waiting for completion...`n"
          Start-Sleep -Seconds 1
          $result = Invoke-AzRestMethod -Method POST -URI $uri -Payload $body
          $content = $result.Content | ConvertFrom-Json -Depth 10
        }
      }
      If ($content.value[0].deploymentStatus -eq 'Failed') {
        $DeploymentScriptOutputs['text'] += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]ERROR: deployment failed - '$($content.value[0].errorMessage)'...`n"
        throw "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]ERROR: deployment failed - ensure you are in a region that supports AVNM! Error message: '$($content.value[0].errorMessage)'"
        exit 1
      }
      ElseIf ($content.value[0].deploymentStatus -eq 'Deployed') {
        $DeploymentScriptOutputs['text'] += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]Deployment completed successfully.`n"
      }
      Else {
        $DeploymentScriptOutputs['text'] += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]ERROR: Deployment status: $($content.value[0].deploymentStatus) is not handled`n"
        throw "ERROR: Deployment status: $($content.value[0].deploymentStatus) is not handled"
        exit 1
      }
    }
    Else {
      $DeploymentScriptOutputs['text'] += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]ERROR: Failed to get deployment status. Status code: '$($result.statusCode)'`n"
      throw "ERROR: Failed to get deployment status. Status code: '$($result.statusCode)'"
      exit 1
    }

    '''
    }
}

/*** RESOURCES (ALL SPOKES) ***/

@description('Next hop to the regional hub\'s Azure Firewall')
resource routeNextHopToFirewall 'Microsoft.Network/routeTables@2022-01-01' = if (deployAzureFirewall) {
  name: 'route-to-${location}-hub-fw'
  location: location
  properties: {
    routes: [
      {
        name: 'r-nexthop-to-fw'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: fwHub.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

@description('NSG on the resource subnet (just using a common one for all as an example, but usually would be based on the specific needs of the spoke).')
resource nsgResourcesSubnet 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'nsg-spoke-resources'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowBastionRdpFromHub'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: vnetHub::azureBastionSubnet.properties.addressPrefix
          destinationPortRanges: [
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionSshFromHub'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: vnetHub::azureBastionSubnet.properties.addressPrefix
          destinationPortRanges: [
            '22'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      // No outbound restrictions.
    ]
  }
}

resource nsgResourcesSubnet_diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: nsgResourcesSubnet
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

@description('NSG on the Private Link subnet (just using a common one for all as an example, but usually would be based on the specific needs of the spoke).')
resource nsgPrivateLinkEndpointsSubnet 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'nsg-spoke-privatelinkendpoints'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAll443InFromVnet'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '443'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource nsgPrivateLinkEndpointsSubnet_diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: nsgPrivateLinkEndpointsSubnet
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

/*** RESOURCES (SPOKE ONE) ***/

resource vnetSpokeOne 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: 'vnet-${location}-spoke-one'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/22'
      ]
    }
    subnets: [
      {
        name: 'snet-resources'
        properties: {
          addressPrefix: '10.100.0.0/24'
          networkSecurityGroup: {
            id: nsgResourcesSubnet.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          routeTable: {
            id: routeNextHopToFirewall.id
          }
        }
      }
      {
        name: 'snet-privatelinkendpoints'
        properties: {
          addressPrefix: '10.100.1.0/26'
          networkSecurityGroup: {
            id: nsgPrivateLinkEndpointsSubnet.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: {
            id: routeNextHopToFirewall.id
          }
        }
      }
    ]
  }

  resource snetResources 'subnets' existing = {
    name: 'snet-resources'
  }

  // Peer to regional hub (hub to spoke peering is in the hub resource)
  resource peerToHub 'virtualNetworkPeerings@2022-01-01' = if (!deployAvnm) {
    name: 'to_${vnetHub.name}'
    properties: {
      allowForwardedTraffic: false
      allowGatewayTransit: false
      allowVirtualNetworkAccess: true
      useRemoteGateways: false
      remoteVirtualNetwork: {
        id: vnetHub.id
      }
    }
  }
}

resource vnetSpokeOne_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: vnetSpokeOne
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('The private Network Interface Card for the linux VM in spoke one.')
resource nicVmSpokeOneLinux 'Microsoft.Network/networkInterfaces@2022-01-01' = if (deployVirtualMachines) {
  name: 'nic-vm-${location}-spoke-one-linux'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: vnetSpokeOne::snetResources.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}

resource nicVmSpokeOneLinux_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployVirtualMachines) {
  scope: nicVmSpokeOneLinux
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('A basic Linux virtual machine that will be attached to spoke one.')
resource vmSpokeOneLinux 'Microsoft.Compute/virtualMachines@2022-03-01' = if (deployVirtualMachines) {
  name: 'vm-${location}-spoke-one-linux'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2ds_v4'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        caching: 'ReadOnly'
        diffDiskSettings: {
          option: 'Local'
          placement: 'CacheDisk'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      dataDisks: []
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: null
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicVmSpokeOneLinux.id
          properties: {
            deleteOption: 'Delete'
            primary: true
          }
        }
      ]
    }
    osProfile: {
      computerName: 'examplevm'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    priority: 'Regular'
  }
}

/*** RESOURCES (SPOKE TWO) ***/

resource vnetSpokeTwo 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: 'vnet-${location}-spoke-two'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.200.0.0/22'
      ]
    }
    subnets: [
      {
        name: 'snet-resources'
        properties: {
          addressPrefix: '10.200.0.0/24'
          networkSecurityGroup: {
            id: nsgResourcesSubnet.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          routeTable: {
            id: routeNextHopToFirewall.id
          }
        }
      }
      {
        name: 'snet-privatelinkendpoints'
        properties: {
          addressPrefix: '10.200.1.0/26'
          networkSecurityGroup: {
            id: nsgPrivateLinkEndpointsSubnet.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: {
            id: routeNextHopToFirewall.id
          }
        }
      }
    ]
  }

  resource snetResources 'subnets' existing = {
    name: 'snet-resources'
  }

  // Peer to regional hub (hub to spoke peering is in the hub resource)
  resource peerToHub 'virtualNetworkPeerings@2022-01-01' = if (!deployAvnm) {
    name: 'to_${vnetHub.name}'
    properties: {
      allowForwardedTraffic: false
      allowGatewayTransit: false
      allowVirtualNetworkAccess: true
      useRemoteGateways: false
      remoteVirtualNetwork: {
        id: vnetHub.id
      }
    }
  }
}

resource vnetSpokeTwo_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: vnetSpokeTwo
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('The private Network Interface Card for the Windows VM in spoke two.')
resource nicVmSpokeTwoLinux 'Microsoft.Network/networkInterfaces@2022-01-01' = if (deployVirtualMachines) {
  name: 'nic-vm-${location}-spoke-two-windows'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: vnetSpokeTwo::snetResources.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}

resource nicVmSpokeTwoLinux_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployVirtualMachines) {
  scope: nicVmSpokeTwoLinux
  name: 'to-hub-la'
  properties: {
    workspaceId: laHub.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('A basic Windows virtual machine that will be attached to spoke two.')
resource vmSpokeTwoWindows 'Microsoft.Compute/virtualMachines@2022-03-01' = if (deployVirtualMachines) {
  name: 'vm-${location}-spoke-two-windows'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      dataDisks: []
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: null
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicVmSpokeTwoLinux.id
          properties: {
            deleteOption: 'Delete'
            primary: true
          }
        }
      ]
    }
    osProfile: {
      computerName: 'examplevm'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    priority: 'Regular'
  }
}

// deployment uses a 'subscription' target scope in order to create resource group and policy
targetScope = 'subscription'

/*** PARAMETERS ***/

@description('The resource group name where the AVNM and VNET resources will be created')
param resourceGroupName string

@description('The location of this regional hub. All resources, including spoke resources, will be deployed to this region.')
@minLength(6)
param location string

// Network Group Membership Options:
//
// Static: Only the VNET IDs specified in the Network Group are part of the Connectivity Configurations
// Dynamic: Network Group membership is dynamic using Azure Policy, adding and removing Network Group members based on Policy rules
//
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

/*** RESOURCES (SPOKE D) - this VNET is left out of the Connected Group ***/
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
module policy 'modules/dynMemberPolicy.bicep' = if (networkGroupMembershipType == 'dynamic') {
  name: 'policy'
  scope: subscription()
  params: {
    networkGroupId: avnm.outputs.networkGroupId
    resourceGroupName: resourceGroupName
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
    networkGroupMembershipType: networkGroupMembershipType
  }
}

//
// In order to deploy a Connectivity or Security configruation, the /commit endpoint must be called or a Deployment created in the Portal. 
// This DeploymentScript resource executes a PowerShell script which calls the /commit endpoint and monitors the status of the deployment.
//
module deploymentScriptConnectivityConfigs 'modules/avnmDeploymentScript.bicep' = {
  name: 'ds-${location}-connectivityconfigs'
  scope: resourceGroup
  dependsOn: [
    policy
  ]
  params: {
    location: location
    userAssignedIdentityId: avnm.outputs.userAssignedIdentityId
    configurationId: avnm.outputs.connectivityConfigurationId
    configType: 'Connectivity'
    networkManagerName: avnm.outputs.networkManagerName
    deploymentScriptName: 'ds-${location}-connectivityconfigs'
  }
}

// output policy resource ids to facilitate cleanup
output policyDefinitionId string = policy.outputs.policyDefinitionId ?? 'not_deployed'
output policyAssignmentId string = policy.outputs.policyAssignmentId ?? 'not_deployed'

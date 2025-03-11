// deployment uses a 'subscription' target scope in order to create resource group and policy
targetScope = 'subscription'

/*** PARAMETERS ***/
@description('The user´s public SSH key that is added as authorized key to the Linux machines.')
param sshKey string

@description('Username for the test VMs deployed in the spokes; default: admin-avnm')
param adminUsername string = 'admin-avnm'

var connectivityTopology = 'hubAndSpoke'
var networkGroupMembershipType = 'dynamic'
var location = deployment().location
var resourceGroupName = 'rg-hub-spoke-${location}'

/*** RESOURCE GROUP ***/
resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name:  resourceGroupName
  location: location
}

/*** RESOURCES (HUB) ***/

module hub 'modules/hub.bicep' = {
  name: 'hub-resources-deployment-${location}'
  scope: resourceGroup
  params: {
  }
}

/*** RESOURCES (SPOKE 1) ***/
module spokeA 'modules/spoke.bicep' = {
  name: 'spoke1-resources-deployment-${location}'
  scope: resourceGroup
  params: {
    spokeName: '001'
    spokeVnetPrefix: '10.1.0.0/16'
    sshKey: sshKey
    adminUsername: adminUsername
  }
}

/*** RESOURCES (SPOKE 2) ***/
module spokeB 'modules/spoke.bicep' = {
  name: 'spoke2-resources-deployment-${location}'
  scope: resourceGroup
  params: {
    spokeName: '002'
    spokeVnetPrefix: '10.2.0.0/16'
    sshKey: sshKey
    adminUsername: adminUsername
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
    hubVnetId: hub.outputs.hubVnetId
    connectivityTopology: connectivityTopology
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
    userAssignedIdentityId: avnm.outputs.userAssignedIdentityId
    configurationId: avnm.outputs.connectivityConfigurationId
    configType: 'Connectivity'
    networkManagerName: avnm.outputs.networkManagerName
    deploymentScriptName: 'ds-${location}-connectivityconfigs'
  }
}

module deploymentScriptSecurityConfigs 'modules/avnmDeploymentScript.bicep' = {
  name: 'ds-${location}-securityadminconfigs'
  scope: resourceGroup
  dependsOn: [
    policy
  ]
  params: {
    userAssignedIdentityId: avnm.outputs.userAssignedIdentityId
    configurationId: avnm.outputs.securtyAdminConfigurationId
    configType: 'SecurityAdmin'
    networkManagerName: avnm.outputs.networkManagerName
    deploymentScriptName: 'ds-${location}-securityadminconfigs'
  }
}

// output policy resource ids to facilitate cleanup
output policyDefinitionId string = policy.outputs.policyDefinitionId ?? 'not_deployed'
output policyAssignmentId string = policy.outputs.policyAssignmentId ?? 'not_deployed'

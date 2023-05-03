// deployment uses a 'subscription' target scope in order to create resource group and policy
targetScope = 'subscription'

/*** PARAMETERS ***/

@description('The resource group name where the AVNM and VNET resources will be created')
param resourceGroupName string

@description('The location of this regional hub. All resources, including spoke resources, will be deployed to this region.')
@minLength(6)
param location string

@description('Password for the test VMs deployed in the spokes')
@secure()
param adminPassword string

@description('Username for the test VMs deployed in the spokes; default: admin-avnm')
param adminUsername string = 'admin-avnm'

var connectivityTopology = 'hubAndSpoke'
var networkGroupMembershipType = 'dynamic'

/*** RESOURCE GROUP ***/
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}

/*** RESOURCES (HUB) ***/

module hub 'modules/hub.bicep' = {
  name: 'hub-resources-deployment-${location}'
  scope: resourceGroup
  params: {
    location: location
    connectivityTopology: connectivityTopology
  }
}

/*** RESOURCES (SPOKE 1) ***/
module spokeA 'modules/spoke.bicep' = {
  name: 'spoke1-resources-deployment-${location}'
  scope: resourceGroup
  params: {
    location: location
    spokeName: '001'
    spokeVnetPrefix: '10.1.0.0/16'
    adminPassword: adminPassword
    adminUsername: adminUsername
  }
}

/*** RESOURCES (SPOKE 2) ***/
module spokeB 'modules/spoke.bicep' = {
  name: 'spoke2-resources-deployment-${location}'
  scope: resourceGroup
  params: {
    location: location
    spokeName: '002'
    spokeVnetPrefix: '10.2.0.0/16'
    adminPassword: adminPassword
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
    location: location
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
    location: location
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
    location: location
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

param location string
param userAssignedIdentityId string
param networkManagerName string
param configurationId string
param deploymentScriptName string
@allowed([
  'Connectivity'
])
param configType string

// the commit action is idempotent, so re-running the deployment will not cause any issues
@description('Create a Deployment Script resource to perform the commit/deployment of the Network Manager connectivity configuration.')
resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: deploymentScriptName
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    azPowerShellVersion: '8.3'
    retentionInterval: 'PT1H'
    timeout: 'PT1H'
    arguments: '-networkManagerName "${networkManagerName}" -location ${location} -configId ${configurationId} -subscriptionId ${subscription().subscriptionId} -configType ${configType} -resourceGroupName ${resourceGroup().name}'
    scriptContent: '''
    param (
      $subscriptionId,
      $networkManagerName,
      $configId,
      $location,
      $configType,
      $resourceGroupName
    )

    $null = Login-AzAccount -Identity -Subscription $subscriptionId

    [System.Collections.Generic.List[string]]$configIds = @()  
    $configIds.add($configId) 
    [System.Collections.Generic.List[string]]$target = @() # target locations for deployment
    $target.Add($location)     
    
    $deployment = @{
        Name = $networkManagerName
        ResourceGroupName = $resourceGroupName
        ConfigurationId = $configIds
        TargetLocation = $target
        CommitType = 'Connectivity'
    }

    try {
      Deploy-AzNetworkManagerCommit @deployment -ErrorAction Stop
    }
    catch {
      Write-Error "Deployment failed with error: $_"
      exit 1
    }
    '''
    }
}

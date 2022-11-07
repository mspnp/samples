param location string
param userAssignedIdentityId string
param networkManagerName string
param configurationId string
param deploymentScriptName string
@allowed([
  'Connectivity'
  'Security'
])
param configType string

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
    arguments: '-uri "${environment().resourceManager}subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/networkManagers/${networkManagerName}/commit?api-version=2022-05-01" -location ${location} -configId ${configurationId} -subscriptionId ${subscription().subscriptionId} -resourceManagerURL ${environment().resourceManager} -configType ${configType}'
    scriptContent: '''
    param (
      $resourceGroup,
      $subscriptionId,
      $networkManagerName,
      $resourceManagerURL,
      $configId,
      $location,
      $configType,
      [string]$uri
    )
    
    $DeploymentScriptOutputs = @{}
    $DeploymentScriptOutputs['text'] = ''

    $null = Login-AzAccount -Identity -Subscription $subscriptionId
    
    ### Deploy the connectivityConfiguration by calling the /commit endpoint via REST API ###
    $body = "{ `
      `"commitType`": `"$configType`", `
      `"configurationIds`": [`"$configId`"], `
      `"targetLocations`": [`"$location`"] `
    }"

    $result = Invoke-AzRestMethod -Method POST -URI "$uri" -Payload $body

    $DeploymentScriptOutputs['text'] += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]Commit status: $($result.statusCode)`n"
    $DeploymentScriptOutputs['text'] += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]Commit status: $($result)`n"
    
    If ($result.statusCode -ne 202) {
        throw "Failed to commit connectivity configuration. Status code: '$($result.statusCode)'; Message: '$($result.content)'"
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
    `"deploymentTypes`": `"$configType`", `
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
          Start-Sleep -Seconds 10
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

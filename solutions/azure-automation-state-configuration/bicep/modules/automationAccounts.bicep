
/*** PARAMETERS ***/

@description('Azure Virtual Machines, and supporting services (Automation State Configuration) region. This defaults to the resource group\'s location for higher reliability.')
param location string = resourceGroup().location

@description('Log Analytic Workspace where the logs will be sent')
param logAnalyticsName string

@description('The DSC configuration object containing a reference to the script that defines the desired state for Windows VMs. By default, it points to a PowerShell script that installs IIS for testing purposes as desired state of the system.')
param windowsConfiguration object = {
  name: 'windowsfeatures'
  description: 'A configuration for installing IIS.'
  script: 'https://raw.githubusercontent.com/mspnp/samples/main/solutions/azure-automation-state-configuration/scripts/windows-config.ps1'
}

@description('The DSC configuration object containing a reference to the script that defines the desired state for Linux VMs. By default, it points to a PowerShell script that installs NGINX for testing purposes as desired state of the system.')
param linuxConfiguration object = {
  name: 'linuxpackage'
  description: 'A configuration for installing Nginx.'
  script: 'https://raw.githubusercontent.com/mspnp/samples/main/solutions/azure-automation-state-configuration/scripts/linux-config.ps1'
}

/*** VARIABLES ***/

var automationAccountName = 'aa-${uniqueString(resourceGroup().id)}-${location}'

/*** RESOURCES ***/

@description('This Log Analytics workspace stores logs from the regional automation account and the virtual network.')
resource la 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsName
}


@description('The Automation Account to deliver consistent management across your Azure Windows and Linux Virtual Machines.')
resource aa 'Microsoft.Automation/automationAccounts@2023-05-15-preview' = {
  name: automationAccountName
  location: location
  properties: {
    sku: {
      name: 'Basic'
    }
  }

  @description('Azure Automation module with DSC Resources for Linux')
  resource aa_nx 'modules@2023-05-15-preview' = {
    name: 'nx'
    properties: {
      contentLink: {
        uri: 'https://devopsgallerystorage.blob.core.windows.net/packages/nx.1.0.0.nupkg'
      }
    }
  }

  @description('The Automation Account configuration for managing Linux DSC.')
  resource aa_linuxConfiguration 'configurations' = {
    name: linuxConfiguration.name
    location: location
    properties: {
      logVerbose: false
      description: linuxConfiguration.description
      source: {
        type: 'uri'
        value: linuxConfiguration.script
      }
    }
  }

  @description('The Automation Account compilation job for Linux DSC.')
  resource aa_compilationJobsLinuxConfiguration 'compilationjobs' = {
    name: aa_linuxConfiguration.name
    location: location
    properties: {
      configuration: {
        name: aa_linuxConfiguration.name
      }
    }
    dependsOn: [
      aa_nx
    ]
  }

  @description('The Automation Account configuration for managing Windows DSC.')
  resource aa_windowsConfiguration 'configurations' = {
    name: windowsConfiguration.name
    location: location
    properties: {
      logVerbose: false
      description: windowsConfiguration.description
      source: {
        type: 'uri'
        value: windowsConfiguration.script
      }
    }
  }

  @description('The Automation Account compilation job for Windows DSC.')
  resource aa_CompilationJobsWindowsConfiguration 'compilationjobs' = {
    name: windowsConfiguration.name
    location: location
    properties: {
      configuration: {
        name: windowsConfiguration.name
      }
    }
    dependsOn: [
      aa_windowsConfiguration
    ]
  }
}

@description('A diagnostic setting for the Automation Account that emits DSC Node Status logs. It is configured to enable log collection for monitoring and analysis, supporting the creation of saved and scheduled queries for alerting purposes.')
resource aa_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: aa
  name: 'aa-${la.name}'
  properties: {
    workspaceId: la.id
    logs: [
      {
        category: 'DscNodeStatus'
        enabled: true
      }
    ]
  }
}


output registrationURL string = aa.properties.registrationUrl
output keyValue string = aa.listKeys().keys[0].Value

 

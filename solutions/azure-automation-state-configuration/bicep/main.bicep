targetScope = 'resourceGroup'

/*** PARAMETERS ***/

@description('Azure Virtual Machines, and supporting services (Automation State Configuration) region. This defaults to the resource group\'s location for higher reliability.')
param location string = resourceGroup().location

@description('The admin user name for both the Windows and Linux virtual machines.')
param adminUserName string = 'admin-automation'

@secure()
@description('The admin password for both the Windows and Linux virtual machines.')
param adminPassword string

@description('The email address configured in the Action Group for receiving non-compliance notifications.')
param emailAddress string

@description('The number of Azure Windows VMs to be deployed as web servers, configured via Desired State Configuration to install IIS.')
@minValue(0)
param windowsVMCount int = 1

@description('The number of Azure Linux VMs to be deployed as web servers, configured via Desired State Configuration to install NGINX.')
@minValue(0)
param linuxVMCount int = 1

@description('The Azure VM size. Defaults to an optimally balanced for general purpose, providing sufficient performance for deploying IIS on Windows and NGINX on Linux in testing environments.')
param vmSize string = 'Standard_A4_v2'

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

var logAnalyticsName = 'log-${uniqueString(resourceGroup().id)}-${location}'
var alertQuery = 'AzureDiagnostics\n| where Category == "DscNodeStatus"\n| where ResultType == "Failed"'
var windowsVMName = 'vm-win-${location}'
var linuxVMname = 'vm-linux-${location}'

/*** RESOURCES ***/

@description('This Log Analytics workspace stores logs from the regional automation account and the virtual network.')
resource la 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    features: {
      searchVersion: 1
    }
  }
  @description('The Log Analytics workspace saved search to monitor Virtual Machines with Non-Compliant DSC status.')
  resource la_savedSearches 'savedSearches' = {
    name: '${la.name}-savedSearches'
    properties: {
      category: 'event'
      displayName: 'Non Compliant DSC Node'
      query: alertQuery
      version: 2
    }
  }
}

@description('The Log Analytics workspace scheduled query rule that trigger alerts based on Virtual Machines with Non-Compliant DSC status.')
resource la_nonCompliantDsc 'microsoft.insights/scheduledqueryrules@2024-01-01-preview' = {
  name: 'la-nonCompliantDsc'
  location: location
  properties: {
    severity: 3
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      la.id
    ]
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: alertQuery
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        ag_email.id
      ]
    }
  }
}

@description('The Action Group responsible for sending email notifications when Non-Compliant DSC alerts are triggered.')
resource ag_email 'microsoft.insights/actionGroups@2024-10-01-preview' = {
  name: 'ag-email'
  location: 'Global'
  properties: {
    groupShortName: 'emailService'
    enabled: true
    emailReceivers: [
      {
        name: 'emailAction'
        emailAddress: emailAddress
        useCommonAlertSchema: false
      }
    ]
  }
}

@description('Automation Account creation')
module automationAccount 'modules/automationAccounts.bicep' = {
  params:{
    logAnalyticsName:la.name
    linuxConfiguration: linuxConfiguration
    windowsConfiguration: windowsConfiguration
    location: location
  }
}

@description('Network creation')
module network './modules/network.bicep' = {
  params: {
    logAnalyticsName: la.name
    location: location
  }
}

@description('Create Network Interfaces and Public Ips for Windows VMS')
module windowsVMNetworkResources './modules/vmNetworkResources.bicep' = {
  params: {
    subnetId: network.outputs.subnetId
    location: location
    vMCount: windowsVMCount
    identifier: 'windows'
  }
}

@description('The Windows VMs managed by DSC. By default, these virtual machines are configured to enforce the desired state using the DSC VM extension, ensuring consistency and compliance.')
resource vm_windows 'Microsoft.Compute/virtualMachines@2024-11-01' = [
  for i in range(0, windowsVMCount): {
    name: '${windowsVMName}${i}'
    location: location
    identity: {
      // It is required by the Guest Configuration extension.
      type: 'SystemAssigned'
    }
    properties: {
      hardwareProfile: {
        vmSize: vmSize
      }
      osProfile: {
        computerName: '${windowsVMName}${i}'
        adminUsername: adminUserName
        adminPassword: adminPassword
        windowsConfiguration: {
          enableAutomaticUpdates: true
          patchSettings: {
            //Machines should be configured to periodically check for missing system updates
            assessmentMode: 'AutomaticByPlatform'
            patchMode: 'AutomaticByPlatform'
          }
        }
      }
      storageProfile: {
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2016-Datacenter'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: windowsVMNetworkResources.outputs.nics[i].resourceId
          }
        ]
      }
      securityProfile: {
        // We recommend enabling encryption at host for virtual machines and virtual machine scale sets to harden security.
        encryptionAtHost: false
      }
    }
  }
]

@description('Windows VM guest extension')
resource vm_guestConfigExtensionWindows 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [
  for i in range(0, windowsVMCount): {
    parent: vm_windows[i]
    name: 'AzurePolicyforWindows${vm_windows[i].name}'
    location: location
    properties: {
      publisher: 'Microsoft.GuestConfiguration'
      type: 'ConfigurationforWindows'
      typeHandlerVersion: '1.0'
      autoUpgradeMinorVersion: true
      enableAutomaticUpgrade: true
      settings: {}
      protectedSettings: {}
    }
  }
]

@description('Windows VM PowerShell DSC extension')
resource vm_powershellDSCWindows 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [
  for i in range(0, windowsVMCount): {
    name: '${vm_windows[i].name}/Microsoft.Powershell.DSC'
    location: location
    properties: {
      publisher: 'Microsoft.Powershell'
      type: 'DSC'
      typeHandlerVersion: '2.76'
      autoUpgradeMinorVersion: true
      protectedSettings: {
        Items: {
          registrationKeyPrivate: automationAccount.outputs.keyValue
        }
      }
      settings: {
        Properties: [
          {
            Name: 'RegistrationKey'
            Value: {
              UserName: 'PLACEHOLDER_DONOTUSE'
              Password: 'PrivateSettingsRef:registrationKeyPrivate'
            }
            TypeName: 'System.Management.Automation.PSCredential'
          }
          {
            Name: 'RegistrationUrl'
            #disable-next-line BCP053
            Value: automationAccount.outputs.registrationURL
            TypeName: 'System.String'
          }
          {
            Name: 'NodeConfigurationName'
            Value: '${windowsConfiguration.name}.localhost'
            TypeName: 'System.String'
          }
          {
            Name: 'ConfigurationMode'
            Value: 'ApplyAndMonitor'
            TypeName: 'System.String'
          }
          {
            Name: 'ConfigurationModeFrequencyMins'
            Value: 15
            TypeName: 'System.Int32'
          }
          {
            Name: 'RefreshFrequencyMins'
            Value: 30
            TypeName: 'System.Int32'
          }
          {
            Name: 'RebootNodeIfNeeded'
            Value: true
            TypeName: 'System.Boolean'
          }
          {
            Name: 'ActionAfterReboot'
            Value: 'ContinueConfiguration'
            TypeName: 'System.String'
          }
          {
            Name: 'AllowModuleOverwrite'
            Value: false
            TypeName: 'System.Boolean'
          }
        ]
      }
    }
  }
]

@description('Create Network Interfaces and Public Ips for Linux VMS')
module linuxVMNetworkResources './modules/vmNetworkResources.bicep' = {
  params: {
    subnetId: network.outputs.subnetId
    location: location
    vMCount: linuxVMCount
    identifier: 'linux'
  }
}

@description('The Linux VMs managed by DSC. By default, these virtual machines are configured to enforce the desired state using the DSC VM extension, ensuring consistency and compliance.')
resource vm_linux 'Microsoft.Compute/virtualMachines@2024-11-01' = [
  for i in range(0, linuxVMCount): {
    name: '${linuxVMname}${i}'
    location: location
    identity: {
      // It is required by the Guest Configuration extension.
      type: 'SystemAssigned'
    }
    properties: {
      hardwareProfile: {
        vmSize: vmSize
      }
      osProfile: {
        computerName: '${linuxVMname}${i}'
        adminUsername: adminUserName
        adminPassword: adminPassword
        linuxConfiguration: {
          patchSettings: {
            //Machines should be configured to periodically check for missing system updates
            assessmentMode: 'AutomaticByPlatform'
            patchMode: 'AutomaticByPlatform '
          }
          disablePasswordAuthentication: false
          provisionVMAgent: true
        }
      }
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: 'UbuntuServer'
          sku: '16.04.0-LTS'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: linuxVMNetworkResources.outputs.nics[i].resourceId
          }
        ]
      }
      securityProfile: {
        // We recommend enabling encryption at host for virtual machines and virtual machine scale sets to harden security.
        encryptionAtHost: false
      }
    }
  }
]

@description('Linux VM guest extension')
resource vm_guestConfigExtensionLinux 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [
  for i in range(0, linuxVMCount): {
    parent: vm_linux[i]
    name: 'Microsoft.AzurePolicyforLinux${vm_linux[i].name}'
    location: location
    properties: {
      publisher: 'Microsoft.GuestConfiguration'
      type: 'ConfigurationForLinux'
      typeHandlerVersion: '1.0'
      autoUpgradeMinorVersion: true
      enableAutomaticUpgrade: true
      settings: {}
      protectedSettings: {}
    }
  }
]

@description('Linux VM DSC extension')
resource vm_enableDCLExtemsionLinux 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [
  for i in range(0, linuxVMCount): {
    name: '${vm_linux[i].name}/enabledsc'
    location: location
    properties: {
      publisher: 'Microsoft.OSTCExtensions'
      type: 'DSCForLinux'
      typeHandlerVersion: '2.7'
      autoUpgradeMinorVersion: true
      settings: {
        ExtensionAction: 'Register'
        NodeConfigurationName: '${linuxConfiguration.name}.localhost'
        RefreshFrequencyMins: 30
        ConfigurationMode: 'applyAndAutoCorrect'
        ConfigurationModeFrequencyMins: 15
        RegistrationUrl: automationAccount.outputs.registrationURL
      }
      protectedSettings: {
        RegistrationKey: automationAccount.outputs.keyValue
      }
    }
  }
]

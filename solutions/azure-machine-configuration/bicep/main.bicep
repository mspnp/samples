targetScope = 'resourceGroup'

/*** PARAMETERS ***/

@description('Azure Virtual Machines, and supporting services (Automation State Configuration) region. This defaults to the resource group\'s location for higher reliability.')
param location string = resourceGroup().location

@description('The admin user name for both the Windows and Linux virtual machines.')
param adminUserName string = 'user-admin'

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

@description('User identity ID to be assignd to the VM with permissions to download the DSC configuration from the storage account.')
param policyUserAssignedIdentityId string

/*** VARIABLES ***/

var logAnalyticsName = 'log-${uniqueString(resourceGroup().id)}-${location}'
var rawAlertQuery = '''
arg("").PolicyResources
| where resourceGroup == 'resourceGroupName'
| where type == 'microsoft.policyinsights/policystates'
| extend complianceState = properties.complianceState
| where complianceState == 'NonCompliant'
| extend policyAssignmentName = properties.policyAssignmentName
| where policyAssignmentName == 'nginx-install-assignment' or policyAssignmentName == 'IIS-install-assignment'
| extend resourceId = properties.resourceId
| project resourceId
'''
var windowsVMName = 'vm-win-${location}'
var linuxVMname = 'vm-linux-${location}'
var alertQuery = replace(rawAlertQuery, 'resourceGroupName', resourceGroup().name)
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
  identity: {
    type: 'SystemAssigned'
  }
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
  dependsOn: [
    la::la_savedSearches
    vm_windows
    vm_linux
  ]
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

@description('Network creation')
module network './modules/network.bicep' = {
  params: {
    logAnalyticsName: la.name
    location: location
  }
}

@description('Create Network Interfaces and Public IPs for Windows VMs')
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
      // SystemAssigned is required by the Guest Configuration extension. UserAssigned is required to download the DSC configuration from the storage account
      type: 'SystemAssigned, UserAssigned'
      userAssignedIdentities: {
        '${policyUserAssignedIdentityId}': {}
      }
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
          sku: '2022-Datacenter'
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
    name: 'AzurePolicyforWindows'
    location: location
    properties: {
      publisher: 'Microsoft.GuestConfiguration'
      type: 'ConfigurationforWindows'
      typeHandlerVersion: '1.29'
      autoUpgradeMinorVersion: true
      enableAutomaticUpgrade: true
      settings: {}
      protectedSettings: {}
    }
  }
]

@description('Create Network Interfaces and Public IPs for Linux VMs')
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
      // SystemAssigned is required by the Guest Configuration extension. UserAssigned is required to download the DSC configuration from the storage account
      type: 'SystemAssigned, UserAssigned'
      userAssignedIdentities: {
        '${policyUserAssignedIdentityId}': {}
      }
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
            patchMode: 'AutomaticByPlatform'
          }
          disablePasswordAuthentication: false
          provisionVMAgent: true
        }
      }
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: '0001-com-ubuntu-server-focal'
          sku: '20_04-lts'
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
    name: 'AzurePolicyforLinux'
    location: location
    properties: {
      publisher: 'Microsoft.GuestConfiguration'
      type: 'ConfigurationForLinux'
      typeHandlerVersion: '1.26'
      autoUpgradeMinorVersion: true
      enableAutomaticUpgrade: true
      settings: {}
      protectedSettings: {}
    }
  }
]

output alertSystemObjectId string = la_nonCompliantDsc.identity.principalId

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

var logAnalyticsName = 'log-${uniqueString(resourceGroup().id)}-${location}'
var automationAccountName = 'aa-${uniqueString(resourceGroup().id)}-${location}'
var alertQuery = 'AzureDiagnostics\n| where Category == "DscNodeStatus"\n| where ResultType == "Failed"'
var windowsPIPName = 'pip-windows-${location}'
var windowsVMName = 'vm-win-${location}'
var linuxPIPName = 'pip-linux-${location}'
var linuxVMname  = 'vm-linux-${location}'

//https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations

@description('This Log Analytics Workspace stores logs from various resources')
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
}

@description('Non Compliant DSC query saved on Log Analytics Workpace')
resource la_savedSearches 'Microsoft.OperationalInsights/workspaces/savedSearches@2023-09-01' = {
  parent: la
  name: '${la.name}-savedSearches'
  properties: {
    category: 'event'
    displayName: 'Non Compliant DSC Node'
    query: alertQuery
    version: 2
  }
}

@description('Non Compliant DSC Alert based on Query')
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
          threshold: json('0')
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

@description('Action Group to send an email when an alert is detected')
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

@description('Azure Automation delivers a cloud-based automation service that supports consistent management across your Azure and non-Azure environments. ')
resource aa 'Microsoft.Automation/automationAccounts@2023-05-15-preview' = {
  name: automationAccountName
  location: location
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

@description('Azure Automation module with DSC Resources for Linux')
resource aa_nx 'Microsoft.Automation/automationAccounts/modules@2023-05-15-preview' = {
  parent: aa
  name: 'nx'
  properties: {
    contentLink: {
      uri: 'https://devopsgallerystorage.blob.core.windows.net/packages/nx.1.0.0.nupkg'
    }
  }
}

@description('Azure Automation Linux Configuration')
resource aa_linuxConfiguration 'Microsoft.Automation/automationAccounts/configurations@2023-05-15-preview' = {
  parent: aa
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

@description('Azure Automation Linux Configuration Job')
resource aa_compilationJobsLinuxConfiguration 'Microsoft.Automation/automationAccounts/compilationjobs@2023-05-15-preview' = {
  parent: aa
  name: linuxConfiguration.name
  location: location
  properties: {
    configuration: {
      name: linuxConfiguration.name
    }
  }
  dependsOn: [
    aa_linuxConfiguration
    aa_nx
  ]
}

@description('Azure Automation Windows Configuration')
resource aa_windowsConfiguration 'Microsoft.Automation/automationAccounts/configurations@2023-05-15-preview' = {
  parent: aa
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

@description('Azure Automation Windows Configuration Job')
resource aa_CompilationJobsWindowsConfiguration 'Microsoft.Automation/automationAccounts/compilationjobs@2023-05-15-preview' = {
  parent: aa
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


@description('Azure Automation logs')
resource aa_diagnosticSettings 'Microsoft.Automation/automationAccounts/providers/diagnosticSettings@2021-05-01-preview' = {
  name: '${automationAccountName}/Microsoft.Insights/default${logAnalyticsName}'
  properties: {
    workspaceId: la.id
    logs: [
      {
        category: 'DscNodeStatus'
        enabled: true
      }
    ]
  }
  dependsOn: [
    aa
  ]
}

@description('Network security group to control traffic on the vnet')
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: 'Tcp'
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
        name: 'HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '80'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

@description('Network Security Grpup log')
resource nsg_diagnosticSettings 'Microsoft.Network/networkSecurityGroups/providers/diagnosticSettings@2021-05-01-preview' = {
  name: 'nsg/Microsoft.Insights/default${logAnalyticsName}'
  properties: {
    workspaceId: la.id
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
      }
    ]
  }
  dependsOn: [
    nsg
  ]
}

@description('Virtual Network')
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
  dependsOn: [
    nsg
  ]
}

@description('Virtual Network subnet')
resource snet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'subnet'
  properties: {
    addressPrefix: '10.0.0.0/24'
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

@description('Public ips for windows VMs')
resource pip_windows 'Microsoft.Network/publicIPAddresses@2024-05-01' = [
  for i in range(0, windowsVMCount): {
    name: '${windowsPIPName}${i}'
    location: location
    properties: {
      publicIPAllocationMethod: 'Dynamic'
    }
  }
]

@description('Network Interfaces for windows VMs')
resource nic_windows 'Microsoft.Network/networkInterfaces@2024-05-01' = [
  for i in range(0, windowsVMCount): {
    name: 'nic-windows-${i}'
    location: location
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            publicIPAddress: {
              id: pip_windows[i].id
            }
            subnet: {
              id: sbnet.id
            }
          }
        }
      ]
    }
    dependsOn: [
      pip_windows
    ]
  }
]

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
            id: nic_windows[i].id
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
// https://learn.microsoft.com/azure/virtual-machines/extensions/guest-configuration#bicep-template
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
    name: '${windowsVMName}${i}/Microsoft.Powershell.DSC'
    location: location
    properties: {
      publisher: 'Microsoft.Powershell'
      type: 'DSC'
      typeHandlerVersion: '2.76'
      autoUpgradeMinorVersion: true
      protectedSettings: {
        Items: {
          registrationKeyPrivate: listKeys(aa.id, '2019-06-01').Keys[0].value
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
            Value: aa.properties.registrationUrl
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
    dependsOn: [
      vm_windows
    ]
  }
]

@description('Public IPs for Linux VMs')
resource pip_linux 'Microsoft.Network/publicIPAddresses@2024-05-01' = [
  for i in range(0, linuxVMCount): {
    name: '${linuxPIPName}${i}'
    location: location
    properties: {
      publicIPAllocationMethod: 'Dynamic'
    }
  }
]

@description('Network Interfaces for linux VMs')
resource nic_linux 'Microsoft.Network/networkInterfaces@2024-05-01' = [
  for i in range(0, linuxVMCount): {
    name: 'nic-linux-${i}'
    location: location
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            publicIPAddress: {
              id: pip_linux[i].id
            }
            subnet: {
              id: sbnet.id
            }
          }
        }
      ]
    }
    dependsOn: [
      pip_linux
    ]
  }
]

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
            id: nic_linux[i].id
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
// https://learn.microsoft.com/azure/virtual-machines/extensions/guest-configuration#bicep-template
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
    name: '${linuxVMname }${i}/enabledsc'
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
        RegistrationUrl: aa.properties.registrationUrl
      }
      protectedSettings: {
        RegistrationKey: listKeys(aa.id, '2019-06-01').Keys[0].value
      }
    }
    dependsOn: [
      vm_linux
    ]
  }
]

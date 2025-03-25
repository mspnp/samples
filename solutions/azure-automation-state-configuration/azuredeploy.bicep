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
param windowsVMCount int = 1

@description('The number of Azure Linux VMs to be deployed as web servers, configured via Desired State Configuration to install NGINX.')
param linuxVMCount int = 1

@description('SKU of the Vms')
param vmSize string = 'Standard_DS1_v2'

@description('Windows VMs configurations')
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

@description('Virtual Network address space')
param addressPrefix string = '10.0.0.0/16'

@description('Virtual Network dubnet address space')
param subnetPrefix string = '10.0.0.0/24'

var virtualNetworkName = 'virtial-network'
var subnetName = 'subnet'
var logAnalyticsName = uniqueString(resourceGroup().id)
var automationAccountName = uniqueString(resourceGroup().id)
var moduleUri = 'https://devopsgallerystorage.blob.core.windows.net/packages/nx.1.0.0.nupkg'
var subnetRef = virtualNetworkName_subnet.id
var alertQuery = 'AzureDiagnostics\n| where Category == "DscNodeStatus"\n| where ResultType == "Failed"'
var windowsNicName = 'windows-nic-'
var windowsPIPName = 'windows-pip-'
var windowsVMName = 'windows-vm-'
var windowsOSVersion = '2016-Datacenter'
var linuxNicName = 'linux-nic-'
var linuxPIPName = 'linux-pip-'
var linuxVMNAme = 'linux-vm-'
var osVersion = '16.04.0-LTS'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
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

resource logAnalytics_savedSearches 'Microsoft.OperationalInsights/workspaces/savedSearches@2023-09-01' = {
  parent: logAnalytics
  name: '${logAnalyticsName}_savedSearches'
  properties: {
    category: 'event'
    displayName: 'Non Compliant DSC Node'
    query: alertQuery
    version: 2
  }
}

resource non_compliant_dsc 'microsoft.insights/scheduledqueryrules@2024-01-01-preview' = {
  name: 'non-compliant-dsc'
  location: location
  properties: {
    severity: 3
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      logAnalytics.id
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
        email_action.id
      ]
    }
  }
}

resource email_action 'microsoft.insights/actionGroups@2024-10-01-preview' = {
  name: 'email-action'
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

resource automationAccount 'Microsoft.Automation/automationAccounts@2023-05-15-preview' = {
  name: automationAccountName
  location: location
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource automationAccountName_nx 'Microsoft.Automation/automationAccounts/modules@2023-05-15-preview' = {
  parent: automationAccount
  name: 'nx'
  properties: {
    contentLink: {
      uri: moduleUri
    }
  }
}

resource automationAccountName_linuxConfiguration_name 'Microsoft.Automation/automationAccounts/configurations@2023-05-15-preview' = {
  parent: automationAccount
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

resource Microsoft_Automation_automationAccounts_compilationjobs_automationAccountName_linuxConfiguration_name 'Microsoft.Automation/automationAccounts/compilationjobs@2023-05-15-preview' = {
  parent: automationAccount
  name: linuxConfiguration.name
  location: location
  properties: {
    configuration: {
      name: linuxConfiguration.name
    }
  }
  dependsOn: [
    automationAccountName_linuxConfiguration_name
    automationAccountName_nx
  ]
}

resource automationAccountName_windowsConfiguration_name 'Microsoft.Automation/automationAccounts/configurations@2023-05-15-preview' = {
  parent: automationAccount
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

resource Microsoft_Automation_automationAccounts_compilationjobs_automationAccountName_windowsConfiguration_name 'Microsoft.Automation/automationAccounts/compilationjobs@2023-05-15-preview' = {
  parent: automationAccount
  name: windowsConfiguration.name
  location: location
  properties: {
    configuration: {
      name: windowsConfiguration.name
    }
  }
  dependsOn: [
    automationAccountName_windowsConfiguration_name
  ]
}

resource automationAccountName_Microsoft_Insights_default_logAnalytics 'Microsoft.Automation/automationAccounts/providers/diagnosticSettings@2021-05-01-preview' = {
  name: '${automationAccountName}/Microsoft.Insights/default${logAnalyticsName}'
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'DscNodeStatus'
        enabled: true
      }
    ]
  }
  dependsOn: [
    automationAccount
  ]
}

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

resource nsg_Microsoft_Insights_default_logAnalytics 'Microsoft.Network/networkSecurityGroups/providers/diagnosticSettings@2021-05-01-preview' = {
  name: 'nsg/Microsoft.Insights/default${logAnalyticsName}'
  properties: {
    workspaceId: logAnalytics.id
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

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
  }
  dependsOn: [
    nsg
  ]
}

resource virtualNetworkName_subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: virtualNetwork
  name: subnetName
  properties: {
    addressPrefix: subnetPrefix
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource windowsPIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = [
  for i in range(0, windowsVMCount): {
    name: '${windowsPIPName}${i}'
    location: location
    properties: {
      publicIPAllocationMethod: 'Dynamic'
    }
  }
]

resource windowsNic 'Microsoft.Network/networkInterfaces@2024-05-01' = [
  for i in range(0, windowsVMCount): {
    name: '${windowsNicName}${i}'
    location: location
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            publicIPAddress: {
              id: resourceId('Microsoft.Network/publicIPAddresses/', '${windowsPIPName}${i}')
            }
            subnet: {
              id: subnetRef
            }
          }
        }
      ]
    }
    dependsOn: [
      windowsPIP
    ]
  }
]

resource windowsVM 'Microsoft.Compute/virtualMachines@2024-11-01' = [
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
          sku: windowsOSVersion
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: resourceId('Microsoft.Network/networkInterfaces', windowsNic[i].name)
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

// https://learn.microsoft.com/azure/virtual-machines/extensions/guest-configuration#bicep-template
resource guestConfigExtensionWindows 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [
  for i in range(0, windowsVMCount): {
    parent: windowsVM[i]
    name: 'AzurePolicyforWindows${windowsVM[i].name}'
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

resource windowsVMName_Microsoft_Powershell_DSC 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [
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
          registrationKeyPrivate: listKeys(automationAccount.id, '2019-06-01').Keys[0].value
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
            Value: automationAccount.properties.registrationUrl
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
      windowsVM
    ]
  }
]

resource linuxPIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = [
  for i in range(0, linuxVMCount): {
    name: '${linuxPIPName}${i}'
    location: location
    properties: {
      publicIPAllocationMethod: 'Dynamic'
    }
  }
]

resource linuxNic 'Microsoft.Network/networkInterfaces@2024-05-01' = [
  for i in range(0, linuxVMCount): {
    name: '${linuxNicName}${i}'
    location: location
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            publicIPAddress: {
              id: resourceId('Microsoft.Network/publicIPAddresses/', '${linuxPIPName}${i}')
            }
            subnet: {
              id: subnetRef
            }
          }
        }
      ]
    }
    dependsOn: [
      linuxPIP
    ]
  }
]

resource linuxVMN 'Microsoft.Compute/virtualMachines@2024-11-01' = [
  for i in range(0, linuxVMCount): {
    name: '${linuxVMNAme}${i}'
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
        computerName: '${linuxVMNAme}${i}'
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
          sku: osVersion
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: resourceId('Microsoft.Network/networkInterfaces', linuxNic[i].name)
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

// https://learn.microsoft.com/azure/virtual-machines/extensions/guest-configuration#bicep-template
resource guestConfigExtensionLinux 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [
  for i in range(0, linuxVMCount): {
    parent: linuxVMN[i]
    name: 'Microsoft.AzurePolicyforLinux${linuxVMN[i].name}'
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

resource linuxVMNAme_enabledsc 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [
  for i in range(0, linuxVMCount): {
    name: '${linuxVMNAme}${i}/enabledsc'
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
        RegistrationUrl: automationAccount.properties.registrationUrl
      }
      protectedSettings: {
        RegistrationKey: listKeys(automationAccount.id, '2019-06-01').Keys[0].value
      }
    }
    dependsOn: [
      linuxVMN
    ]
  }
]

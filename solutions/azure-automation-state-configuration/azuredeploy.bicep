param location string = resourceGroup().location

param adminUserName string

@description('your public key. Authentication to Linux machines should require SSH keys.')
param sshKey string
@secure()
param adminPassword string
param emailAddress string
param windowsVMCount int = 1
param linuxVMCount int = 1
param vmSize string = 'Standard_DS1_v2'
param windowsConfiguration object = {
  name: 'windowsfeatures'
  description: 'A configuration for installing IIS.'
  script: 'https://raw.githubusercontent.com/mspnp/samples/main/solutions/azure-automation-state-configuration/scripts/windows-config.ps1'
}
param linuxConfiguration object = {
  name: 'linuxpackage'
  description: 'A configuration for installing Nginx.'
  script: 'https://raw.githubusercontent.com/mspnp/samples/main/solutions/azure-automation-state-configuration/scripts/linux-config.ps1'
}
param virtualNetworkName string = 'virtial-network'
param addressPrefix string = '10.0.0.0/16'
param subnetPrefix string = '10.0.0.0/24'
param subnetName string = 'subnet'

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

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
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

resource logAnalyticsName_91192b47_5f04_4215_a142_1fcb2b1622b1 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: logAnalytics
  name: '91192b47-5f04-4215-a142-1fcb2b1622b1'
  properties: {
    category: 'event'
    displayName: 'Non Compliant DSC Node'
    query: alertQuery
    version: 2
  }
}

resource non_compliant_dsc 'microsoft.insights/scheduledqueryrules@2018-04-16' = {
  name: 'non-compliant-dsc'
  location: location
  properties: {
    enabled: 'true'
    source: {
      query: alertQuery
      dataSourceId: logAnalytics.id
      queryType: 'ResultCount'
    }
    schedule: {
      frequencyInMinutes: 5
      timeWindowInMinutes: 5
    }
    action: {
      severity: '3'
      aznsAction: {
        actionGroup: [
          email_action.id
        ]
      }
      trigger: {
        thresholdOperator: 'GreaterThan'
        threshold: 0
      }
      'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.Microsoft.AppInsights.Nexus.DataContracts.Resources.ScheduledQueryRules.AlertingAction'
    }
  }
}

resource email_action 'microsoft.insights/actionGroups@2023-01-01' = {
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

resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: automationAccountName
  location: location
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource automationAccountName_nx 'Microsoft.Automation/automationAccounts/modules@2023-11-01' = {
  parent: automationAccount
  name: 'nx'
  properties: {
    contentLink: {
      uri: moduleUri
    }
  }
}

resource automationAccountName_linuxConfiguration_name 'Microsoft.Automation/automationAccounts/configurations@2023-11-01' = {
  parent: automationAccount
  name: '${linuxConfiguration.name}'
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
  name: '${linuxConfiguration.name}'
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
  name: '${windowsConfiguration.name}'
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
  name: '${windowsConfiguration.name}'
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

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
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

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
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

resource virtualNetworkName_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: virtualNetwork
  name: subnetName
  properties: {
    addressPrefix: subnetPrefix
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource windowsPIP 'Microsoft.Network/publicIPAddresses@2023-11-01' = [
  for i in range(0, windowsVMCount): {
    name: '${windowsPIPName}${i}'
    location: location
    properties: {
      publicIPAllocationMethod: 'Dynamic'
    }
  }
]

resource windowsNic 'Microsoft.Network/networkInterfaces@2023-11-01' = [
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

resource windowsVM 'Microsoft.Compute/virtualMachines@2023-09-01' = [
  for i in range(0, windowsVMCount): {
    name: '${windowsVMName}${i}'
    location: location
    identity: {
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
            id: resourceId('Microsoft.Network/networkInterfaces', '${windowsNicName}${i}')
          }
        ]
      }
      securityProfile: {
        //Virtual machines and virtual machine scale sets should have encryption at host enabled
        encryptionAtHost: true
      }
    }
    dependsOn: [
      windowsNic
    ]
  }
]

resource guestConfigExtensionWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [
  for i in range(0, windowsVMCount): {
    parent: windowsVM[i]
    name: 'Microsoft.GuestConfiguration${windowsVM[i].name}'
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

resource windowsVMName_Microsoft_Powershell_DSC 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [
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

resource linuxPIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = [
  for i in range(0, linuxVMCount): {
    name: '${linuxPIPName}${i}'
    location: location
    properties: {
      publicIPAllocationMethod: 'Dynamic'
    }
  }
]

resource linuxNic 'Microsoft.Network/networkInterfaces@2023-09-01' = [
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

resource linuxVMN 'Microsoft.Compute/virtualMachines@2023-09-01' = [
  for i in range(0, linuxVMCount): {
    name: '${linuxVMNAme}${i}'
    location: location
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      hardwareProfile: {
        vmSize: vmSize
      }
      osProfile: {
        computerName: '${linuxVMNAme}${i}'
        adminUsername: adminUserName
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                path: '/home/${adminUserName}/.ssh/authorized_keys'
                keyData: sshKey
              }
            ]
          }
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
            id: resourceId('Microsoft.Network/networkInterfaces', '${linuxNicName}${i}')
          }
        ]
      }
      securityProfile: {
        //Virtual machines and virtual machine scale sets should have encryption at host enabled
        encryptionAtHost: true
      }
    }
    dependsOn: [
      linuxNic
    ]
  }
]

resource guestConfigExtensionLinux 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [
  for i in range(0, linuxVMCount): {
    parent: linuxVMN[i]
    name: 'Microsoft.GuestConfiguration${linuxVMN[i].name}'
    location: location
    properties: {
      publisher: 'Microsoft.GuestConfiguration'
      type: 'ConfigurationforLinux'
      typeHandlerVersion: '1.0'
      autoUpgradeMinorVersion: true
      enableAutomaticUpgrade: true
      settings: {}
      protectedSettings: {}
    }
  }
]

resource linuxVMNAme_enabledsc 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [
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

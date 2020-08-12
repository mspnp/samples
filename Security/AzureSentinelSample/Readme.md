## Azure Sentinel Sample

In this sample you create an Azure Log Analytics workspace, which is required if you want to start collecting, analyzing, and taking action on data, and an Azure Sentinel on top of it. [Azure Sentinel](https://docs.microsoft.com/azure/sentinel/overview) is a cloud-native SIEM (security instant and event management) service that runs in Azure.

This Powershell script makes use [PowerShell module for Azure Sentinel](https://github.com/wortell/AZSentinel) to setup the service. 

The script also installs an Azure Application Gateway as sample (ARM template is provided in the sample and used by the PS script), after you run it, you can manually configure a diagnostics setting to connect the App Gateway to the Log Analytics Workspace installed before. Behind the scenes, you are connecting Azure Sentinel to the Azure Application Gateway’s web application firewall (WAF). This WAF protects your applications from common web vulnerabilities such as SQL injection and cross-site scripting, and lets you customize rules to reduce false positives.​

### Prerequisites
 - Powershell 6.2.4 or higher version
 - PowerShell Core
 - Powershell AZ Module - tested with version 2.4.0
 - An Azure subscription

### Instructions
1) Run the powerhsell script, by using this command:

```Powershell
.\AzSentinelSetup.ps1 -Location westus -SubscriptionId [your azure subscription Id] -ResourceGroupName [your azure resource group] -WorkspaceName [your log analytics workspace name] 
```

2) Inside your Application Gateway resource:

    - Select Diagnostic settings under monitoring section.​
    - Select "Add diagnostics setting".​
    - In the Diagnostics setting blade:
        - Type a Name.
        - Select Send to Log Analytics.
        - Choose the log destination workspace.​
        - Select the log types that you want to analyze (recommended: ‘ApplicationGatewayAccessLog’ and ‘ApplicationGatewayFirewallLog’).
        - Select ’All metrics"’
        - Click Save.
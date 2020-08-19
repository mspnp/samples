## Azure Sentinel and WAF connector Sample

In this sample you create an Azure Log Analytics workspace, which is required if you want to start collecting, analyzing, and taking action on data, and an Azure Sentinel on top of it. [Azure Sentinel](https://docs.microsoft.com/azure/sentinel/overview) is a cloud-native SIEM (security instant and event management) service that runs in Azure.

The script also installs an Azure Application Gateway as sample (ARM template is provided in the sample and used by the PS script), after you run it, you can manually configure a diagnostics setting to connect the App Gateway to the Log Analytics Workspace installed before. Behind the scenes, you are connecting Azure Sentinel to the Azure Application Gateway’s web application firewall (WAF). This WAF protects your applications from common web vulnerabilities such as SQL injection and cross-site scripting, and lets you customize rules to reduce false positives.​

### Prerequisites
 - Powershell 6.2.4 or higher version
 - PowerShell Core
 - Powershell AZ Module - tested with version 2.4.0
 - An Azure subscription

### Instructions

**Since the script acquires an access token to authorize a call to the management API you will need to provide yout Azure Tenant Id, your client Id and secret.**

1) Run the powerhsell script, by using this command:

```Powershell

.\AzSentinelSetup.ps1 -Location westus -TenantId [your azure tenant id] -ClientId [your application id] -ClientSecret [your client secret] -SubscriptionId [your azure subscription Id] -ResourceGroupName [your azure resource group] -WorkspaceName [your log analytics workspace name] 
```

2) Inside your Application Gateway resource (In Azure Portal):

    - Select Diagnostic settings under monitoring section.​
    - Select "Add diagnostics setting".​
    - In the Diagnostics setting blade:
        - Type a Name.
        - Select Send to Log Analytics.
        - Choose the log destination workspace.​
        - Select the log types that you want to analyze (recommended: ‘ApplicationGatewayAccessLog’ and ‘ApplicationGatewayFirewallLog’).
        - Select ’All metrics"’
        - Click Save.

## Visualizing and monitoring the data using workbooks

Once you have connected your data sources to Azure Sentinel, you can visualize and monitor the data using the Azure Sentinel adoption of Azure Monitor Workbooks. Azure Sentinel allows you to create custom workbooks across your data, and also comes with built-in workbook templates to allow you to quickly gain insights across your data as soon as you connect a data source.

This sample provides a ARM template that defines a workbook as an example of how to query the failed access requests to you Azure Application Gateway created in the steps above.  If you take a look at the template code, you will find the query embedded in the "serializedData" element.

```
// Failed requests per hour 
// Count of requests to which Application Gateway responded with an error. 
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS" and OperationName == "ApplicationGatewayAccess" and httpStatus_d > 399
| summarize AggregatedValue = count() by bin(TimeGenerated, 1h)
| render timechart
```

Alternatively, you can use your own queries by modifying the "serializedData" element. [Click here](https://docs.microsoft.com/azure/azure-monitor/log-query/get-started-queries) to get started with log analytics queries.


### Creating the workbook programmatically

To create the workbook, run the following Powershell command, the "WorkbookSourceId" parameter is the container where you want to create the workbook in, in this case the Azure Sentinel resurce Id, it should look like this:

/subscriptions/[your subscriptionId]/resourceGroups/[your resource group name]/providers/Microsoft.OperationsManagement/solutions/SecurityInsights([your log analytics workspace name])


```Powershell
New-AzResourceGroupDeployment -ResourceGroupName [your resource group] -TemplateFile .\FailedRequestsWorkbook.json -WorkbookSourceId "[your workboox source Id]" -workbookDisplayName FailedRequestsWorkbookSample
```

After you created the workbook, you can see it in the portal by opening the "workbooks" section under the Azure Sentinel created in the steps above. 

[Click here](https://docs.microsoft.com/azure/sentinel/tutorial-monitor-your-data) to learn more about Azure Sentinel and Workbooks.



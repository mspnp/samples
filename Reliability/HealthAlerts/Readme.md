## Create Resource Health Activity Log Alerts

This sample shows how to create Resource level Health Activity Log Alerts programmatically using an ARM template. Azure Resource Health 
notifies you about the current and historical health status of your Azure resources.

This template will work as written, and will sign you up to receive alerts for all newly activated resource health events across all resources 
in the resource group specified in the Action Group.

If you want to limit alerts to only come from a certain subset of resource types, you can define that in the condition section of the template 
like so:

```json
"condition": {
    "allOf": [
        ...,
        {
            "anyOf": [
                {
                    "field": "resourceType",
                    "equals": "MICROSOFT.COMPUTE/VIRTUALMACHINES",
                    "containsAny": null
                },
                {
                    "field": "resourceType",
                    "equals": "MICROSOFT.STORAGE/STORAGEACCOUNTS",
                    "containsAny": null
                },
                ...
            ]
        }
    ]
},
```

### Prerequisites

#### Create an action group

To follow the instructions on this sample, you'll need to create or reuse an Action Group configured to notify you; using the portal, manually create an Action Group named heatlh-alerts-ag.

See [How to create and manage action groups in the Azure portal](https://docs.microsoft.com/azure/azure-monitor/platform/action-groups) for instructions.


### Deploy the template

Log in to Azure

```powershell
Connect-AzAccount
```

Create a new resource group to deploy the sample

```powershell
New-AzResourceGroup -Name HealthAlerts-RG -Location "Central US"
```powershell

To start a new deployment using the template provided in this sample, use the PowerShell command below; you will also be prompted for the ActionGroupResourceId, which is composed this way (replace the _subscriptionId_ placeholder with your subscription ID):

 /subscriptions/<subscriptionId>/resourceGroups/HealthAlerts-RG/providers/microsoft.insights/actionGroups/heatlh-alerts-ag

If you desire, you can get the ActionGroupResourceId with this powershell command (asuming the name of the action group created is "health-alerts-ag")

```powershell
(Get-AzActionGroup -ResourceGroupName healthalerts-rg -Name health-alerts-ag).Id
```

Run the deployment command

```powershell
New-AzResourceGroupDeployment -Name ExampleDeployment -ResourceGroupName HealthAlerts-RG -TemplateFile resourcehealth.json
```

You'll get a confirmation in PowerShell if everything worked ok

```powershell
DeploymentName          : ExampleDeployment
ResourceGroupName       : HealthAlerts-RG
ProvisioningState       : Succeeded
Timestamp               : 11/28/2021 10:00:04 PM
Mode                    : Incremental
TemplateLink            :
Parameters              :
                          Name                     Type                       Value
                          =======================  =========================  ==========
                          activityLogAlertName     String                     activityLog-alert-1
                          actionGroupResourceId    String                     /subscriptions/a012a8b0-522a-4f59-81b6-aa
                          0361eb9387/resourceGroups/HealthAlerts-RG/providers/microsoft.insights/actionGroups/health-al
                          erts-ag

Outputs                 :
DeploymentDebugLogLevel :
```
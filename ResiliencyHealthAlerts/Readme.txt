Create Resource Health Activity Log Alerts

This sample shows how to create Resource level Health Activity Log Alerts programmatically using an ARM template. Azure Resource Health 
notifies you about the current and historical health status of your Azure resources.

This template will work as written, and will sign you up to receive alerts for all newly activated resource health events across all resources 
in the resource group specified in the Action Group.


If you want to limit alerts to only come from a certain subset of resource types, you can define that in the condition section of the template 
like so:


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


Instructions

Create an action group

You need to create or reuse an [Action Group](https://docs.microsoft.com/azure/azure-monitor/platform/action-groups) configured to notify you.


Deploy the template

To start a new deployment using the template provided in this sample, use this powershell command (provide you resource group name):

New-AzResourceGroupDeployment -Name ExampleDeployment -ResourceGroupName <resourceGroup> -TemplateFile resourcehealth.json

You will be prompted for the ActivityLogAlertName, enter any AlertName you want.

You will also be prompted for the ActionGroupResourceId, which is composed this way:

 /subscriptions/<subscriptionId>/resourceGroups/<resourceGroup>/providers/microsoft.insights/actionGroups/<actionGroup>

If you want, you can get hte ActionGroupResourceId with this powershell command:

(Get-AzActionGroup -ResourceGroupName mgrande-dev -Name TestActionGroup).Id

You'll get a confirmation in PowerShell if everything worked
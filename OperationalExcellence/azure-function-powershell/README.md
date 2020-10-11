--- 
page_type: sample
languages:
- azurecli
products:
- azure
---

# Azure Well Architected Framework Sample (Azure Monitor Alert and Azure PowerShell Function)

The Azure Monitor service collects and analizes data from your Azure and on-premises envitonment. This data can be used to detect and alert on service anonomilies, degradication, and failue. Azure PowerShell functions can be used to automate operational tasks sucs as responding to service issues. Together Azure Monitor and Azure Functions make a great team for detectign and responding to service issues.

This sample deploys a complete and ready to test enviroment for demonistrating Azure Monitor for detectign issues with Windows Services and an Azure Function for remediating serivce issues. When deployed, the following Azure resources are created:

- 1 to many Azure Virtual Machines (Windows)
- An Azure Log Analytics workspace
- An Azure Monitor query that querieis for all systems where a named service has been stopped
- An Azure Alert that triggers once a named serive has been stopped
- An Azure Monitor Action group that sends an email and runs an Azure function once triggered by an alert
- An Azure PowerShell Function that starts a stopped service on the virtual machin that raised the alert

## Deploy sample

**Azure portal**

To deploy this template using the Azure portal, click this button.  

<br />

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fsamples%2Fmaster%2FOperationalExcellence%2Fazure-function-powershell%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>  

**Azure CLI**

Create a resource group for the deployment.

```azurecli
az group create --name demo002 --location eastus
```

Run the following command to initiate the deployment.

```azurecli
az deployment group create \
    --resource-group demo002 \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/azure-function-powershell/OperationalExcellence/azure-function-powershell/azuredeploy.json --parameters adminPassword=Password2020! workspaceName=demo002niner functionAppName=demo002niner
```

## Code of conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

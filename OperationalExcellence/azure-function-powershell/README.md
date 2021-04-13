# Azure Well-Architected Framework Sample (Azure Monitor Alert and Azure PowerShell Function)

The Azure Monitor service collects and analyzes data from your Azure and on-premises environment. This data can be used to detect and alert on service anomalies, degradation, and failure. Azure PowerShell functions can be used to automate operational tasks such as responding to service issues. Together Azure Monitor and Azure Functions make a great team for detecting and responding to service issues.

This sample deploys a complete and ready-to-test environment to demonstrate Azure Monitor for detecting issues with Windows Services and an Azure Function for remediating service issues. When deployed, the following Azure resources are created:

- An Azure Virtual Machines (Windows)
- An Azure Log Analytics workspace
- An Azure Monitor query that queries for all systems where a named service has been stopped
- An Azure Alert that triggers once a named service has been stopped
- An Azure Monitor Action group that sends an email and runs an Azure function once triggered by an alert
- An Azure PowerShell Function that starts a stopped service on the virtual machine that raised the alert

## Deploy sample

### Azure portal

To deploy this template using the Azure portal, click this button.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fsamples%2Fmaster%2FOperationalExcellence%2Fazure-function-powershell%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>  

### Azure CLI

Create a resource group for the deployment.

```azurecli
az group create --name monitor-function-demo --location eastus
```

Run the following command to initiate the deployment.

```azurecli
az deployment group create \
    --resource-group monitor-function-demo \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/master/OperationalExcellence/azure-function-powershell/azuredeploy.json --parameters adminPassword=Password2020! emailAddress=nepeters@microsoft.com
```

## Microsoft Open Source Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

Resources:

- [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
- [Microsoft Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
- Contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with questions or concerns
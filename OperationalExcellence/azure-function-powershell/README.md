--- 
page_type: sample
languages:
- azurecli
products:
- azure
---

# Azure Well Architected Framework Sample (Azure Monitor Alert and Azure PowerShell Function)

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
az group create --name boot-strap-script-extension --location eastus
```

Run the following command to initiate the deployment.

```azurecli
az deployment group create \
    --resource-group uri-test-001 \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/azure-function-powershell/OperationalExcellence/azure-function-powershell/azuredeploy.json --parameters adminPassword=Password2020! workspaceName=uri-test-001 functionAppName=uri-test-001
```

## Code of conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

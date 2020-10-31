--- 
page_type: sample
languages:
- azurecli
products:
- azure
---

# Azure Well Architected Framework Sample (Secure AKS Cluster Pods with Azure Policy)

## Deploy sample

**Azure portal**

To deploy this template using the Azure portal, click this button.  

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fneilpeterson%2Fsamples%2Fazure-function-powershell%2FOperationalExcellence%2Fazure-aks-policy%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>  

**Azure CLI**

Create a resource group for the deployment.

```azurecli
az group create --name aks-azure-policy --location eastus
```

Run the following command to initiate the deployment.

```azurecli
az deployment group create \
    --resource-group aks-azure-policy \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/aks-azure-policy/OperationalExcellence/azure-aks-policy/azuredeploy.json
```

Verify that policies have propagated to the cluster. This process could take up to 20 minutes.

```azurecli
kubectl get constrainttemplate
```

If you would like to run the command on a loop to visually indicate when policies have propagated down to the cluster, run the following command.

```azurecli
while $true; do kubectl get constrainttemplate; sleep 5; done
```

## Code of conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
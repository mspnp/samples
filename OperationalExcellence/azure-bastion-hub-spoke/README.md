# Azure Bastion in a Hub and Spoke configuration

This sample deploys two peered Azure Virtual Networks, an Azure Bastion host, and optionally multiple Azure virtual machines. Use this sample to experience an Azure Bastion host in a hub and spoke configuration. To learn more about Bastion and peered VNets, see [VNet peering and Azure Bastion](https://docs.microsoft.com/en-us/azure/bastion/vnet-peering).

## Deploy sample

**Azure Portal**

To deploy this template using the Azure portal, click this button.  

<br />

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmspnp%2Fsamples%2Fmaster%2FOperationalExcellence%2Fazure-bastion-hub-spoke%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

**Azure CLI**

Create a resource group for the deployment.

```azurecli
az group create --name bast-hub-spoke --location eastus
```

Run the following command to initiate the deployment.c

```azurecli
az deployment group create \
    --resource-group bast-hub-spoke-303 \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/master/OperationalExcellence/azure-bastion-hub-spoke/azuredeploy.json \
    --parameters adminPassword=Password2020! windowsVMCount=1 linuxVMCount=1
```
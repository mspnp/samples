# Azure Bastion in a Hub and Spoke configuration

This sample deploys two peered Azure Virtual Networks, an Azure Bastion host, and optionally multiple Azure virtual machines. Use this sample to experience an Azure Bastion host in a hub and spoke configuration. To learn more about Bastion and peered VNets, see [VNet peering and Azure Bastion](https://docs.microsoft.com/en-us/azure/bastion/vnet-peering).

## Deploy sample

Create a resource group for the deployment.

```azurecli
az group create --name hub-spoke-updated-niner --location eastus
```

Run the following command to initiate the deployment.

```azurecli
az deployment group create \
    --resource-group hub-spoke-updated \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/hub-spoke-deployment/Solutions/azure-hub-spoke/azuredeploy.json \
    --parameters adminPassword=Password2020! linuxVMCount=1
```

To deploy with a VPN Gateway, run the following command.

```azurecli
az deployment group create \
    --resource-group hub-spoke-updated-niner \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/hub-spoke-deployment/Solutions/azure-hub-spoke/azuredeploy.json \
    --parameters adminPassword=Password2020! linuxVMCount=1 deployVpnGateway=true
```

## Code of conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
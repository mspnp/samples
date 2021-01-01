# Azure Bastion in a Hub and Spoke configuration


## Deploy sample

Create a resource group for the deployment.

```azurecli
az group create --name hub-spoke-updated --location eastus
```

** Basic deployment **

Run the following command to initiate the deployment. If you would like to also deploy this sample with virtual machines and / or an Azure VPN gateway, see the `az deployment group create` examples found later in this document.

```azurecli
az deployment group create \
    --resource-group hub-spoke-updated-fw-002 \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/hub-spoke-deployment/Solutions/azure-hub-spoke/azuredeploy.json
```

** Deploy with virtual machines **

Run the following command to initiate the deployment with a Linux VM deployed to the first spoke network.

```azurecli
az deployment group create \
    --resource-group hub-spoke-updated-fw-003 \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/hub-spoke-deployment/Solutions/azure-hub-spoke/azuredeploy.json \
    --parameters adminPassword=Password2020! linuxVMCount=1
```

** Deploy with VPN gateway **

Run the following command to initiate the deployment with a Linux VM deployed to the first spoke network and a virtual network gateway deployed into the hub virtual network.

```azurecli
az deployment group create \
    --resource-group hub-spoke-updated-ny-002 \
    --template-uri https://raw.githubusercontent.com/neilpeterson/samples/hub-spoke-deployment/Solutions/azure-hub-spoke/azuredeploy.json \
    --parameters adminPassword=Password2020! linuxVMCount=1 deployVpnGateway=true
```

## Solution deployment parameters

| Parameter | Type | Description | Default |
|---|---|---|--|
| windowsVMCount | int | Number of Windows virtual machines to create in spoke network. | 0 |
| linuxVMCount | int | Number of Linux virtual machines to create in spoke network. | 0 |
| adminUserName | string | If deploying virtual machines, the admin user name. | azureadmin |
| adminPassword | securestring | If deploying virtual machines, the admin password. | null |
| deployVpnGateway | bool | If true, a virtual network gateway is deployed into the hub network (30 min deployment). | false |
| hubNetwork | object | Network configuration for the hub virtual network. | [see template] |
| spokeOneNetwork | object | Network configuration for the first spoke virtual network. | [see template] |
| spokeTwoNetwork | object | Network configuration for the second spoke virtual network. | [see template] |
| vpnGateway | object | Network configuration for the vpn gateway. | [see template] |
| bastionHost | object | Configuration for the Bastion host. | [see template] |
| azureFirewall | object | Network configuration for the firewall instance. | [see template] |
| location | string | Deployment location. | resourceGroup().location | 

## Code of conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
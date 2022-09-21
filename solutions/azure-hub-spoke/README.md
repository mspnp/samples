---
page_type: sample
languages:
- azurepowershell
- azurecli
products:
  - azure
  - azure-firewall
  - azure-virtual-network
  - azure-bastion
  - azure-vpn-gateway
description: This sample deploys Azure virtual networks in a hub and spoke configuration. An Azure Firewall and Bastion host are also deployed. Optionally, a VPN gateway and sample workload (virtual machines) can be deployed. 
---

# Hub and spoke deployment

This sample deploys Azure virtual networks in a hub and spoke configuration. An Azure Firewall and Bastion host are also deployed. Optionally, a VPN gateway and sample workload (virtual machines) can be deployed. 

Where applicable, each resource is configured to send diagnostics to an Azure Log Analytics instance.

![Hub and spoke architectural diagram.](./images/hub-spoke.png)

For detailed information, see the Azure Hub and Spoke reference architecture in the Azure Architecture Center:

> [!div class="nextstepaction"]
> [Hub-spoke network topology in Azure](https://learn.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)

## Deploy sample

Create a resource group for the deployment.

```azurecli-interactive
az group create --name hub-spoke --location eastus
```

> The location for the deployed resources defaults to the location used for the target resource group. This deployment uses availability zones for all resources that support it, as hub networks are usually business critical. This means  if the resource group's location does not support availability zones, you must provide an additional parameter to your chosen command below of `location=value` with a value supports availability zones. See [Azure regions with availability zones](https://learn.microsoft.com/azure/availability-zones/az-overview#azure-regions-with-availability-zones).

**Basic deployment**

Run the following command to initiate the deployment. If you would like to also deploy this sample with virtual machines and / or an Azure VPN gateway, see the `az deployment group create` examples found later in this document.

```azurecli-interactive
az deployment group create \
    --resource-group hub-spoke \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/main/solutions/azure-hub-spoke/azuredeploy.json
```

**Deploy with virtual machines**

Run the following command to initiate the deployment with a Linux VM deployed to the first spoke network and a Windows VM deployed to the second spoke network.

| :warning: | This deploys these VMs with basic configuration, they are not Internet facing, but security should always be top of mind.  Please update the `adminUsername` and `adminPassword` to a value of your choosing. |
|-----------|:--------------------------|

```azurecli-interactive
az deployment group create \
    --resource-group hub-spoke \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/main/solutions/azure-hub-spoke/azuredeploy.json \
    --parameters deployVirtualMachines=true adminUsername=azureadmin adminPassword=Password2023!
```

**Deploy with VPN gateway**

Run the following command to initiate the deployment with a virtual network gateway deployed into the hub virtual network. Note, VPN gateways take a significant time to deploy.

```azurecli-interactive
az deployment group create \
    --resource-group hub-spoke \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/main/solutions/azure-hub-spoke/azuredeploy.json \
    --parameters deployVpnGateway=true
```

**Deploy with virtual machines and a VPN gateway**

Run the following command to initiate the deployment with a Linux VM deployed to the first spoke network and a Windows VM deployed to the second spoke network.

| :warning: | This deploys these VMs with basic configuration, they are not Internet facing, but security should always be top of mind.  Please update the `adminUsername` and `adminPassword` to a value of your choosing. |
|-----------|:--------------------------|

```azurecli-interactive
az deployment group create \
    --resource-group hub-spoke \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/main/solutions/azure-hub-spoke/azuredeploy.json \
    --parameters deployVirtualMachines=true adminUsername=azureadmin adminPassword=Password2023! deployVpnGateway=true
```

## Solution deployment parameters

| Parameter | Type | Description | Default |
|---|---|---|--|
| `location` | string | Deployment location. Location must support availability zones. | `resourceGroup().location` | 
| `deployVirtualMachines` | bool | If true, deploys one basic Linux virtual machine to spoke one and one basic Windows virtual machine to spoke two. | `false` |
| `adminUserName` | string | If deploying virtual machines, the admin user name for both VMs. | `azureadmin` |
| `adminPassword` | securestring | If deploying virtual machines, the admin password for both VMs. | `null` |
| `deployVpnGateway` | bool | If true, a virtual network gateway is deployed into the hub network (+30 min deployment). | `false` |

## Diagnostic configurations

The following resources are configured to send diagnostic logs to the included Log Analytics workspace.

- All virtual networks
- All network security groups
- Azure VPN Gateway
- Azure Firewall
- Azure Bastion

Note, this deployment includes optional basic virtual machines. These are not configured with a Log Analytics workspace, however, can be with the Log Analytics virtual machine extension for [Windows](https://learn.microsoft.com/azure/virtual-machines/extensions/oms-windows) and [Linux](https://learn.microsoft.com/azure/virtual-machines/extensions/oms-linux).

## Bicep implementation

The links above use JSON Azure Resource Manager (ARM) templates to support network referencing. The ARM templates were generated from the following [source bicep file](https://github.com/mspnp/samples/blob/main/solutions/azure-hub-spoke/bicep/main.bicep), which has additional comments and considerations.

## Microsoft Open Source Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

Resources:

- [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
- [Microsoft Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
- Contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with questions or concerns

---
page_type: sample
languages:
- azurecli
- bicep
products:
  - azure
  - azure-firewall
  - azure-virtual-network
  - azure-bastion
  - azure-vpn-gateway
  - virtual-network-manager
name: Hub-and-Spoke Deployment with Connected Groups
urlFragment: hub-and-spoke-virtual-network-manager-connected-groups
description: This sample deploys Azure virtual networks in a hub and spoke configuration, using Azure Virtual Network Manager to manage Virtual Network connectivity and implement sample Security Admin Rules. An Azure Firewall and Bastion host are also deployed. Optionally, a VPN gateway and sample workload (virtual machines) can be deployed.
urlFragment: hub-and-spoke-deployment-with-connected-groups
azureDeploy: https://raw.githubusercontent.com/mspnp/samples/main/solutions/azure-hub-spoke-connected-group/azuredeploy.json
---

# Hub and Spoke Deployment with Connected Groups

This sample deploys Azure virtual networks in a hub and spoke configuration, using Azure Virtual Network Manager to manage Virtual Network connectivity and implement sample Security Admin Rules. An Azure Firewall and Bastion host are also deployed. Optionally, a VPN gateway and sample workload (virtual machines) can be deployed.

Where applicable, each resource is configured to send diagnostics to an Azure Log Analytics instance.

![Hub and spoke connected group architectural diagram.](https://learn.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/images/hub-spoke.png)

For detailed information, see the Azure Hub and Spoke reference architecture in the Azure Architecture Center:

> [!div class="nextstepaction"] > [Hub-spoke network topology in Azure](https://learn.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)

## Deploying Azure Virtual Network Manager with Infrastructure-as-Code

### Registering Resource Providers

If your Azure Virtual Network Manager's scopes includes Management Groups, you'll need to register the 'Microsoft.Network' Resource Provider at each Management Group scope with the REST API. See: [Register Resource Provider at Management Group Scope](https://learn.microsoft.com/rest/api/resources/providers/register-at-management-group-scope).

### Deploying Configurations

When deploying or managing Azure Virtual Network Manager using infrastructure-as-code, special consideration should be given to the fact that Azure Virtual Network Manager configuration involves a two step process:

1. A configuration and configuration scope or target are defined, then
1. The configuration is deployed to the target resources (typically, Virtual Networks).

To complete these steps using the Portal, you create a configuration then choose to deploy it in a separate action. For infrastructure code, after defining a configuration in code, the Azure Virtual Network Manager API must be called to perform a 'commit' action (mirroring the 'deploy' step in the Portal).

Declarative infrastructure code on its own cannot call the API, requiring the use of a Deployment Script resource. The Deployment Script resource invokes a script in an Azure Container Instance to execute the `Deploy-AzNetworkManagerCommit` Azure PowerShell command.

Because the PowerShell script runs within the Deployment Script resource, troubleshooting a failed deployment may require reviewing the script logs found on the Deployment Script resource if the Deployment Script resource deployment reports a failure. It is also possible to view the deployment in the Portal, but note that the Portal interface may take several minutes to update after a code deployment is run.

## Deploy sample

Clone repository

```bash
git clone https://github.com/mspnp/samples.git
cd samples/solutions/azure-hub-spoke-connected-group/bicep
```

Create a resource group for the deployment.

```bash
az group create --name rg-hub-spoke-eastus --location eastus
```

> The location for the deployed resources defaults to the location used for the target resource group. This deployment uses availability zones for all resources that support it, as hub networks are usually business critical. This means if the resource group's location does not support availability zones, you must provide an additional parameter to your chosen command below of `location=value` with a value supports availability zones. See [Azure regions with availability zones](https://learn.microsoft.com/azure/availability-zones/az-overview#azure-regions-with-availability-zones).

**Basic deployment**

Run the following command to initiate the deployment. If you would like to also deploy this sample with virtual machines and / or an Azure VPN gateway, see the `az deployment group create` examples found later in this document.

```bash
az deployment group create \
    --resource-group rg-hub-spoke-eastus \
    --template-file main.bicep
```

**Deploy with virtual machines**

Run the following command to initiate the deployment with a Linux VM deployed to the first spoke network and a Windows VM deployed to the second spoke network.

| :warning: | This deploys these VMs with basic configuration, they are not Internet facing, but security should always be top of mind. Please update the `adminUsername` and `adminPassword` to a value of your choosing. |
| --------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |

```bash
az deployment group create \
    --resource-group rg-hub-spoke-eastus \
    --template-file main.bicep \
    --parameters deployVirtualMachines=true adminUsername=azureadmin adminPassword=Password2023!
```

**Deploy with VPN gateway**

Run the following command to initiate the deployment with a virtual network gateway deployed into the hub virtual network. Note, VPN gateways take a significant time to deploy.

```bash
az deployment group create \
    --resource-group rg-hub-spoke-eastus \
    --template-file main.bicep \
    --parameters deployVpnGateway=true
```

**Deploy with virtual machines and a VPN gateway**

Run the following command to initiate the deployment with a Linux VM deployed to the first spoke network and a Windows VM deployed to the second spoke network.

| :warning: | This deploys these VMs with basic configuration, they are not Internet facing, but security should always be top of mind. Please update the `adminUsername` and `adminPassword` to a value of your choosing. |
| --------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |

```bash
az deployment group create \
    --resource-group rg-hub-spoke-eastus \
    --template-file main.bicep \
    --parameters deployVirtualMachines=true adminUsername=azureadmin adminPassword=Password2023! deployVpnGateway=true
```

## Solution deployment parameters

| Parameter                             | Type         | Description                                                                                                       | Default                    |
| ------------------------------------- | ------------ | ----------------------------------------------------------------------------------------------------------------- | -------------------------- |
| `location`                            | string       | Deployment location. Location must support availability zones.                                                    | `resourceGroup().location` |
| `deployVirtualMachines`               | bool         | If true, deploys one basic Linux virtual machine to spoke one and one basic Windows virtual machine to spoke two. | `false`                    |
| `adminUserName`                       | string       | If deploying virtual machines, the admin user name for both VMs.                                                  | `azureadmin`               |
| `adminPassword`                       | securestring | If deploying virtual machines, the admin password for both VMs.                                                   | `null`                     |
| `deployVpnGateway`                    | bool         | If true, a virtual network gateway is deployed into the hub network (+30 min deployment).                         | `false`                    |
| `deployDefaultDenySecurityAdminRules` | bool         | If false, the Azure Virtual Network Manager security rule collection is left empty                                | `true`                     |

## Diagnostic configurations

The following resources are configured to send diagnostic logs to the included Log Analytics workspace.

- All virtual networks
- All network security groups
- Azure VPN Gateway
- Azure Firewall
- Azure Bastion

Note, this deployment includes optional basic virtual machines. These are not configured with a Log Analytics workspace, however, can be with the Log Analytics virtual machine extension for [Windows](https://learn.microsoft.com/azure/virtual-machines/extensions/oms-windows) and [Linux](https://learn.microsoft.com/azure/virtual-machines/extensions/oms-linux).

## Step 5: Clean Up

```bash
az group delete --name rg-hub-spoke-eastus --yes
```

## Microsoft Open Source Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

Resources:

- [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
- [Microsoft Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
- Contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with questions or concerns

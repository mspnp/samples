---
page_type: sample
languages:
- azurepowershell
- azurecli
name: Secure hybrid network
products:
  - azure-vpn-gateway
  - azure-virtual-network
  - azure-firewall
description: This sample deploys a hub and spoke network, a mock on-premises network, and connects both with a site-to-site VPN connection. 
---

# Secure hybrid network

This sample deploys a hub and spoke network, a mock on-premises network, and connects both with a site-to-site VPN connection. 

Where applicable, each resource is configured to send diagnostics to an Azure Log Analytics instance.

![Hub and spoke architectural diagram](images/dmz-private.png)

For detailed information, see the Implement a secure hybrid network:

> [!div class="nextstepaction"]
> [Implement a secure hybrid network](https://learn.microsoft.com/azure/architecture/reference-architectures/dmz/secure-vnet-dmz)

## Deploy sample

Clone this repo

```azurecli-interactive
git clone https://github.com/mspnp/samples.git
cd samples/solutions/secure-hybrid-network
```

Run the following commands to initiate the deployment. When prompted, enter values for an admin username and password. These values are used to log into the included virtual machines.

```azurecli-interactive
# Resources will be created on deployment region
az deployment sub create -n secure-hybrid-network --location eastus2 --template-file azuredeploy.bicep  -p mocOnPremResourceGroup=rg-site-to-site-mock-prem-eastus2 azureNetworkResourceGroup=rg-site-to-site-azure-network-eastus2
```

## Solution deployment parameters

**azuredeploy.bicep**

| Parameter | Type | Description | Default and properties |
|---|---|---|--|
| mocOnPremResourceGroup | string | Name of the moc on-prem resource group. | null |
| azureNetworkResourceGroup | string | Name of the Azure network resource group. | null |
| adminUserName | string | The admin user name for the Azure SQL instance. | null |
| adminPassword | securestring | The admin password for the Azure SQL instance. | null |

**nestedtemplates/azure-network-azuredeploy.bicep**

| Parameter | Type | Description | Default and properties |
|---|---|---|--|
| adminUserName | string | The admin user name for the Azure SQL instance. | null |
| adminPassword | securestring | The admin password for the Azure SQL instance. | null |
| windowsVMCount | int | The number of load-balanced virtual machines running IIS. | 2 |
| vmSize | string | Size of the load-balanced virtual machines. | Standard_DS1_v2 |
| configureSitetosite | bool | Condition for configuring a site-to-site VPN connection. | true |
| hubNetwork | object | Object representing the configuration of the hub network. | name, addressPrefix |
| spokeNetwork | object | Object representing the configuration of the spoke network. | name, addressPrefix, subnetName, subnetPrefix, subnetNsgName |
| vpnGateway | object | Object representing the configuration of the VPN gateway. | name, subnetName, subnetPrefix, publicIPAddressName |
| bastionHost | object | Object representing the configuration of the Bastion host. | name, subnetName, subnetPrefix, publicIPAddressName, nsgName |
| azureFirewall | object | Object representing the configuration of the Azure Firewall. | name, subnetName, subnetPrefix, publicIPAddressName |
| spokeRoutes | object | Object representing user-defined routes for the spoke subnet. | tableName, routeNameFirewall |
| gatewayRoutes | object | Object representing user-defined routes for the gateway network. | tableName, routeNameFirewall |
| internalLoadBalancer | object | Object representing the configuration of the application load balancer. | name, backendName, fontendName, probeName |
| location | string | Location to be used for all resources. | rg location |

**nestedtemplates/azure-network-local-gateway.bicep**

| Parameter | Type | Description | Default and properties |
|---|---|---|--|
| connectionName | string | Name of the Azure connection resource. | hub-to-mock-prem |
| gatewayIpAddress | string | Public IP address of the mock on-prem virtual network gateway. | null |
| azureCloudVnetPrefix | string | Subnet prefix of the management subnet found in the hub network. | null |
| azureNetworkGatewayName | string | Name of the Azure virtual network gateway. | null |
| localNetworkGatewayName | string |  Name of the Azure local network gateway. | local-gateway-azure-network |

**nestedtemplates/mock-onprem-azuredeploy.bicep**

| Parameter | Type | Description | Default |
|---|---|---|--|
| adminUserName | string | The admin user name for the Azure SQL instance. | null |
| adminPassword | securestring | The admin password for the Azure SQL instance. | null |
| mocOnpremNetwork | object | Object representing the configuration of the mock on-prem network. | name, addressPrefix, mgmt, subnetPrefix |
| mocOnpremGateway | object | Object representing the configuration of the VPN gateway. | name, subnetName, subnetPrefix, publicIPAddressName |
| bastionHost | object | Object representing the configuration of the Bastion host. | name, subnetName, subnetPrefix, publicIPAddressName, nsgName |
| vmSize | string | Size of the load-balanced virtual machines. | Standard_DS1_v2 |
| configureSitetosite | bool | Condition for configuring a site-to-site VPN connection. | true |
| location | string | Location to be used for all resources. | rg location |

**nestedtemplates/mock-onprem-local-gateway.bicep**

| Parameter | Type | Description | Default |
|---|---|---|--|
| connectionName | string | Name of the mock on-prem connection resource. | hub-to-mock-prem |
| azureCloudVnetPrefix | string | Subnet prefix of the management subnet found in the hub network. | hub-to-mock-prem |
| spokeNetworkAddressPrefix | string | Subnet prefix of the resource subnet found in the spoke network. | hub-to-mock-prem |
| gatewayIpAddress | string | Public IP address of the Azure virtual network gateway. | null |
| mocOnpremGatewayName | string | Name of the mock on-prem local network gateway.  | null |
| localNetworkGateway | string | Name of the mock on-prem local network gateway. | local-gateway-moc-prem |
| location | string | Location to be used for all resources. | rg location |

## Clean Up

```azurecli-interactive
az group delete --name rg-site-to-site-mock-prem-eastus2 --yes
az group delete --name rg-site-to-site-azure-network-eastus2 --yes
```

## Microsoft Open Source Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

Resources:

- [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
- [Microsoft Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
- Contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with questions or concerns
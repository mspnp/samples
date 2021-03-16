---
page_type: sample
languages:
- azurepowershell
- azurecli
products:
  - azure-vpn-gateway
  - azure-virtual-network
  - azure-firewall
  - azure-vpn-gateway
description: This sample deploys a hub and spoke network, a mock on-premises network, and connects both with a site-to-site VPN connection. 
---

# Secure hybrid network

[![Build Status](https://nepeters-devops.visualstudio.com/arm-template-validation-pipelines/_apis/build/status/secure-hybrid-network?branchName=master)](https://nepeters-devops.visualstudio.com/arm-template-validation-pipelines/_build/latest?definitionId=135&branchName=master)

This sample deploys a hub and spoke network, a mock on-premises network, and connects both with a site-to-site VPN connection. 

Where applicable, each resource is configured to send diagnostics to an Azure Log Analytics instance.

![Hub and spoke architectural diagram.](images/dmz-private.png)

For detailed information, see the Implement a secure hybrid network:

> [!div class="nextstepaction"]
> [Implement a secure hybrid network](https://docs.microsoft.com/azure/architecture/reference-architectures/dmz/secure-vnet-dmz)

## Deploy sample

Run the following command to initiate the deployment. When prompted, enter values for an admin user name and password. These values are used to log into the included virtual machines.

```azurecli-interactive
az deployment sub create \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/master/solutions/secure-hybrid-network/azuredeploy.json --location eastus
```

## Solution deployment parameters

**azuredeploy.json**

| Parameter | Type | Description | Default |
|---|---|---|--|
| mocOnPremResourceGroup | string | Name of the moc on-prem resource group. | site-to-site-mock-prem |
| azureNetworkResourceGroup | string | Name of the Azure network resource group. | site-to-site-azure-network |
| adminUserName | string | The admin user name for the Azure SQL instance. | null |
| adminPassword | securestring | The admin password for the Azure SQL instance. | null |

**nestedtemplates/azure-network-azuredeploy.json**

| Parameter | Type | Description | Default |
|---|---|---|--|
| adminUserName | string | The admin user name for the Azure SQL instance. | null |
| adminPassword | securestring | The admin password for the Azure SQL instance. | null |
| windowsVMCount | int |  | 2 |
| vmSize | string |  | Standard_A1_v2 |
| deployVpnGateway | bool |  | true |
| hubNetwork | object |  | name, addressPrefix |
| spokeNetwork | object |  | name, addressPrefix, subnetName, subnetPrefix, subnetNsgName |
| vpnGateway | object |  | name, subnetName, subnetPrefix, publicIPAddressName |
| bastionHost | object |  | name, subnetName, subnetPrefix, publicIPAddressName, nsgName |
| azureFirewall | object |  | name, subnetName, subnetPrefix, publicIPAddressName |
| spokeRoutes | object |  | tableName, routeNameFirewall |
| gatewayRoutes | object |  | tableName, routeNameFirewall |
| internalLoadBalancer | object |  | name, backendName, fontendName, probeName |
| location | string |  | null |

**nestedtemplates/azure-network-local-gateway.json**

| Parameter | Type | Description | Default |
|---|---|---|--|
| connectionName | string |  | hub-to-mock-prem |
| gatewayIpAddress | string |  | null |
| azureCloudVnetPrefix | string |  | null |
| azureNetworkGatewayName | string |  | null |
| localNetworkGatewayName | string |  | local-gateway-azure-network |

**nestedtemplates/mock-onprem-azuredeploy.json**

| Parameter | Type | Description | Default |
|---|---|---|--|
| adminUserName | string | The admin user name for the Azure SQL instance. | null |
| adminPassword | securestring | The admin password for the Azure SQL instance. | null |
| mocOnpremNetwork | object | | name, addressPrefix, mgmt, subnetPrefix |
| mocOnpremGateway | object | | name, subnetName, subnetPrefix, publicIPAddressName |
| bastionHost | object | | name, subnetName, subnetPrefix, publicIPAddressName, nsgName |
| vmSize | string | | Standard_A1_v2 |
| deployVpnGateway | bool | | true |
| location | string |  | null |

**nestedtemplates/mock-onprem-local-gateway.json**

| Parameter | Type | Description | Default |
|---|---|---|--|
| connectionName | string |  | hub-to-mock-prem |
| azureCloudVnetPrefix | string |  | hub-to-mock-prem |
| spokeNetworkAddressPrefix | string |  | hub-to-mock-prem |
| gatewayIpAddress | string |  | null |
| mocOnpremGatewayName | string |  | null |
| localNetworkGateway | string |  | local-gateway-moc-prem |
| location | string |  | null |

## Code of conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information, see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

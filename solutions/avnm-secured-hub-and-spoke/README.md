---
page_type: sample
languages:
- azurepowershell
- azurecli
products:
  - azure
  - azure-virtual-network
  - virtual-network-manager
description: This sample deploys Azure virtual networks in a hub and spoke connectivity configuration, using Azure Virtual Network Manager to manage Virtual Network connectivity and implement sample Security Admin Rules. A VPN gateway and test VMs are included.
urlFragment: virtual-network-manager-secured-hub-and-spoke
---

# Secured hub and spoke deployment with Connected Groups

This sample deploys Azure virtual networks in a hub and spoke configuration, using Azure Virtual Network Manager to manage Virtual Network connectivity and implement sample Security Admin Rules. A VPN Gateway and test VMs are deployed to complete the hub and spoke features.


## Deploy sample

### Step 1: Create a Resource Group for the sample resources

Create a resource group for the deployment.

```azurecli-interactive
az group create --name hub-spoke --location eastus
```

### Step 2: Deploy infrastructure and Virtual Network Manager resources

```azurecli-interactive
az deployment group create \
    --resource-group hub-spoke \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/main/solutions/avnm-secured-hub-and-spoke/armTemplates/avnmResources.json
```

### Step 3: Deploy Virtual Network Manager Dynamic Network Group Policy resources

```azurecli-interactive
az deployment subscription create \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/main/solutions/avnm-secured-hub-and-spoke/armTemplates/avmnDynamicMembershipPolicy.json
```

## Solution deployment parameters

| Parameter | Type | Description | Default |
|---|---|---|--|
| `location` | string | Deployment location | `resourceGroup().location` | 
| `adminUserName` | string | The admin user name for deployed VMs. | `admin-avnm` |
| `adminPassword` | securestring | The admin password for deployed VMs. | `null` |


## Bicep implementation

The links above use JSON Azure Resource Manager (ARM) templates to support network referencing. The ARM templates were generated from the following [source bicep file](https://github.com/mspnp/samples/blob/main/solutions/avnm-secured-hub-and-spoke/bicep/main.bicep), which has additional comments and considerations.

## Microsoft Open Source Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

Resources:

- [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
- [Microsoft Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
- Contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with questions or concerns

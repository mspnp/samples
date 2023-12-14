---
page_type: sample
languages:
- azurepowershell
- azurecli
products:
  - azure
  - azure-virtual-network
  - virtual-network-manager
description: This sample deploys Virtual Networks and implements inter-network connectivity using Azure Virtual Network Manager and a mesh connectivity topology. 
urlFragment: avnm-mesh-connected-group
azureDeploy: https://raw.githubusercontent.com/mspnp/samples/main/solutions/avnm-mesh-connected-group/azuredeploy.json
---

# Hub and spoke deployment with Mesh Connected Groups

This sample deploys Azure virtual networks, using Azure Virtual Network Manager to connect the virtual networks with a mesh topology connected group. The sample includes both hub and spoke virtual networks, which are all added to the same mesh. Note that gateway routes are not propagated with mesh connectivity, so deploying a Virtual Network Gateway in the hub with this pattern would require static routes. See [Quickstart: Create a mesh network topology with Azure Virtual Network Manager by using Bicep](https://learn.microsoft.com/azure/virtual-network-manager/create-virtual-network-manager-bicep) for more context.

## Deploy sample

**Default Deployment with Static Network Group Membership**

```azurecli-interactive
az deployment subscription create \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/main/solutions/avnm-mesh-connected-group/armTemplates/azuredeploy.json \
    --parameters location=eastus
```

**Default Deployment with Dynamic Network Group Membership**

Include the deployment parameter `networkGroupMembershipType` with a value of `dynamic` to use Azure Policy to dynamically manage the membership of the network group. 

>![NOTE] This deployment requires permissions to create and assign Azure Policy at the target subscription level. 

```azurecli-interactive
az deployment subscription create \
    --template-uri https://raw.githubusercontent.com/mspnp/samples/main/solutions/avnm-mesh-connected-group/armTemplates/azuredeploy.json \
    --parameters networkGroupMembershipType=dynamic location=eastus
```

## Solution deployment parameters

| Parameter | Type | Description | Default |
|---|---|---|--|
| `location` | string | Deployment location. Location must support availability zones. | `resourceGroup().location` | 
| `deployVirtualMachines` | bool | If true, deploys one basic Linux virtual machine to spoke one and one basic Windows virtual machine to spoke two. | `false` |
| `networkGroupMembershipType` | string | Specify either 'static' or 'dynamic' network group membership. Default: 'static' | `false` |

## Bicep implementation

The links above use JSON Azure Resource Manager (ARM) templates to support network referencing. The ARM templates were generated from the following [source bicep file](https://github.com/mspnp/samples/blob/main/solutions/avnm-mesh-connected-group/bicep), which has additional comments and considerations.

## Microsoft Open Source Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

Resources:

- [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
- [Microsoft Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
- Contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with questions or concerns

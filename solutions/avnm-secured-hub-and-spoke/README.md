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

### Step 1: Environment

```bash
LOCATION=eastus
RESOURCEGROUP_NAME=rg-hub-spoke-${LOCATION}

# Ensure the feature is enable
az feature register --namespace "Microsoft.Compute" --name "EncryptionAtHost"
```

### Step 2: Create a Resource Group for the sample resources

Create a resource group for the deployment.

```bash
az group create --name ${RESOURCEGROUP_NAME} --location ${LOCATION}
```

### Step 3: Download bicep files

```bash
mkdir modules
cd modules
curl -o avnm.bicep https://raw.githubusercontent.com/mspnp/samples/main/solutions/avnm-secured-hub-and-spoke/bicep/modules/avnm.bicep
curl -o avnmDeploymentScript.bicep https://raw.githubusercontent.com/mspnp/samples/main/solutions/avnm-secured-hub-and-spoke/bicep/modules/avnmDeploymentScript.bicep
curl -o dynMemberPolicy.bicep https://raw.githubusercontent.com/mspnp/samples/main/solutions/avnm-secured-hub-and-spoke/bicep/modules/dynMemberPolicy.bicep
curl -o hub.bicep https://raw.githubusercontent.com/mspnp/samples/main/solutions/avnm-secured-hub-and-spoke/bicep/modules/hub.bicep
curl -o spoke.bicep https://raw.githubusercontent.com/mspnp/samples/main/solutions/avnm-secured-hub-and-spoke/bicep/modules/spoke.bicep
cd ..

curl -o main.bicep https://raw.githubusercontent.com/mspnp/samples/main/solutions/avnm-secured-hub-and-spoke/bicep/main.bicep
```

### Step 4: Deploy infrastructure and Virtual Network Manager resources

```bash
az deployment sub create --template-file main.bicep -n avnm-secured-hub-and-spoke -l ${LOCATION} --parameters resourceGroupName=${RESOURCEGROUP_NAME} adminPassword=changeMe123!
```

## Solution deployment parameters

| Parameter       | Type         | Description                           | Default                    |
| --------------- | ------------ | ------------------------------------- | -------------------------- |
| `location`      | string       | Deployment location                   | `resourceGroup().location` |
| `adminUserName` | string       | The admin user name for deployed VMs. | `admin-avnm`               |
| `adminPassword` | securestring | The admin password for deployed VMs.  | `null`                     |

## Step 5: Clean Up

```bash
az group delete --name ${RESOURCEGROUP_NAME} --yes
```

## Microsoft Open Source Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

Resources:

- [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
- [Microsoft Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
- Contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with questions or concerns

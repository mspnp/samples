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

### Step 1: Clone repository and navigate to the correct folder

```bash
git clone https://github.com/mspnp/samples.git
cd ./samples/solutions/avnm-secured-hub-and-spoke/bicep
```

### Step 2: Deploy infrastructure and Virtual Network Manager resources

```bash
# Generate ssh key and get public data.
ssh-keygen -t rsa -b 2048

az deployment sub create --location eastus --template-file main.bicep -n avnm-secured-hub-and-spoke --parameters sshKey="$(cat ~/.ssh/id_rsa.pub)"
```

## Solution deployment parameters

| Parameter       | Type         | Description                           | Default                    |
| --------------- | ------------ | ------------------------------------- | -------------------------- |
| `adminUserName` | string       | The admin user name for deployed VMs. | `admin-avnm`               |
| `sshkey`        | string       | The user's public SSH key to be added to the Linux machines as part of the `ssh_authorized_keys` list    |                 |

## Step 4: Clean Up

```bash
az group delete --name rg-hub-spoke-eastus --yes
```

## Microsoft Open Source Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

Resources:

- [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
- [Microsoft Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
- Contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with questions or concerns

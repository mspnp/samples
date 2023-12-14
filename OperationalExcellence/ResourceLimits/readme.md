# Query limits and quotas for commonly used resources

This set of Azure CLI and Azure PowerShell commands shows how to query limits and quotas for commonly used networking, SQL Database, storage, and virtual machine resources. To learn more about how limits and quota impact service selection see [PE:03 Selecting services](https://learn.microsoft.com/azure/well-architected/performance-efficiency/select-services) in the Azure Well-Architected Framework.

## Azure CLI instructions

### Prerequisites

- This repository is cloned to the workstation you plan on running this script from.
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) version 2.0.32 or later.

### Steps

1. Open Azure Cloud Shell or a shell on your workstation.

1. Run `az login` to log into Azure.

1. Modify **QueryLimits.sh** to set your subscription and region.

1. Run **QueryLimits.sh** in the shell.

## Azure PowerShell instructions

### Prerequisites

- This repository is cloned to the workstation you plan on running this script from.
- [Azure PowerShell](https://learn.microsoft.com/powershell/azure/install-azure-powershell) 10.4 or later.

### Steps

1. Open Azure Cloud Shell or a shell on your workstation.

1. Connect to Azure using your account.

1. Modify **QueryLimits.ps1** to set your subscription and region.

1. Run **QueryLimits.ps1** in the shell.

## :broom: Clean up

This sample doesn't deploy any new resources, so there is no cleanup necessary.

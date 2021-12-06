---
title: AAF resiliency pillar - Data management - storage resiliency code samples
description: Sample scripts for creating storage snapshots for resiliency
ms.date: 12/03/2021
author: hallihan
ms.topic: guide
ms.service: architecture-framework
ms.subservice: resiliency
ms.custom: data-managemt
---

## Storage resiliency code samples

In this set of files we provide sample Powershell scripts for creating a snapshot of a Blob and a File share, as well as a sample script for copying blobs from one storage account to another; we also include the ARM template to deploy the storage account and related resources.

### Prerequisites

These samples require you to have installed [Azure PowerShell](https://docs.microsoft.com/powershell/azure/install-az-ps), [AzCopy](https://docs.microsoft.com/azure/storage/common/storage-use-azcopy#download-azcopy) and [Git](https://docs.microsoft.com/devops/develop/git/install-and-set-up-git) or you may utilize the [Azure Cloud Shell](https://shell.azure.com) in PowerShell mode.

### Clone the Samples Repo and navigate to Storage samples

```powershell
git clone https://github.com/mspnp/samples.git
cd samples\Reliability\StorageSnapshotsSample
```

### Deploy the resources

```
$ResourceGroupName="rg-storage-samples"
New-AzResourceGroup -ResourceGroupName $ResourceGroupName -Location EASTUS
New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile StorageAccountTemplate.json
```

### Sample Scripts

Sample 1 included in PowerShell script Blob-Snapshot.ps1, shows how to create a snapshot of a blob. A file is first uploaded, and then a snapshot of the blob is created.

```powershell
.\Blob-Snapshot.ps1 -ResourceGroupName $ResourceGroupName
```

Sample 2 included in PowerShell script AzCopy-Blob-Container.ps1, shows how to copy all the blobs included in a blob container from one storage account to another. In this example a read-only SAS key is generated for the source, and a write-only SAS key is generated for the destination. Normally the retrieval of SAS keys would be a separate operation and is included in the script here for convenience.

```powershell
./AzCopy-Blob-Container.ps1 -ResourceGroupName $ResourceGroupName
```

Sample 3 included in PowerShell script FileShare-Snapshot.ps1, shows how request a snapshot of a File Share. A file is first uploaded, and then a snapshot of the share is created.

```powershell
.\FileShare-Snapshot.ps1 -ResourceGroupName $ResourceGroupName
```

### Clean up resources

After you are done with the sample, clean up the resources with the following command.

```powershell
Remove-AzResourceGroup -Name $ResourceGroupName
```

### For more information

These samples are related to this section:

https://docs.microsoft.com/azure/architecture/framework/resiliency/data-management#storage-resiliency

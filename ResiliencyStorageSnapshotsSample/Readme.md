---
title: AAF resiliency pillar - Data management - storage resiliency code samples 
description: Sample scripts for creating storage snapshots for resiliency
ms.date: 03/19/2020
author: Magrande
ms.topic: guide
ms.service: architecture-framework
ms.subservice: resiliency
ms.custom: data-managemt
---

## Storage resiliency code samples 


In this set of files we provide sample Powershell scripts for creating a snapshot of a blob and a File share, as well as a sample script for copying blobs from one storage account to another; we also include the ARM tmeplate to deploy the storage account and related resources.

Before running any of these samples, deploy the ARM template included in file StorageAccountTemplate.json

Use this command:

New-AzResourceGroupDeployment -ResourceGroupName <resource-group-name> -TemplateFile StorageAccountTemplate.json

Sample 1 included in PS script Blob-Snapshots.ps1, shows how to create a snapshot of a blob

Sample 3 included in PS script FileShare-Snapshot.ps1, shows how request a snaphot of a fileShare 

Sample 2 included in PS script azcopy-blob-containers.ps1, shows how to copy all the blobs included in a blob container from one storage account to another.



These samples are related to this section:

https://docs.microsoft.com/en-us/azure/architecture/framework/resiliency/data-management#storage-resiliency

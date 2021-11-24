# Manage your alerts programmatically

## Azure Cli

### Prerequisites

Add the Resource Graph extension to the Azure CLI environment

```bash
az extension add --name resource-graph
```

Check the extension list (note that you may have other extensions installed)

```bash
az extension list
```

Run help for graph query options

```bash
az graph query -h
```

### Sample Queries

This set of Azure CLI commands show how to query programmatically for alerts generated against your subscription.

```bash
./graph-alerts.sh <subscriptionId>
```

## PowerShell

### Prerequisites

Install the Resource Graph module from PowerShell Gallery

```powershell
Install-Module -Name Az.ResourceGraph
```

Get a list of commands for the imported Az.ResourceGraph module

```powershell
Get-Command -Module 'Az.ResourceGraph' -CommandType 'Cmdlet'
```

### Sample Queries

This set of Powershell commands show how to query programmatically for alerts generated against your subscription.

```powershell
.\graph-alerts.ps1 <subscriptionId>
```

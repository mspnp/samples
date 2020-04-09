## Manage your alerts programmatically

This set of Powershell commands show how to query programmatically for alerts generated against your subscription.


### Prerequisites

# Install the Resource Graph module from PowerShell Gallery
Install-Module -Name Az.ResourceGraph

# Get a list of commands for the imported Az.ResourceGraph module
Get-Command -Module 'Az.ResourceGraph' -CommandType 'Cmdlet'


### Sample Queries

# This query searchs for alerts in a specific subscription

Search-AzGraph -Query "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ 'a012a8b0-522a-4f59-81b6-aa0361eb9387' "

# Same query but listing specific fields

Search-AzGraph -Query "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ 'a012a8b0-522a-4f59-81b6-aa0361eb9387' | project name, type, resourceGroup"



param ($ResourceGroup, $AzureSQLinstance)

# This set of Azure PowerShell commands shows how to query limit and quotas for networking, SQL Database, storage, and virtual machine resources.

# Connect to Azure using your account
# Make sure that you have a subscription associated with your Azure Account
# Azure PowerShell is installed from https://learn.microsoft.com/powershell/azure/install-azure-powershell


Connect-AzAccount

# Set the subscription you are going to query

Set-AzContext -Subscription <subscription name or id>


# This command gets the limits for networking resources in the West US location

Get-AzNetworkUsage -Location westus | Format-Table ResourceType, CurrentValue, Limit

# Alternatively you can query for specific resources, this command gets the limits for all route table resources in the West US location

Get-AzNetworkUsage -Location westus | Where-Object {$_.ResourceType -eq 'Route Tables'} | Format-Table ResourceType, CurrentValue, Limit


# Use this command to Get all limits that apply to a specific Azure SQL Instance

Get-AzSqlInstancePoolUsage -ResourceGroupName $ResourceGroup -Name $AzureSQLinstance | Format-Table Name, Limit
 
# Use this command in case you need to query for a specific limit in you Azure Sql Instance

Get-AzSqlInstancePoolUsage -ResourceGroupName $ResourceGroup -Name $AzureSQLinstance | where Name -CContains "Storage utilization" | Format-Table Name, Limit


# Use this command to get the storage accounts limit in the West US location

Get-AzStorageUsage -Location 'West US'


# Use this command to get virtual machine related resource limits in the West US location

Get-AzVMUsage -Location 'West US'

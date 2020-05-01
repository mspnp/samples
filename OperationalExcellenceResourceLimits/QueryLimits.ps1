# This set of Powershell commands show how yo query limit and quotas for commonly used Networking resources, Virtual machines, SQL database and Storage Accounts

# Connect to Azure using your account
# Make sure that you have a subscription associated with your Azure Account


Connect-AzAccount

# This command gets the limits for networking resources in the West US location:

Get-AzNetworkUsage -Location westus | Where-Object {$_.CurrentValue -gt 0} | Format-Table ResourceType, Limit

# Alternatively you can query for specific resources, this command gets the limits for route tables

Get-AzNetworkUsage -Location westus | Where-Object {$_.ResourceType -eq 'Route Tables'}  | Format-Table ResourceType, Limit


# Use this command to Get all limits that apply to a spcefici Azure Sql Intance

Get-AzSqlInstancePoolUsage -ResourceGroupName <your resource group> -Name <you azure sql instance> | Format-Table Name, Limit
 

# Use this command in case you need to query for a specific limit in you Azure Sql Instance

Get-AzSqlInstancePoolUsage -ResourceGroupName <your resource group> -Name <you azure sql instance> | where Name -CContains "Storage utilization" | Format-Table Name, Limit


# Use this command to get the storage accounts limit

Get-AzStorageUsage -Location 'West US'


# Use this command to get the virtual machine limits

Get-AzVMUsage -Location "Central US" 
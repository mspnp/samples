# Manage your alerts programmatically

# This set of Azure CLI commands show how to query programmatically for alerts generated against your subscription.


# Prerequisites

# Add the Resource Graph extension to the Azure CLI environment
az extension add --name resource-graph

# Check the extension list (note that you may have other extensions installed)
az extension list

# Run help for graph query options
az graph query -h



### Sample Queries
### REPLACE the subscription Id placeholder by you current subscription Id


# This query searchs for alerts in a specific subscription

az graph query -q "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '<your subscription id>' "

# Same query but listing specific fields

az graph query -q  "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '<your subscription id>' | project name, type, resourceGroup"

# Query alerts in a subscription and list their common properties

az graph query -q  "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '<your subscription id>' | project properties"

# Query alerts in a subscription and list a specific common property

az graph query -q  "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '<your subscription id>' | project properties.essentials.severity"

# In case you want to build a JSON object that contains the common alert metadata

az graph query -q  "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '<your subscription id>' | project properties | summarize buildschema(properties)"


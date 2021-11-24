subcriptionId=$1
echo Manage your alerts programmatically

### Sample Queries

echo 'This query searches for alerts in a specific subscription'

az graph query -q "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '$subcriptionId' "

echo 'Same query but listing specific fields'

az graph query -q  "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '$subcriptionId' | project name, type, resourceGroup"

echo 'Query alerts in a subscription and list their common properties'

az graph query -q  "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '$subcriptionId' | project properties"

echo 'Query alerts in a subscription and list a specific common property'

az graph query -q  "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '$subcriptionId' | project properties.essentials.severity"

echo 'In case you want to build a JSON object that contains the common alert metadata'

az graph query -q  "AlertsManagementResources | where type =~ 'Microsoft.AlertsManagement/alerts' and subscriptionId =~ '$subcriptionId' | project properties | summarize buildschema(properties)"

